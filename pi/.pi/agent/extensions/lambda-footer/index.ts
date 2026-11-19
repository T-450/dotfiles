// lambda-footer: Pi's footer as the shell prompt (zsh/.zshrc: oh-my-zsh's cdimascio-lambda theme),
// `λ dotfiles git:(main) ✗`, in the prompt's palette roles from ~/.config/theme/colors.sh (re-read
// when `theme set` rewrites it): λ bold success, or bold error after a failed tool as after a failed
// command; the directory's last component fg_bright; git:( ) fg_text, the branch link, and an error
// ✗ when `git status --porcelain` lists anything (oh-my-zsh's parse_git_dirty). Right: the model,
// thinking level, context and session cost, dim.
import { execFile } from "node:child_process";
import { readFileSync, statSync } from "node:fs";
import { basename, join } from "node:path";
import { homedir } from "node:os";
import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const sgr = (codes: string) => `\x1b[${codes}m`;
const RESET = sgr("0");
const GIT_REFRESH_MS = 10_000;
const COLORS = join(homedir(), ".config/theme/colors.sh");

// before the first `theme set` there is no colors.sh: the terminal's ANSI colors, as zsh's theme
const ANSI: Record<string, string> = { SUCCESS: "92", ERROR: "31", FG_BRIGHT: "95", FG_TEXT: "94", LINK: "33" };
let colors = { mtime: -1, sgr: ANSI };

// SGR foreground codes for the prompt's roles, keyed by colors.sh's THEME_<ROLE> names
function roles(): Record<string, string> {
	let mtime: number;
	try {
		mtime = statSync(COLORS).mtimeMs;
	} catch {
		return ANSI;
	}
	if (mtime === colors.mtime) return colors.sgr;
	const sgr = { ...ANSI };
	for (const [, role, hex] of readFileSync(COLORS, "utf8").matchAll(/^THEME_(\w+)="#([0-9a-f]{6})"/gim)) {
		if (role in ANSI) sgr[role] = `38;2;${[0, 2, 4].map((i) => parseInt(hex.slice(i, i + 2), 16)).join(";")}`;
	}
	colors = { mtime, sgr };
	return sgr;
}

export default function lambdaFooter(pi: ExtensionAPI) {
	let failed = false; // the last tool failed: λ turns red, as zsh's does after a failed command
	let dirty = false;
	let requestRender: (() => void) | undefined;
	let timer: ReturnType<typeof setInterval> | undefined;
	let cwd = process.cwd();

	const refreshGit = () => {
		execFile("git", ["status", "--porcelain"], { cwd, timeout: 5000 }, (err, out) => {
			const now = !err && out.trim().length > 0;
			if (now !== dirty) {
				dirty = now;
				requestRender?.();
			}
		});
	};

	const show = (ctx: ExtensionContext) => {
		cwd = ctx.cwd;
		ctx.ui.setFooter((tui, theme, footerData) => {
			requestRender = () => tui.requestRender();
			const unsub = footerData.onBranchChange(() => {
				refreshGit();
				tui.requestRender();
			});
			return {
				dispose() {
					unsub();
					requestRender = undefined;
				},
				invalidate() {},
				render(width: number): string[] {
					const dir = cwd === homedir() ? "~" : basename(cwd);
					const branch = footerData.getGitBranch();
					const c = roles();
					let left = `${sgr(`1;${failed ? c.ERROR : c.SUCCESS}`)}λ ${RESET}${sgr(c.FG_BRIGHT)}${dir}${RESET} `;
					if (branch) {
						left += `${sgr(c.FG_TEXT)}git:(${sgr(c.LINK)}${branch}`;
						left += dirty ? `${sgr(c.FG_TEXT)}) ${sgr(c.ERROR)}✗` : `${sgr(c.FG_TEXT)})`;
						left += RESET;
					}

					let cost = 0;
					for (const e of ctx.sessionManager.getBranch()) {
						if (e.type === "message" && e.message.role === "assistant") {
							cost += (e.message as AssistantMessage).usage?.cost?.total ?? 0;
						}
					}
					const k = (n: number) => (n < 1000 ? `${n}` : `${Math.round(n / 1000)}k`);
					const usage = ctx.getContextUsage();
					const parts = [ctx.model?.id ?? "no model", pi.getThinkingLevel()];
					if (usage) parts.push(`${usage.tokens == null ? "?" : k(usage.tokens)}/${k(usage.contextWindow)}`);
					if (cost > 0) parts.push(`$${cost.toFixed(2)}`);
					const right = theme.fg("dim", parts.join(" · "));

					const gap = width - visibleWidth(left) - visibleWidth(right);
					if (gap < 2) return [truncateToWidth(left, width)];
					return [left + " ".repeat(gap) + right];
				},
			};
		});
		refreshGit();
		clearInterval(timer);
		timer = setInterval(refreshGit, GIT_REFRESH_MS);
	};

	pi.on("session_start", async (_event, ctx) => {
		failed = false;
		if (ctx.hasUI && ctx.mode === "tui") show(ctx);
	});
	pi.on("session_shutdown", async () => clearInterval(timer));
	pi.on("tool_execution_end", async (event) => {
		failed = event.isError;
		refreshGit();
		requestRender?.();
	});
	for (const e of ["message_end", "model_select", "thinking_level_select", "agent_settled"] as const) {
		pi.on(e, async () => requestRender?.());
	}
}
