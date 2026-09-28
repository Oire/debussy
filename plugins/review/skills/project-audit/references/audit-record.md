# Audit record

The audit's memory on disk: `.claude/project-audit/<branch>.md`, with `/` in
the branch name replaced by `-`. It holds every finding and what the user
decided about it, so an audit can be picked up after the context has been
compacted or the session has ended, and skipped findings are still there to
revisit once the audit is over. It lives under `.claude/`, so it is never
committed.

You keep it with the Write and Edit tools: create it when the audit starts, add
a section when a reviewer reports, and update a finding's decision as soon as
the user makes it or the fixer reports back.

```
# Audit record
Branch: audit-2026-09-28
Base: master
Mode: nigel-first
Started: 2026-09-28
Windows: headless only
User's uncommitted files (never committed): src/Settings.cs

## Nigel, round 1
Not covered: failed group safety; not tested: 1.4.10 Reflow (app would not start)

- N1 serious, confirmed. README example calls Connect(host), which now takes options. README.md:42. Fix: update the example. Decision: implemented in 3f2a91c
- N2 moderate, suspected. Settings dialog may clip at 150% DPI. SettingsForm.Designer.cs. Would confirm: a screenshot at 150%. Decision: declined
- N3 nitpick, confirmed. Mixed casing in enum members. Status.cs:8. Decision: not fixed: the fixer found it already consistent
- N4 serious, refuted. "No LICENSE file." LICENSE exists at the root. Skeptic: LICENSE present, Apache-2.0.

## Codex, round 1
- C1 major, confirmed. ...
```

- Ids are stable for the whole audit: `N` for Nigel and `C` for Codex, with
  numbering that continues across rounds (a second Codex round starts after
  the last `C` id). Use the same numbers in triage, so the user can refer to
  them.
- Decisions: `pending` until the user triages, then `implemented in <commit>`
  (or `implemented, uncommitted` with git mode `none`), `declined`, or
  `not fixed: <why>` from the fixer's report. A refuted finding keeps the
  skeptic's reason instead of a decision.
- When a later reviewer runs, the declined and refuted entries are what it is
  told not to report again.
