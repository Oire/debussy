# Tone and Writing Style

## Voice: the friendly expert

Write as someone who knows the app inside out, genuinely wants to help, and respects the reader's time. The reader may be a complete beginner or a power user — the writing must work for both without being condescending to either.

- Second person throughout: "you" and "your," never "the user"
- Warm but not trying to be funny — no jokes, no emoji, no marketing fluff
- Confident and direct — don't hedge with "you might want to" when "you can" is accurate

## Task-first, not feature-first

Lead with what the reader wants to accomplish, not with the feature name.

Good: "To quickly capture a thought without leaving your current app, press Ctrl+Alt+Shift+N."
Bad: "The Quick Note feature provides a streamlined editor accessible via a global hotkey."

Good: "If you have a lot of notes, organizing them into categories can help you find things faster."
Bad: "ExampleApp supports three category modes: Tree, Flat, and None."

## Sentences and structure

- Short sentences, active voice
- One idea per sentence when explaining steps
- Imperative mood for instructions: "Press Enter" not "You should press Enter"
- Present tense: "ExampleApp saves your draft" not "ExampleApp will save your draft"

## Scenarios and examples

Use brief scenarios to anchor abstract features — show *why* you'd use something, not just *how*.

Good: "Say you're on a call and need to jot something down — press Ctrl+Alt+Shift+N and a small editor appears right away. Type your note, press Enter, and you're back to your call."

But not every feature needs a scenario. Use them for:
- Features whose purpose isn't obvious from the name
- Workflows that combine multiple features
- Situations where the reader might not realize a feature exists

Don't use scenarios for self-explanatory actions like "to delete a note, select it and press Delete."

## Tips and notes

Use sparingly — only when there's a genuinely non-obvious shortcut, gotcha, or important clarification. Wrap in an element with `role="note"`.

Good tip: "Tip: If you close the editor without saving, your work isn't lost — ExampleApp keeps it as a draft and restores it the next time you open the note."

Bad tip (too obvious): "Tip: You can use Ctrl+C to copy text."

## Instructions: keyboard first, mouse second

Always give keyboard instructions first, with mouse as an alternative. Slight preference toward keyboard phrasing.

Good: "Press Enter to open the note, or double-click it."
Good: "Right-click the category or press the context menu key, then choose Rename."
Bad: "Double-click a note to open it."
Bad: "Right-click and choose Rename."

## What to avoid

- Passive voice where active is clearer
- Jargon without explanation (but don't over-explain common terms)
- Repeating the section heading in the first sentence ("In this section, we will learn about...")
- Referring to the reader in third person
- Referencing internal implementation details (database tables, class names, config file format) unless the reader genuinely needs them (e.g. data storage paths)
- Feature-first framing: "The X feature provides Y" — instead, write "You can Y"
- Naming internal systems: "The Title Derivation system" — instead, describe the behavior: "If you leave the title blank, ExampleApp shows the first line"
- Unmotivated feature descriptions: don't list what a feature does without explaining why someone would care
- Starting with a tip or note — these should appear after the reader has context, not before
- Over-explaining self-evident settings: if "Start with Windows" is self-explanatory, don't write three sentences about it
- Marketing language or superlatives: "powerful," "seamless," "robust" — just say what it does
- Hedging when certainty is appropriate: "you might want to" when "you can" is accurate
