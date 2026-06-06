# Keyboard Formatting Rules

## The `<kbd>` element

All keyboard references must be wrapped in `<kbd>`. Style `<kbd>` as bold via CSS (`font-weight: bold` or `font-weight: 600`) — do not use `<strong>` for keyboard shortcuts.

## Formatting conventions

### Single keys

Wrap in `<kbd>` with the canonical name:
- `<kbd>Enter</kbd>`, `<kbd>Escape</kbd>`, `<kbd>Delete</kbd>`, `<kbd>Tab</kbd>`, `<kbd>Space</kbd>`
- `<kbd>F1</kbd>`, `<kbd>F2</kbd>`, etc.
- Letter keys are always uppercase: `<kbd>C</kbd>`, not `<kbd>c</kbd>`

### Key combinations (simultaneous)

One `<kbd>` element for the whole combination. Keys joined with `+`, no spaces:
- `<kbd>Ctrl+C</kbd>` — not `<kbd>Ctrl</kbd>+<kbd>C</kbd>`
- `<kbd>Ctrl+Alt+Shift+N</kbd>`
- `<kbd>Alt+F4</kbd>`

### Key sequences (one after another)

Separate `<kbd>` elements joined by comma and space:
- `<kbd>Ctrl+K</kbd>, <kbd>B</kbd>` — means press Ctrl+K, release, then press B

### Modifier key order

Always in this order: Ctrl, Alt, Shift, then the key:
- `<kbd>Ctrl+Alt+Shift+N</kbd>` — not `<kbd>Shift+Alt+Ctrl+N</kbd>`

## Localized key names

Key names must be localized per language. The language glossary's `keys` object maps English canonical names to localized equivalents. Only keys that differ from English need entries.

Common localizations:
- **German**: Ctrl → Strg, Delete → Entf, Escape → Esc (same), Enter → Eingabe (context-dependent, often kept as Enter)
- **French**: Shift → Maj, Delete → Suppr, Escape → Échap
- **Russian**: key names are typically kept in Latin script (Ctrl, Shift, Alt, Enter, Delete) — do not transliterate to Cyrillic
- **Hebrew**: key names are kept in Latin script, written left-to-right within RTL text

When a key name is not in the glossary, keep the English name unchanged.

## Braille dot notation

For Braille dot combinations (not pertinent for all products, but may occur):
- Use `<strong>` not `<kbd>` — Braille dots are not keyboard keys
- Use `&nbsp;` between "Dots" and the number sequence
- Format: `<strong>Dots&nbsp;1+3+5+6+Space</strong>`
- Chord names use the same pattern: `<strong>Dots&nbsp;1+3+5+6+Space</strong>` for Z-chord

## CSS for `<kbd>`

Minimum styling (adapt to match the manual's design):

```css
kbd {
    display: inline-block;
    padding: 0.1em 0.4em;
    font-size: 0.9em;
    font-weight: 600;
    font-family: inherit;
    background: #f0f0f0;
    border: 1px solid #ccc;
    border-radius: 3px;
    white-space: nowrap;
}
```

Dark mode equivalent must maintain WCAG 2.2 AA contrast.
