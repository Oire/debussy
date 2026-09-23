# write-manual (plugin)

A multi-agent pipeline that produces comprehensive, accessible, WCAG 2.2 AA
user manuals for desktop applications.

## Pipeline

Haiku scouts extract facts from the codebase → Sonnet synthesizes research →
Opus writes the manual → Sonnet verifies accuracy and accessibility → Sonnet
translates to target languages.

If the app can be launched, the skill can also screenshot its main window and
dialogs first; the researcher and verifier then check layout, labels, and focus
order against the real app instead of inferring them from code.

Progress is recorded in `.claude/write-manual/progress.md`, so an interrupted
run can resume where it stopped.

## Git

The skill works on a branch (`manual-<date>` when started from the base branch),
commits the approved English manual and then the translations, then pushes and
opens a pull request. How far it goes, the base branch, and whether anything
may mention AI are set in `.claude/debussy.json`;
see `skills/write-manual/references/git.md`. Set `"git": "none"` to leave
everything uncommitted.

## Glossaries

Term rules live with the manuals, in `glossaries/` inside the project's help
directory: `base.json` for rules that hold in every language (names never
translated, words always capitalized) and one `<lang>.json` per language for
fixed translations and localized key names. The skill creates `base.json` on its
first run from what it learns about the product, adds terms the translators flag
when you agree, and commits the glossaries alongside the manuals. The schemas
and a format example ship in `skills/write-manual/references/glossaries/`. If
your build copies the help directory into the app, exclude `glossaries/`.

## Contents

- `skills/write-manual/` — the `SKILL.md` plus its `references/` tree (scout and
  agent prompts, accessibility/encoding/tone rules, glossary schemas and
  examples, and the shared git workflow).

## Install

```
/plugin marketplace add Oire/debussy
/plugin install write-manual@debussy
```
