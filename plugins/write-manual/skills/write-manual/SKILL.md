---
name: write-manual
description: "Write comprehensive, accessible user manuals for desktop applications. Multi-agent pipeline: Haiku scouts extract facts from code, Sonnet synthesizes research, Opus writes the manual, Sonnet verifies accuracy and WCAG compliance, Sonnet translates to target languages. Use when user says 'write-manual', 'write manual', 'write a manual', 'write help file', 'write user manual', 'update manual', 'update help file', 'generate manual', or wants to create/update product documentation. Also use to pick up a started run: 'continue the manual', 'resume the manual', 'where did we get to on the manual'."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, AskUserQuestion
---

# write-manual

Write comprehensive, accessible, WCAG 2.2 AA compliant user manuals for desktop applications using a multi-agent pipeline. The run is done when the English manual and every requested translation are approved by the user, written to the help directory, and committed as far as the git setting allows.

## Arguments

- `$ARGUMENTS` — path to the project root (optional; uses current working directory if omitted)

## Accessibility-friendly output

Use plain prose and simple bullet lists in user-visible output, with no ASCII diagrams, tables, box-drawing characters, or pseudographics. Give counts in a sentence ("three critical, five minor"), not as a column of numbers.

## Output format

Manuals are single HTML files, one per language: UTF-8, raw Unicode characters, and no HTML entities except `&lt;`, `&gt;`, `&amp;`, `&nbsp;`. The rules files hold the full requirements.

## Skill directory

All referenced files live under the skill directory:

```
SKILL_DIR = ${CLAUDE_PLUGIN_ROOT}/skills/write-manual
```

- `$SKILL_DIR/references/rules/*.md` — output rules every writer and translator follows
- `$SKILL_DIR/references/scouts/*.md` — Haiku scout prompt templates
- `$SKILL_DIR/references/prompts/*.md` — agent prompts (researcher, writer, verifier, translator)
- `$SKILL_DIR/references/glossaries/*.schema.json` — glossary JSON schemas
- `$SKILL_DIR/references/glossaries/examples/` — example glossaries for a made-up app, showing the format only
- `$SKILL_DIR/references/settings.md` — the user's settings (`.claude/debussy.json`)
- `$SKILL_DIR/references/git.md` — branching, committing, pushing, and the pull request
- `$SKILL_DIR/references/manual-review.md` — acting on the notes the user leaves when reviewing a manual by hand

## Glossaries

Glossaries belong to the project, not the plugin: they live in `HELP_DIR/glossaries/` next to the manuals they govern, and they are committed with them.
- `base.json` holds rules for every language: names never translated, terms always capitalized. It follows `base-glossary.schema.json`.
- `<lang>.json` (`en.json`, `fr.json`) holds one language's fixed term translations and localized key names. It follows `language-glossary.schema.json`.

The files in `examples/` illustrate the format; their ExampleApp entries are not content to copy. If the app's build copies the help directory into the product, `glossaries/` should be excluded from that copy; mention it once if you see the help directory in a build or packaging file.

## Git

Resolve the settings in `$SKILL_DIR/references/settings.md`, then follow `$SKILL_DIR/references/git.md`. What is specific to this skill:

- **Branch.** If you are on the base branch, cut `manual-<YYYY-MM-DD>` before writing any file. If you are already on another branch, stay on it: the manual belongs with the work on that branch.
- **Commits.** Commit the approved English manual first, together with a base glossary created in this run; then the translations (one commit for all languages is fine); then glossary updates from flagged terms. Leave out the product brief, screenshots, and the progress file.
- **Push and pull request** at the end of Step 11, as far as the `git` setting goes.

## Progress file

Keep `.claude/write-manual/progress.md` in the project so a run survives a context compaction or a restart. After each step, append the step number, what it produced, and the paths involved (product brief, screenshots, manual files, glossaries, commits). At the start of a run, if the file exists and its last step is not Step 11, show the user where the previous run stopped and ask whether to resume from there or start over. Delete the file after Step 11.

## When to proceed and when to ask

Carry on without asking between steps. Stop and ask when:

- the help directory, target languages, or product identity is ambiguous after Step 1
- the working tree has changes the skill did not make (see git.md)
- a scout gap leaves a section of the manual without facts
- the verifier still reports critical issues after three fix rounds
- the push or pull request fails

The interactive checkpoints in Steps 4, 7, and 10 are the user's to answer; don't skip them.

## Process

### Step 1. Orient

No agents needed — the orchestrator does this directly.

1. **Resolve project path** from `$ARGUMENTS` or use the current working directory.
2. **Read `CLAUDE.md`** at the project root. This gives you the product's tech stack, conventions, and architecture.
3. **Read `README.md`** if it exists. This gives you the product description and setup instructions.
4. **Find the help directory** (`HELP_DIR` from here on): glob for `**/help/**/*.html` or `**/manual.html` or `**/docs/**/*.html`. Note:
   - Where existing manual files live (the output target)
   - Which languages already exist (subdirectories like `en/`, `fr/`, `de/`)
   - Whether a shared CSS file exists
   - Where the logo file is
5. **Find plan files**: glob for `docs/plans/**/*.md`. Read completed plans (in `completed/` subdirectory) and any active plans with all checkboxes ticked. These describe implemented features.
6. **Find source directories**: identify where UI code, config, services, and localization files live from the project structure in CLAUDE.md.
7. **Find glossary files**: check `HELP_DIR/glossaries/` for `base.json` and any `<lang>.json` files. A missing base glossary is created after Step 4; missing language glossaries grow from the terms translators flag.
8. **Branch** per the Git section above.
9. **Screenshots (optional).** A launched app opens windows that take focus from whatever the user is doing, which matters with a screen reader. So ask the user once whether the app may be launched here, and before each launch say what will open and roughly how long it will stay open, then wait for a yes; approval for one launch does not carry over to the next. Batch every capture into as few launches as possible. With a yes, build and run it, then capture the main window and each dialog you can reach to `help/.screenshots/` (on Windows, a PowerShell screen capture of the app window works; name each file after the window). Read them yourself to confirm they show what you expect. Screenshots are evidence of real layout, control order, and labels, which code alone only implies. If the app can't be launched, skip this; the scouts work from code either way.

Report to the user:
- Product name and description (from CLAUDE.md/README)
- Existing help file location and languages found
- Number of completed plans found
- Source directories identified
- Glossary status (which languages have glossaries, which don't)
- Branch, and how many screenshots were captured (if any)

### Step 2. Scout (Haiku agents, parallel)

Read all six scout prompt templates from `$SKILL_DIR/references/scouts/`. For each, substitute project-specific file paths discovered in Step 1.

Spawn all scouts in parallel (one message, six Agent calls) with `model: "haiku"`. Each scout gets:
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

Spawn one agent with `model: "sonnet"`:
- The researcher prompt
- All six scout outputs (full JSON, not summarized)
- CLAUDE.md content
- README.md content
- Completed plan file summaries
- The screenshot paths from Step 1, if any, with the instruction to read them and treat them as the authority on layout, labels, and control order where they disagree with the ui-layout scout

The researcher produces:
- A **product brief** (structured research document)
- A **question list** (uncertainties, ranked by importance)

Save the product brief to `help/.product-brief.md` (the leading dot marks it as temporary).

### Step 4. Clarification (interactive)

Present the researcher's questions to the user using AskUserQuestion. Group questions by importance:
- Must answer (manual accuracy depends on these)
- Should answer (would improve quality)
- Nice to know (adds depth)

For multiple-choice questions, use the `options` format. For open-ended questions, use free-text.

Collect all answers. Append them to the product brief.

If `HELP_DIR/glossaries/base.json` does not exist, create it now from the brief: the product and company names, the platform and assistive-technology names that are never translated, and any capitalization rules the brief implies. Take the format from `$SKILL_DIR/references/glossaries/examples/base.json` and check it against `base-glossary.schema.json`. Show the user the entries in a short list; they can correct them before the writer relies on them.

### Step 5. Write (Opus agent)

Read the writer prompt from `$SKILL_DIR/references/prompts/writer.md`.
Read all rules files from `$SKILL_DIR/references/rules/`.
Read `HELP_DIR/glossaries/base.json`, and `HELP_DIR/glossaries/en.json` if it exists.

Spawn one agent with `model: "opus"`:
- The writer prompt
- The complete product brief (with user's answers appended)
- All four rules files (html.md, encoding.md, tone.md, keyboard.md), pasted in full: the writer needs every rule while it writes, so they go in the prompt rather than by reference
- The base glossary, and the English glossary if there is one
- The existing manual (if any) — clearly marked as "reference only, do not copy"
- The target file path (e.g. `src/ExampleApp/help/en/manual.html`)

Include this framing in the agent prompt:

> You are writing for a real person who just installed an app and wants to get things done. You are not writing a feature spec or an API reference. Every paragraph must pass this test: "Would a reader who just wants to use the app find this useful right now?"
>
> Start with a short welcome that tells the reader what the app is and what to expect. Then give them a Quick Start (4–5 steps to their first success). Only after that, explore features in depth — and always from the perspective of what the user wants to accomplish, not what the software contains.
>
> Do not name internal systems, do not use "the X feature" framing, do not list capabilities without motivation.

The writer outputs a single complete HTML file. The orchestrator writes it to the target path using the Write tool.

**Quick pre-check before verification.** Scan the draft yourself — the verifier checks facts and rules, not framing:
- Does it start with a welcome or overview, not a tip?
- Is there a quick-start section in the first few screens of content?
- Does the Enter/shortcut table (if applicable) clearly show both directions (what to press for action A, what to press for action B)?
- Are settings explained with motivation, not just restated?
- Count the instances of "the X feature" — more than 2 means feature-catalog writing.

If the draft fails these checks, send it back to the writer with specific revision notes before running Step 6.

Report to the user: "English manual draft written to PATH."

### Step 6. Verify (Sonnet agent + Haiku spot-checkers)

Read the verifier prompt from `$SKILL_DIR/references/prompts/verifier.md`.

Spawn one agent with `model: "sonnet"`:
- The verifier prompt
- The generated HTML manual (full content)
- The product brief
- All four rules files
- The base glossary, and the English glossary if there is one
- Source file paths for spot-checking
- The screenshot paths from Step 1, if any, for checking described layout, labels, and focus order against the real app

The verifier returns a structured report with critical, important, and minor issues, plus spot-check requests.

**If the verifier has spot-check requests**: spawn Haiku agents in parallel (`model: "haiku"`) to verify specific facts against source code. Feed their results back to the verifier.

Report the verification results to the user:
- Number of critical / important / minor issues
- Brief list of each issue (one line per issue)

### Step 7. Fix and present (loop)

**If the verifier found critical or important issues**:

1. Spawn the writer again (`model: "opus"`) with:
   - The current manual HTML
   - The full verification report
   - Instructions to fix all critical and important issues, and as many minor issues as practical
2. Write the fixed HTML to the target path
3. Re-run verification (Step 6) on the fixed version
4. Repeat up to 3 times. If issues persist after 3 iterations, present the manual to the user with remaining issues listed.

**When verification passes or max iterations reached**, present the manual to the user with AskUserQuestion:

```json
{
  "questions": [{
    "question": "The English manual is ready for your review. It's at TARGET_PATH. What would you like to do?",
    "header": "Manual review",
    "options": [
      {"label": "Looks good — proceed to translation", "description": "Approve the English manual and start translating"},
      {"label": "I have feedback", "description": "I'll describe what needs changing, or leave notes in the manual file"},
      {"label": "Stop here", "description": "Keep the English manual as-is, skip translation for now"}
    ],
    "multiSelect": false
  }]
}
```

**If the user has feedback**: they may describe it, or annotate the manual file itself using their note markers. When they say they are done ("done", "go", "continue"), gather every note and direct edit as `$SKILL_DIR/references/manual-review.md` describes, and settle every doubt with the user before anything is revised. You don't edit manual content yourself, so hand the writer each note with its location and surrounding text, the direct edits to keep, and the instruction to remove the notes. After the writer returns, search for the markers again; none may remain. Then re-verify and present again. Repeat until the user approves or stops.

**On approval** (or "Stop here"), commit the English manual per the Git section.

### Step 8. Translate (Sonnet agents, parallel)

Only proceed here if the user approved the English manual for translation.

1. **Determine target languages**: check which language directories exist in the help folder (e.g. `fr/`, `de/`, `ru/`, `uk/`). Also ask the user if they want to add new languages.

2. **Check glossaries**: for each target language, check if `HELP_DIR/glossaries/<lang>.json` exists.
   - If a glossary is missing, inform the user: "No glossary found for LANGUAGE. The translator will use its best judgment and flag terms for glossary creation."

3. **Read the translator prompt** from `$SKILL_DIR/references/prompts/translator.md`.

4. **Spawn one agent per language** in parallel, each with `model: "sonnet"`:
   - The translator prompt
   - The approved English HTML manual
   - The language glossary (if it exists)
   - The base glossary
   - encoding.md and keyboard.md rules
   - The target file path (e.g. `src/ExampleApp/help/fr/manual.html`)
   - The path to the relevant `.po` localization file for that language (so the translator can read exact UI string translations from it)
   - The instruction: "Write the output file directly, with no HTML comments anywhere in it."

5. **Collect outputs**: each translator produces either:
   - A plain HTML file (no flagged terms), OR
   - A preamble with flagged terms, a blank line, then the HTML file

   Parse the output: if it starts with `FLAGGED TERMS:`, extract the flagged-terms block and write only the HTML portion (starting from `<!DOCTYPE html>`) to the target file. Collect flagged terms separately for reporting.

6. **Write translated files** to their target paths. Check that each file starts with `<!DOCTYPE html>` and contains no HTML comments; strip any extraneous content before writing.

Report to the user: "Translations complete for X languages. Y terms flagged for glossary additions." List any flagged terms.

### Step 9. Verify translations (Sonnet, per language)

For each translated manual, run a lighter verification pass. Spawn agents in parallel (`model: "sonnet"`), each checking:
- Glossary compliance — every glossary term uses the specified translation
- No HTML entities crept in (except the four allowed)
- `<kbd>` key names properly localized per the glossary's `keys` mapping
- RTL attributes correct (for Hebrew and future RTL languages)
- Proper diacritics, no ASCII approximations
- No untranslated strings left behind
- HTML structure matches the English original (same IDs, same sections, same number of articles)

If issues found, send back to the translator agent for fixes (up to 2 iterations per language).

Report to the user: translation verification results per language. Commit the translations per the Git section.

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

**If revising a translation**: ask which language, collect the feedback (described, or left as notes in that language's file, handled as in Step 7), and re-run that language's translator with it.

Each accepted revision is its own commit.

### Step 11. Cleanup and hand-off

After the user accepts all manuals:
- Delete the temporary product brief (`help/.product-brief.md`) and the screenshots (`help/.screenshots/`) if they were created
- If any terms were flagged during translation, offer to create or update glossary files:
  "X terms were flagged during translation. Would you like me to add them to the glossaries?" On yes, write them to `HELP_DIR/glossaries/<lang>.json` (a new file follows `language-glossary.schema.json`, with `examples/en.json` as the format reference) and commit them as their own commit.
- Push and open the pull request as far as the `git` setting goes (see git.md)
- Delete the progress file
- Report completion: "Manual complete. English + X translations written to HELP_DIR." Add the branch, commits, and pull request URL.

## Key rules

- Every agent is spawned via the Agent tool with an explicit `model` parameter; scouts, translators, and translation verifiers run in parallel (one message, multiple Agent calls)
- The orchestrator writes no manual content itself — only agents write content
- Pass agent output between agents in full, not summarized or filtered
- Glossary terms are fixed: no synonyms, no variation
- UTF-8, raw Unicode, no HTML entities (except `&lt;`, `&gt;`, `&amp;`, `&nbsp;`), no HTML comments in any manual
- American English spelling for the English manual
- WCAG 2.2 AA compliance is a hard requirement
- The user approves the English manual before any translation begins
