# Frontend and web checks

Read this for any project that renders HTML: sites, SPAs, SSR apps, Electron and
Tauri UIs. It covers what is specific to the web beyond the WCAG criteria in the
agent itself.

## Semantics and ARIA

- Landmarks, one `h1`, heading levels that do not skip, real lists and tables.
- `div` or `span` with a click handler where a `button` or `a` belongs.
- ARIA only where native HTML falls short, and correct when used: roles match
  behavior, `aria-live` on content that updates, custom widgets that follow the
  WAI-ARIA Authoring Practices keyboard model.
- SPA focus management: focus moves on route change, into and back out of modals.

## Presentation

- Works at 320px wide without horizontal scrolling and at 200% text size.
- Visible focus indicator on every interactive element, not removed by a reset.
- Favicon, `lang` on `<html>`, descriptive `<title>` per page, meta description.
- Typography: line height, readable line length, consistent scale.
- Component styling consistent; no mix of styled and browser-default controls.

## Build

- Environment handling that keeps secrets out of the client bundle.
- Assets optimized (image formats and sizes, fonts subset or preloaded).
- Accessibility tests in CI (axe-core, pa11y, or Lighthouse CI).
