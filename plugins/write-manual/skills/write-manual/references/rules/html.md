# HTML Requirements

These are non-negotiable rules for all manual HTML output.

## File structure

- One HTML file per language (e.g. `en/manual.html`, `fr/manual.html`)
- UTF-8 encoding, declared with `<meta charset="utf-8">`
- `<!DOCTYPE html>` declaration
- `<html>` element must have `lang` attribute matching the language (e.g. `lang="en"`, `lang="ru"`, `lang="he"`)
- `<html>` element must have `dir` attribute for RTL languages (`dir="rtl"` for Hebrew, `dir="ltr"` for others)
- CSS is either inline in a `<style>` block or in a shared `style.css` in the help root folder — never per-language CSS files
- Logo is an external file shared across language folders (referenced via relative path like `../logo.png`), never base64-embedded
- No deviation in styles or image layout between languages

## Semantic structure

- `<header>` — product logo and name
- `<main>` — all manual content
- `<nav aria-label="Table of contents">` — table of contents inside `<main>`
- `<article aria-labelledby="section-id">` — each major section, with `aria-labelledby` pointing to its heading's `id`
- `<footer>` — copyright, links

## Heading hierarchy

- `<h1>` — product name (once, in the header)
- `<h2>` — major sections (Overview, Installation, Creating notes, etc.) and the ToC heading
- `<h3>` — subsections within a section
- `<h4>` — sub-subsections, used sparingly and only when genuinely needed
- Every heading must have an `id` attribute for ToC linking
- Headings must not skip levels (no h2 followed directly by h4)

## Content elements

Allowed and encouraged:
- `<p>` for paragraphs
- `<ul>`, `<ol>` for lists
- `<dl>`, `<dt>`, `<dd>` for definition lists (great for settings, modes, menu items)
- `<table>` for simple, uniform data (keyboard shortcuts, comparison grids) — must have `<thead>` and `<tbody>`
- `<kbd>` for keyboard references (see keyboard.md for formatting rules)
- `<code>` for file paths, config values, technical identifiers
- `<strong>` for UI element names (menu items, button labels, setting names)
- `<em>` for emphasis
- `<a>` for internal cross-references and external links — meaningful link text, never "click here"
- `<details>` with `<summary>` only where genuinely useful (FAQ, troubleshooting collapsible steps)
- Elements with `role="note"` for tips and callouts

Forbidden:
- Complex non-uniform tables (tables where cells span multiple rows/columns)
- `<canvas>`, `<svg>` inline content
- Image maps (`<map>`, `<area>`)
- Inline event handlers (`onclick`, etc.)
- `<div>` or `<span>` where a semantic element exists

## Accessibility — WCAG 2.2 AA

- Color contrast: minimum 4.5:1 for normal text, 3:1 for large text, in both light and dark modes
- All images must have descriptive `alt` text
- Reading order in the DOM must match visual order
- Focus indicators must be visible for any interactive elements
- No information conveyed by color alone
- Landmark regions: `<header>`, `<nav>`, `<main>`, `<footer>`, `<article>`
- Language attribute on `<html>` must be correct

## Dark mode

- Support `prefers-color-scheme: dark` media query
- All colors must have dark-mode equivalents
- Contrast ratios must meet WCAG 2.2 AA in both modes
- Test both modes — do not assume light-mode colors work inverted

## RTL support

- Use logical CSS properties: `margin-inline-start` not `margin-left`, `padding-inline-end` not `padding-right`
- Use `text-align: start` not `text-align: left`
- Tables, lists, and definition lists must render correctly in RTL
- `dir="rtl"` on `<html>` for RTL languages
- Test layout with RTL content — mirroring must be correct
