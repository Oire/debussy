# Encoding and Character Rules

These are non-negotiable rules for all manual output.

## File encoding

- Always UTF-8
- Declared with `<meta charset="utf-8">` in the HTML head
- No BOM (byte order mark)

## Unicode — no HTML entities

Use raw Unicode characters always. Never use HTML entities for characters that can be represented directly in UTF-8.

Forbidden:
- `&mdash;` — use `—` (U+2014)
- `&ndash;` — use `–` (U+2013)
- `&rsquo;` — use `'` (U+2019)
- `&ldquo;` / `&rdquo;` — use `"` `"` (U+201C / U+201D)
- `&bull;` — use `•` (U+2022)
- `&hellip;` — use `…` (U+2026)
- `&#xNNNN;` or `&#NNNN;` numeric references — use the actual character
- Any named or numeric entity for a character that exists in Unicode

Allowed exceptions (syntactically required by HTML):
- `&lt;` for `<` when it would be parsed as a tag
- `&gt;` for `>` when it would be parsed as a tag
- `&amp;` for `&` when it would be parsed as an entity
- `&nbsp;` for non-breaking spaces where semantically needed (e.g. Braille dot notation: `Dots&nbsp;1+3+5+6`)

## No HTML comments

HTML comment blocks (`<!-- ... -->`) are forbidden in the output. Do not add translator notes, section markers, TODO markers, or any other comments. The output is a clean, final document.

## Spelling

- **English manual**: American English spelling (color, organize, behavior, canceled)
- **Other languages**: proper native orthography with all diacritics
  - German: ä, ö, ü, ß — never ae, oe, ue, ss
  - French: é, è, ê, ë, ç, à, ù, î, ô, û, ï, ÿ, æ, œ — never ASCII approximations
  - Russian: full Cyrillic, standard orthography with ё where appropriate
  - Ukrainian: full Ukrainian Cyrillic including ґ, є, і, ї
  - Hebrew: full Hebrew script including nikud (vowel marks) only where conventional
