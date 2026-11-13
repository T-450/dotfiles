// lambda-footer: Pi's footer as the shell prompt (zsh/.zshrc: oh-my-zsh's cdimascio-lambda theme),
// `λ dotfiles git:(main) ✗`, in the theme's own terminal colors (SGR codes, so the terminal's palette
// draws it exactly as it draws the prompt): λ bold green, or bold red after a failed tool as after a
// failed command; the directory's last component cyan; git:( bold blue, the branch red, ) blue, and
// a yellow ✗ when `git status --porcelain` lists anything (oh-my-zsh's parse_git_dirty). Right: the
// model, thinking level, context and session cost, dim.
import { execFile } from "node:child_process";
import { basename } from "node:path";
import { homedir } from "node:os";
import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const sgr = (codes: string) => `\x1b[${codes}m`;
const RESET = sgr("0");
const GIT_REFRESH_MS = 10_000;

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
					let left = `${sgr(failed ? "1;31" : "1;32")}λ ${RESET}${sgr("36")}${dir}${RESET} `;
					if (branch) {
						left += `${sgr("1;34")}git:(${sgr("31")}${branch}`;
						left += dirty ? `${sgr("34")}) ${sgr("33")}✗` : `${sgr("34")})`;
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
