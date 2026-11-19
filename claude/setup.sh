#!/usr/bin/env bash
# claude/setup.sh: register mise's MCP server for every Claude Code session (user scope, kept in
# ~/.claude.json, which Claude Code owns, so it can't be a linked file). No --cd: Claude Code starts
# the server in the session's directory, so it describes whichever project the session is in.
. "$(dirname -- "${BASH_SOURCE[0]}")/../tools/setup-lib.sh"
if ! claude mcp get mise >/dev/null 2>&1; then
	claude mcp add --scope user mise -- /usr/bin/mise mcp >/dev/null
	echo "mcp     claude: mise"
fi
