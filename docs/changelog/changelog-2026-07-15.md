# Changelog — 2026-07-15

## Claude wrappers allow configured MCP servers

The planning, review, and implementation wrappers now run `claude mcp list` and add one
server-level permission rule for every configured MCP server. Names are normalized to
Claude's ASCII tool-name format, so connector and plugin names containing spaces, colons,
dots, or non-ASCII characters are handled alongside ordinary server names.
The normalizer decodes `claude mcp list` names as UTF-8 before replacing code points, so
macOS Bash 3.2 produces the same namespace even when its caller sets `LC_ALL=C`.

The shared calculation keeps the three roles consistent and preserves each wrapper's
existing non-MCP permissions. A list failure yields no MCP rules and does not block the
delegated Claude call.

Rejected alternatives:

- One MCP wildcard: unsupported by the approved legacy compatibility target.
- `bypassPermissions`: also disables unrelated permission checks.
- A hardcoded server list: becomes stale as users add or remove servers.
