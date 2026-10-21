# Changelog — 2026-10-21

## Delegation brief checklist (`reference/brief.md`)

The router now loads `reference/brief.md` whenever the delegated task reads or changes
code, data, or infrastructure. The checklist comes from observed rework in delegated runs:

- **Verified facts from the delegate's own checkout.** A brief cited code that existed only
  on another branch; the delegate flagged it, the next brief repeated it, and the slice took
  three attempts. Facts are now quoted with `git -C <checkout> show HEAD:<path>` or a
  recorded command output, and facts that hold only on another ref carry that ref.
- **Measured data shape before a prescribed design.** A brief fixed the design and said
  "do not ask"; the duplicate-data measurement came after the change was merged and had to
  be rebuilt. When nobody has measured the data, measuring becomes the first step.
- **Consumers of every touched interface.** A producer added a field that a strict consumer
  rejected; reviews missed it and only end-to-end QA caught it. Briefs now list consumers,
  how they deserialize, and the deploy order.
- **Baseline, sandbox directories, and an autonomy line.** Delegates no longer chase
  pre-existing failures, get sandbox-denied on build caches, or pause to ask for approval
  the brief already granted.
- **Re-brief rule:** quote the delegate's objection verbatim in the next brief.

`SKILL.md` gains the reference-map row and a Done-criterion clause; both READMEs describe
the new step.
