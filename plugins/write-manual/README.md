# write-manual (plugin)

A multi-agent pipeline that produces comprehensive, accessible, WCAG 2.2 AA
user manuals for desktop applications.

## Pipeline

Haiku scouts extract facts from the codebase → Sonnet synthesizes research →
Opus writes the manual → Sonnet verifies accuracy and accessibility → Sonnet
translates to target languages.

## Contents

- `skills/write-manual/` — the `SKILL.md` plus its `references/` tree (scout and
  agent prompts, accessibility/encoding/tone rules, and glossaries).

## Install

```
/plugin marketplace add Oire/debussy
/plugin install write-manual@debussy
```
