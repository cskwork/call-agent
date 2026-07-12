# Changelog — 2026-07-12

## Make Claude implementation fail early when the host blocks Bash

### Decision

Add an explicit Claude implementation route and probe Claude's Bash capability before
sending the real task. Authentication alone was insufficient: Claude could start and
consume credits while its internal shell failed before any workspace edit.

### Alternatives rejected

- Automatic sandbox bypass: host policy is authoritative, and weakening Claude's own
  permission mode would not override it safely.
- Authentication-only preflight: it proves account access, not workspace execution.
- Silent fallback to the host agent: the user explicitly named Claude.

### Verification

- Shell syntax for every Claude wrapper.
- Static guard against permission-bypass flags.
- Claude smoke test at L0/L1; live shell probe remains opt-in because it uses credits.

### Follow-up: remove the preflight false negative

The first probe inherited Claude's full user configuration and exhausted its `$0.05`
budget after loading roughly 150k cached/context tokens. Run the probe in `safe-mode`
with only Bash, a minimal system prompt, and four turns. Failed semantic checks now print
Claude's result or terminal error instead of hiding the cause.
