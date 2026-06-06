---
name: write-manual
description: "Write comprehensive, accessible user manuals for desktop applications. Multi-agent pipeline: Haiku scouts extract facts from code, Sonnet synthesizes research, Opus writes the manual, Sonnet verifies accuracy and WCAG compliance, Sonnet translates to target languages. Use when user says 'write-manual', 'write manual', 'write a manual', 'write help file', 'write user manual', 'update manual', 'update help file', 'generate manual', or wants to create/update product documentation."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, AskUserQuestion
---

# write-manual

Write comprehensive, accessible, WCAG 2.2 AA compliant user manuals for desktop applications using a multi-agent pipeline.

## Arguments

- `$ARGUMENTS` — path to the project root (optional; uses current working directory if omitted)

## Accessibility-friendly output

Do NOT use ASCII diagrams, tables, box-drawing characters, or pseudographics in user-visible output. Prefer plain prose and simple bullet lists.

## Key constraint — output format

All manuals are produced as single HTML files, one per language. UTF-8 encoding, raw Unicode characters only (never HTML entities except `&lt;`, `&gt;`, `&amp;`, `&nbsp;`). See rules files for full requirements.

## Skill directory

All referenced files live under the skill directory. Resolve the absolute path once at startup:

```
SKILL_DIR = ${CLAUDE_PLUGIN_ROOT}/skills/write-manual
```

Reference files:
- `$SKILL_DIR/references/rules/*.md` — non-negotiable output rules
- `$SKILL_DIR/references/scouts/*.md` — Haiku scout prompt templates
- `$SKILL_DIR/references/prompts/*.md` — agent prompts (researcher, writer, verifier, translator)
- `$SKILL_DIR/references/glossaries/*.schema.json` — glossary JSON schemas

## Process

### Step 1. Orient

No agents needed — the orchestrator does this directly.

1. **Resolve project path** from `$ARGUMENTS` or use the current working directory.
2. **Read `CLAUDE.md`** at the project root. This gives you the product's tech stack, conventions, and architecture.
3. **Read `README.md`** if it exists. This gives you the product description and setup instructions.
4. **Find the help directory**: glob for `**/help/**/*.html` or `**/manual.html` or `**/docs/**/*.html`. Note:
   - Where existing manual files live (the output target)
   - Which languages already exist (subdirectories like `en/`, `fr/`, `de/`)
   - Whether a shared CSS file exists
   - Where the logo file is
5. **Find plan files**: glob for `docs/plans/**/*.md`. Read completed plans (in `completed/` subdirectory) and any active plans with all checkboxes ticked. These describe implemented features.
6. **Find source directories**: identify where UI code, config, services, and localization files live from the project structure in CLAUDE.md.
7. **Find glossary files**: check `$SKILL_DIR/references/glossaries/` for `base.json` and any `LANG.json` files. If none exist yet, note that glossaries will need to be created.

Report to the user:
- Product name and description (from CLAUDE.md/README)
- Existing help file location and languages found
- Number of completed plans found
- Source directories identified
- Glossary status (which languages have glossaries, which don't)

### Step 2. Scout (Haiku agents, parallel)

Read all six scout prompt templates from `$SKILL_DIR/references/scouts/`. For each, substitute project-specific file paths discovered in Step 1.

Spawn **all scouts in parallel** using the Agent tool with `model: "haiku"`. Each scout gets:
- Its prompt template with file paths filled in
- The specific source files to read (provide exact paths, not globs)
- Instructions to return structured JSON

The six scouts:
1. **shortcuts** — extract keyboard shortcuts from UI code (ProcessCmdKey, ShortcutKeys, hotkey registrations)
2. **settings** — extract config settings with defaults, types, valid values
3. **menus** — extract menu structure with mnemonics, shortcuts, context menus, tray menu
4. **ui-layout** — extract window/dialog layouts, control order, focus behavior
5. **features** — extract implemented features from completed plan files
6. **strings** — extract user-facing strings from localization files and hardcoded UI text

After all scouts return, collect their JSON outputs. If any scout reported errors or could not complete, note the gaps.

Report to the user: "Scouting complete. X scouts succeeded, Y had gaps." List any gaps briefly.

### Step 3. Synthesize and question (Sonnet agent)

Read the researcher prompt from `$SKILL_DIR/references/prompts/researcher.md`.

Spawn **one Sonnet agent** with `model: "sonnet"`:
- The researcher prompt
- All six scout outputs (full JSON, not summarized)
- CLAUDE.md content
- README.md content
- Completed plan file summaries

The researcher produces:
- A **product brief** (structured research document)
- A **question list** (uncertainties, ranked by importance)

After the agent returns, save the product brief to a temporary location (the project's help directory, e.g. `help/.product-brief.md` — prefixed with dot so it's clearly temporary).

### Step 4. Clarification (interactive)

Present the researcher's questions to the user using **AskUserQuestion**. Group questions by importance:
- Must answer (manual accuracy depends on these)
- Should answer (would improve quality)
- Nice to know (adds depth)

For multiple-choice questions, use the `options` format. For open-ended questions, use free-text.

Collect all answers. Append them to the product brief.

### Step 5. Write (Opus agent)

Read the writer prompt from `$SKILL_DIR/references/prompts/writer.md`.
Read all rules files from `$SKILL_DIR/references/rules/`.
Read the base glossary from `$SKILL_DIR/references/glossaries/base.json` (if it exists).

Spawn **one Opus agent** with `model: "opus"`:
- The writer prompt
- The complete product brief (with user's answers appended)
- All four rules files (html.md, encoding.md, tone.md, keyboard.md) — injected in full, not referenced
- The base glossary
- The existing manual (if any) — clearly marked as "reference only, do not copy"
- The target file path (e.g. `src/ExampleApp/help/en/manual.html`)

**Critical framing instruction to include in the agent prompt:**

> You are writing for a real person who just installed an app and wants to get things done. You are NOT writing a feature spec or an API reference. Every paragraph must pass this test: "Would a reader who just wants to use the app find this useful right now?"
>
> Start with a short welcome that tells the reader what the app is and what to expect. Then give them a Quick Start (4–5 steps to their first success). Only after that, explore features in depth — and always from the perspective of what the user wants to accomplish, not what the software contains.
>
> Do not name internal systems, do not use "the X feature" framing, do not list capabilities without motivation.

The writer outputs a single complete HTML file. The orchestrator writes it to the target path using the Write tool.

Report to the user: "English manual draft written to PATH."

### Step 6. Verify (Sonnet agent + Haiku spot-checkers)

Read the verifier prompt from `$SKILL_DIR/references/prompts/verifier.md`.

Spawn **one Sonnet agent** with `model: "sonnet"`:
- The verifier prompt
- The generated HTML manual (full content)
- The product brief
- All four rules files
- The base glossary
- Source file paths for spot-checking

The verifier returns a structured report with critical, important, and minor issues, plus spot-check requests.

**If the verifier has spot-check requests**: spawn Haiku agents (parallel, `model: "haiku"`) to verify specific facts against source code. Feed their results back to the verifier.

Report the verification results to the user:
- Number of critical / important / minor issues
- Brief list of each issue (one line per issue)

### Step 7. Fix and present (loop)

**If the verifier found critical or important issues**:

1. Spawn the Opus writer again (`model: "opus"`) with:
   - The current manual HTML
   - The full verification report
   - Instructions to fix all critical and important issues, and as many minor issues as practical
2. Write the fixed HTML to the target path
3. Re-run verification (Step 6) on the fixed version
4. Repeat up to 3 times. If issues persist after 3 iterations, present the manual to the user with remaining issues listed.

**When verification passes or max iterations reached**:

Present the manual to the user. Use AskUserQuestion:

```json
{
  "questions": [{
    "question": "The English manual is ready for your review. It's at TARGET_PATH. What would you like to do?",
    "header": "Manual review",
    "options": [
      {"label": "Looks good — proceed to translation", "description": "Approve the English manual and start translating"},
      {"label": "I have feedback", "description": "I'll describe what needs changing"},
      {"label": "Stop here", "description": "Keep the English manual as-is, skip translation for now"}
    ],
    "multiSelect": false
  }]
}
```

**If the user has feedback**: collect it, send it to the Opus writer for revision, re-verify, and present again. Repeat until the user approves or stops.

### Step 8. Translate (Sonnet agents, parallel)

Only proceed here if the user approved the English manual for translation.

1. **Determine target languages**: check which language directories exist in the help folder (e.g. `fr/`, `de/`, `ru/`, `uk/`). Also ask the user if they want to add new languages.

2. **Check glossaries**: for each target language, check if `$SKILL_DIR/references/glossaries/LANG.json` exists.
   - If a glossary is missing, inform the user: "No glossary found for LANGUAGE. The translator will use its best judgment and flag terms for glossary creation."

3. **Read the translator prompt** from `$SKILL_DIR/references/prompts/translator.md`.

4. **Spawn one Sonnet agent per language** in parallel, each with `model: "sonnet"`:
   - The translator prompt
   - The approved English HTML manual
   - The language glossary (if it exists)
   - The base glossary
   - encoding.md and keyboard.md rules
   - The target file path (e.g. `src/ExampleApp/help/fr/manual.html`)
   - The path to the relevant `.po` localization file for that language (so the translator can read exact UI string translations from it)
   - Explicit instruction: "Write the output file directly. Do NOT include HTML comments anywhere in the output."

5. **Collect outputs**: each translator produces either:
   - A plain HTML file (no flagged terms), OR
   - A preamble with flagged terms, a blank line, then the HTML file

   The orchestrator MUST parse the output: if it starts with `FLAGGED TERMS:`, extract the flagged-terms block and write only the HTML portion (starting from `<!DOCTYPE html>`) to the target file. Collect flagged terms separately for reporting.

6. **Write translated files** to their target paths. Verify each file starts with `<!DOCTYPE html>` — if any extraneous content (comments, notes) was included, strip it before writing.

Report to the user: "Translations complete for X languages. Y terms flagged for glossary additions." List any flagged terms.

### Step 9. Verify translations (Sonnet, per language)

For each translated manual, run a lighter verification pass. Spawn Sonnet agents in parallel (`model: "sonnet"`), each checking:
- Glossary compliance — every glossary term uses the specified translation
- No HTML entities crept in (except the four allowed)
- `<kbd>` key names properly localized per the glossary's `keys` mapping
- RTL attributes correct (for Hebrew and future RTL languages)
- Proper diacritics, no ASCII approximations
- No untranslated strings left behind
- HTML structure matches the English original (same IDs, same sections, same number of articles)

If issues found, send back to the translator agent for fixes (up to 2 iterations per language).

Report to the user: translation verification results per language.

### Step 10. Final review

Present the complete set of manuals to the user using AskUserQuestion:

```json
{
  "questions": [{
    "question": "All manuals are ready. English plus LANGUAGE_COUNT translations. What would you like to do?",
    "header": "Final review",
    "options": [
      {"label": "All done", "description": "Accept all manuals as-is"},
      {"label": "Revise English", "description": "I want changes to the English manual (translations will need updating)"},
      {"label": "Revise a translation", "description": "A specific translation needs work"}
    ],
    "multiSelect": false
  }]
}
```

**If revising English**: go back to Step 7 with user feedback. After English is re-approved, re-run Step 8-9 for all languages.

**If revising a translation**: ask which language, collect feedback, re-run that specific translator.

### Step 11. Cleanup

After the user accepts all manuals:
- Delete the temporary product brief (`help/.product-brief.md`) if it was created
- If any terms were flagged during translation, offer to create or update glossary files:
  "X terms were flagged during translation. Would you like me to add them to the glossaries?"
- Report completion: "Manual complete. English + X translations written to HELP_DIR."

## Model assignment

| Agent | Model | Rationale |
|---|---|---|
| Scouts (6) | Haiku | Narrow extraction tasks, one file per scout, structured JSON output |
| Researcher (1) | Sonnet | Synthesis across scout outputs, structured brief, question generation |
| Writer (1) | Opus | Creative writing, tone calibration, accessibility awareness |
| Verifier (1) | Sonnet | Systematic checklist verification, cross-referencing |
| Spot-checkers | Haiku | Single-fact verification against one source file |
| Translators | Sonnet | Professional translation with glossary adherence |
| Translation verifiers | Sonnet | Checklist verification of translated output |

## Key rules

- All agents are spawned via the Agent tool with explicit `model` parameter
- Scout agents run in parallel (single message, multiple Agent tool calls)
- Translator agents run in parallel (single message, multiple Agent tool calls)
- The orchestrator never writes manual content itself — only agents write content
- The orchestrator never summarizes or filters agent output when passing between agents — pass full output
- All rules files are injected into agent prompts in full, not by reference
- Glossary terms are non-negotiable — no synonyms, no variation
- UTF-8, raw Unicode, no HTML entities (except `&lt;`, `&gt;`, `&amp;`, `&nbsp;`)
- American English spelling for the English manual
- WCAG 2.2 AA compliance is a hard requirement, not a nice-to-have
- The user reviews and approves the English manual before any translation begins
- Never commit, push, or modify git state
- Translator output must NEVER contain HTML comments — the orchestrator must strip any that appear

## Quality guidance — what "good" looks like

The difference between a mediocre manual and a good one is perspective. A mediocre manual describes what the software contains. A good manual helps a person accomplish something.

### Common failure modes to watch for in writer output

1. **Feature-catalog syndrome.** Every section reads as "Feature X does Y. Feature Z does W." No sense of when or why you'd use any of them. Fix: the writer prompt explicitly demands task-first framing and motivating context.

2. **Leading with the uncommon case.** A section on notes that starts with "You can configure Enter key behavior in three ways" before explaining how to create a note. Fix: common path first, variations after.

3. **Internal naming leaking through.** "The Title Derivation system," "the ConfirmOnExit setting," "the Single Instance mechanism." Users don't know or care about internal names. Fix: describe behavior, not systems.

4. **Unmotivated settings descriptions.** Listing every setting with a one-line echo of its label. Fix: explain *why* someone would change each setting.

5. **Opening with a tip.** Starting the manual with a `role="note"` tip before the reader has any context. Fix: welcome first, then quick start, then depth.

6. **Dry, even tone throughout.** No change in energy between a welcome paragraph and a settings reference table. The welcome should feel inviting. The quick start should feel fast. The settings reference can be more clinical. Match tone to purpose.

7. **Missing the "what happens" half of instructions.** "Press Ctrl+N" without saying what appears on screen. Users need confirmation they did the right thing.

### What the orchestrator should check before presenting to the user

After the writer produces output, before running full verification, the orchestrator should quickly scan for:
- Does it start with a welcome or overview, not a tip?
- Is there a quick-start section in the first few screens of content?
- Does the Enter/shortcut table (if applicable) clearly show both directions (what to press for action A, what to press for action B)?
- Are settings explained with motivation, not just restated?
- Count the instances of "the X feature" — if more than 2, it's feature-catalog writing

If the output fails these checks, send it back to the writer with specific revision instructions rather than running the full verify cycle (which won't catch tone/framing issues).
