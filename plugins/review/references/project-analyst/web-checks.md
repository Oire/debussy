# Checking a web UI in a real browser

For any project that renders HTML, measure the running page instead of judging
it from source. The scanner does the measuring; this file says how to run it and
how not to fool yourself with what it, or a probe of your own, reports.

## Running the scanner

The toolchain (Playwright, axe-core, Chromium's headless shell) installs once
into the plugin's data directory. It is a download of roughly 150 MB, so say so
in your report the first time:

```
node ${CLAUDE_PLUGIN_ROOT}/scripts/web-scan/setup.mjs ${CLAUDE_PLUGIN_DATA}/web-scan
```

Then point it at the page. A static site is a `file:///` URL. An app needs its
dev server: start it in the background, note the port, and stop it when you
are done.

```
node ${CLAUDE_PLUGIN_ROOT}/scripts/web-scan/scan.mjs scan    --url URL --toolchain ${CLAUDE_PLUGIN_DATA}/web-scan
node ${CLAUDE_PLUGIN_ROOT}/scripts/web-scan/scan.mjs reflow  --url URL --zoom 400 --toolchain ...
node ${CLAUDE_PLUGIN_ROOT}/scripts/web-scan/scan.mjs spacing --url URL --toolchain ...
node ${CLAUDE_PLUGIN_ROOT}/scripts/web-scan/scan.mjs shot    --url URL --selector CSS --toolchain ...
```

Each run prints a one-line summary and the path of its JSON; the screenshots sit
beside it. Everything runs in the headless shell, which never shows a window.
Scan the main page types (home, a form, a list, a detail page, a dialog in its
open state), not just the front page.

What `scan` gives you:
- axe-core violations and "needs review" items, in the page and in every
  visible iframe;
- the accessibility tree as the browser computed it (`*-tree.yaml`), with the
  landmarks and headings pulled out;
- text contrast measured against the composited background, with a note where
  an image, gradient, filter, or blend mode makes the number uncertain;
- the real Tab order, with the stops that show no visible focus change, the
  stops hidden under sticky or fixed content (2.4.11), and a suspected trap
  when focus cycles through the same few stops;
- undersized pointer targets that also fail the 24-pixel spacing exception
  (2.5.8).

## Evidence, not verdicts

Everything the scanner reports is a lead. A finding needs the behavior itself
behind it: the screenshot showing the clipped text, the key sequence that
leaves focus stuck. For the coverage list, the same goes the other way: a pass
you record should rest on something you observed, not only on a script that
returned nothing.

The rule behind every trap below: **a check that is meant to show something
changed must be run before the action too.** If it already reports the
after-state before you press anything, the check is broken, not the page
fixed. And treat a pass from a probe you wrote yourself as a hypothesis until
you have reproduced it the way a person would: pressed the key, looked at the
screenshot.

## Checks that mislead

- **`offsetParent === null` is not "hidden".** It is null for every
  `position: fixed` element, which covers most banners, dialogs, toasts, and
  sticky headers. Test visibility with the computed `display`, `visibility`,
  and `opacity` plus a bounding box inside the viewport.
- **CSS `zoom` is not browser zoom.** It leaves the viewport and media queries
  untouched. Browser zoom shrinks the CSS viewport in both dimensions (200% of
  1280 by 800 is 640 by 400), which is what `reflow` does.
- **No horizontal scrollbar does not mean reflow passes.** The common failure
  is vertical: a fixed-height box with hidden overflow silently cuts its text.
  `reflow` measures where the text actually flows against the clipping box.
- **The computed `color` is not always the painted color.**
  `-webkit-text-fill-color` overrides it, and a filter or blend mode on any
  ancestor changes what is painted without changing any computed color. Check
  flagged contrast on a screenshot.
- **Measure after scrolling the element into view.** Positions taken before
  a scroll describe a different layout.
- **"No click handler found" does not mean inert.** Frameworks delegate events
  to ancestors. Click it, or press Enter and Space on it, and watch what
  changes.
- **A control with `role="button"` must answer Space as well as Enter.**
  Activating it with Enter proves nothing about Space.
- **"Loading" is not the content.** Late-rendering widgets get measured as
  their placeholder unless you wait for them (`--ready` with an expression
  that is true once they are there).
- **State leaks between runs.** Each scanner run starts a fresh browser
  context, but an interactive probe can leave a menu open or a banner
  dismissed. Reset the state before the next capture.
