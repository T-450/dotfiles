// mascot: a sprite above Pi's editor that acts out what the model is doing. The frames come from
// `pi-mascot-import SHEET` (~/.local/share/pi-mascot/zero: frames/*.png and poses.json); they stay
// on this machine. Drawn with the Kitty graphics protocol (Ghostty): one image id, each frame
// replaces the last in place. Terminals without image support get no widget.
//
// Activity poses loop while the model does something: idle (waiting for you), think (thinking),
// talk (writing a reply), and one per tool (read/search run, bash dashes, edit slashes, write
// combos, web jumps, subagents crescent-slash). Moments play once and then hold their last
// frame: ready (a run starts), hurt (a tool failed, a run was aborted), win (a run finished).
// `/mascot` toggles it; `/mascot POSE` previews one (`/mascot win`).
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { allocateImageId, deleteKittyImage, getCapabilities, renderImage } from "@earendil-works/pi-tui";

const DIR = process.env.PI_MASCOT_DIR ??
	join(process.env.XDG_DATA_HOME ?? join(homedir(), ".local/share"), "pi-mascot", "zero");
const ROWS = Number(process.env.PI_MASCOT_ROWS) || 5; // terminal rows the sprite stands in
const RIGHT_MARGIN = 2; // columns between the sprite and the right edge

type Pose = { frames: string[]; fps: number; loop: boolean; width: number; height: number };
type Frame = { data: string; widthPx: number; heightPx: number };

const TOOL_POSE: Record<string, string> = {
	read: "run", grep: "run", find: "run", ls: "run",
	bash: "dash",
	edit: "slash", write: "combo", apply_patch: "combo",
	web_search: "jump", webfetch: "jump", web_fetch: "jump", fetch: "jump",
	Agent: "crescent", agent: "crescent", subagent: "crescent", task: "crescent",
};
// how long a one-shot pose holds its last frame before the activity pose comes back
const HOLD_MS: Record<string, number> = { ready: 0, hurt: 1200, win: 2500 };

function load(): Map<string, { pose: Pose; frames: Frame[] }> | null {
	try {
		const manifest = JSON.parse(readFileSync(join(DIR, "poses.json"), "utf8")) as { poses: Record<string, Pose> };
		const poses = new Map<string, { pose: Pose; frames: Frame[] }>();
		for (const [name, pose] of Object.entries(manifest.poses)) {
			const frames = pose.frames.map((f) => ({
				data: readFileSync(join(DIR, "frames", f)).toString("base64"),
				widthPx: pose.width * 3,
				heightPx: pose.height * 3,
			}));
			poses.set(name, { pose, frames });
		}
		return poses.has("idle") ? poses : null;
	} catch {
		return null; // no frames imported yet: no mascot
	}
}

export default function mascot(pi: ExtensionAPI) {
	const poses = load();
	if (!poses) return;

	let enabled = true;
	let activity = "idle"; // looping pose for what the model is doing now
	let moment: string | null = null; // one-shot pose playing over it
	let frame = 0;
	let timer: ReturnType<typeof setTimeout> | undefined;
	let requestRender: (() => void) | undefined;
	let running = 0; // tools executing now
	const imageId = allocateImageId();

	const current = () => {
		const name = moment ?? activity;
		return poses.get(name) ?? poses.get("idle")!;
	};

	const schedule = () => {
		clearTimeout(timer);
		if (!enabled) return;
		const { pose, frames } = current();
		const last = frame >= frames.length - 1;
		let delay = 1000 / Math.max(1, pose.fps);
		if (moment && last && !pose.loop) delay = HOLD_MS[moment] ?? 800;
		timer = setTimeout(() => {
			if (moment && last && !current().pose.loop) {
				moment = null; // the moment is over: back to the activity
				frame = 0;
			} else {
				frame = last ? (current().pose.loop ? 0 : frame) : frame + 1;
			}
			requestRender?.();
			schedule();
		}, delay);
	};

	const setActivity = (name: string) => {
		if (!poses.has(name) || name === activity) return;
		activity = name;
		if (!moment) frame = 0;
		schedule();
		requestRender?.();
	};
	const play = (name: string) => {
		if (!poses.has(name)) return;
		moment = name;
		frame = 0;
		schedule();
		requestRender?.();
	};

	const show = (ctx: ExtensionContext) => {
		if (!ctx.hasUI || ctx.mode !== "tui" || !getCapabilities().images) return;
		ctx.ui.setWidget("mascot", (tui) => {
			requestRender = () => tui.requestRender();
			return {
				render(width: number): string[] {
					const { frames } = current();
					const f = frames[Math.min(frame, frames.length - 1)];
					const img = renderImage(f.data, { widthPx: f.widthPx, heightPx: f.heightPx }, {
						maxHeightCells: ROWS, maxWidthCells: Math.max(1, width - RIGHT_MARGIN), imageId, moveCursor: false,
					});
					if (!img) return [];
					const pad = " ".repeat(Math.max(0, width - img.columns - RIGHT_MARGIN));
					return [pad + img.sequence, ...Array.from({ length: img.rows - 1 }, () => "")];
				},
				invalidate() {},
			};
		});
		schedule();
	};
	const hide = (ctx: ExtensionContext) => {
		clearTimeout(timer);
		ctx.ui.setWidget("mascot", undefined);
		if (getCapabilities().images === "kitty") process.stdout.write(deleteKittyImage(imageId));
		requestRender = undefined;
	};

	pi.on("session_start", async (_event, ctx) => {
		activity = "idle"; moment = null; frame = 0; running = 0;
		if (enabled) show(ctx);
	});
	pi.on("session_shutdown", async (_event, ctx) => hide(ctx));

	pi.on("agent_start", async () => {
		running = 0;
		setActivity("think");
		play("ready");
	});
	pi.on("message_update", async (event) => {
		if (running > 0) return; // a tool's pose wins while it runs
		const type = (event as { assistantMessageEvent?: { type?: string } }).assistantMessageEvent?.type ?? "";
		if (type.startsWith("thinking")) setActivity("think");
		else if (type.startsWith("text")) setActivity("talk");
	});
	pi.on("tool_execution_start", async (event) => {
		running++;
		setActivity(TOOL_POSE[event.toolName] ?? "dive");
	});
	pi.on("tool_execution_end", async (event) => {
		running = Math.max(0, running - 1);
		if (event.isError) play("hurt");
		if (running === 0) setActivity("think");
	});
	pi.on("ui_prompt_start", async () => setActivity("alert"));
	pi.on("ui_prompt_end", async () => setActivity("think"));
	pi.on("agent_settled", async (event) => {
		running = 0;
		setActivity("idle");
		play(event.aborted ? "hurt" : "win");
	});

	pi.registerCommand("mascot", {
		description: `Show or hide the mascot, or preview a pose: ${[...poses.keys()].join(", ")}`,
		handler: async (args, ctx) => {
			const pose = String(args ?? "").trim();
			if (pose) {
				if (!poses.has(pose)) return ctx.ui.notify(`mascot: no pose ${pose}`, "warning");
				if (!enabled) { enabled = true; show(ctx); }
				if (poses.get(pose)!.pose.loop) setActivity(pose);
				else play(pose);
				return;
			}
			enabled = !enabled;
			if (enabled) show(ctx);
			else hide(ctx);
		},
	});
}
