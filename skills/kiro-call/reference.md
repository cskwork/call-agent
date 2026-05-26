# kiro-call — Reference

Verified against `kiro --help` v0.12.224.

## Top-level options used by this skill

| Flag | Purpose |
|---|---|
| `-d, --diff <a> <b>` | Open side-by-side diff |
| `-m, --merge <p1> <p2> <base> <out>` | Open 3-way merge editor |
| `-a, --add <folder>` | Add folder to last active window |
| `-g, --goto <file:line[:col]>` | Open at a specific position |
| `-n, --new-window` / `-r, --reuse-window` | Window targeting |
| `-w, --wait` | Block until window closes |
| `--add-mcp <json>` | Register an MCP server in the user profile |
| `--profile <name>` | Use a named profile |
| `-v, --version` | Print version |
| `--locate-shell-integration-path <shell>` | Print Kiro's shell-integration script path |

## Subcommands

| Subcommand | Purpose |
|---|---|
| `chat [prompt]` | Open chat session in CWD |
| `serve-web` | Run editor UI in browsers (requires `kiro-tunnel`) |
| `tunnel` | Expose this machine via secure tunnel |

## `kiro chat` flags

| Flag | Purpose |
|---|---|
| `-m, --mode <ask\|edit\|agent\|custom>` | Default: `agent` |
| `-a, --add-file <path>` | Add file as context (repeatable) |
| `--maximize` | Maximize chat view |
| `-r, --reuse-window` / `-n, --new-window` | Window targeting |
| `--profile <name>` | Use named profile |

stdin: append `-` after the prompt to pipe stdin (`echo X | kiro chat "Summarize" -`).

**Critical:** there is no `--print` / `-p` / `--json` flag — Kiro chat
opens a GUI window and prints results IN the IDE, not on stdout.

## Data paths

- Binary: `/usr/local/bin/kiro` → `/Applications/Kiro.app/Contents/Resources/app/bin/code`
- User config / MCP registry: `~/.kiro/` (created by Kiro on first run)
- Extensions: `~/.kiro/extensions/`
- Profiles: managed by Kiro internally; named via `--profile`

## MCP JSON shape for `--add-mcp`

```json
{
  "name": "server-name",
  "command": "npx",
  "args": ["-y", "@org/mcp-server"],
  "env": { "KEY": "VALUE" }
}
```

`name` and `command` required; `args` and `env` optional. Kiro merges
into its user-level MCP registry.

## What this skill does NOT use

- `kiro chat` as a result-fetcher (no headless output)
- `serve-web` / `tunnel` (infrastructure ops, not delegation)
- Extension install/uninstall (user-managed)
- `--sync` / telemetry / proposed-API flags

## Why no L2 round-trip test

`kiro chat` returns no stdout — it just opens the IDE chat panel. Any
"did the prompt work?" check would require GUI inspection. The skill's
automated tests therefore stop at L1 (syntax + help).
