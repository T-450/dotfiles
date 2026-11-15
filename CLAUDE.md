# CLAUDE.md

@AGENTS.md

## Free resources

Always kill hanging, stale, unused or temporary runners to free their resources and memory: an
orphaned nested or headless `mango` (parent PID 1; SIGKILL it, since a clean exit stops
`graphical-session.target`, then remove its `wayland-N` and `mango-PID.sock`), a leftover qemu or
`desktop-vm` guest (`desktop-vm down`), an fzf/test process you started, a background job that has
done its work. Check `ps` and `free -h` before starting a VM: desktop-vm and CI guests need 6 GB.
Never kill the user's apps, the live `mango`, `runner-up.service`, or another live Claude session's
processes (its MCP servers have a running `claude` parent).
