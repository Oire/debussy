#!/usr/bin/env node
/**
 * Accessibility evidence for a web page, gathered in Chromium's headless
 * shell, which never shows a window. It reports measurements, not verdicts:
 * whoever reads the output confirms a problem before calling it a finding.
 *
 *   node scan.mjs scan    --url URL [--out DIR] [--no-frames]
 *   node scan.mjs reflow  --url URL [--out DIR] [--zoom 200|400|320]
 *   node scan.mjs spacing --url URL [--out DIR]
 *   node scan.mjs shot    --url URL [--out DIR] [--selector CSS] [--full]
 *
 * Every command takes:
 *   --toolchain DIR   where setup.mjs installed Playwright and axe-core
 *                     (default: $WEB_SCAN_TOOLCHAIN)
 *   --viewport WxH    default 1280x800
 *   --wait MS         settle time after load, default 1500
 *   --ready "EXPR"    poll a JavaScript expression until truthy before
 *                     measuring, for content that renders late
 *   --ua STRING       user agent, for sites that serve nothing to headless
 *
 * Output goes to --out (default: <os temp>/web-scan/<slug>); the JSON path is
 * printed on the last line.
 *
 * scan     axe-core (WCAG 2.x A and AA rules) in the page and in every visible
 *          iframe; the accessibility tree as the browser computes it;
 *          contrast measured against the composited background; the real Tab
 *          order with focus visibility, obscured focus, and trap detection;
 *          undersized targets; a full-page screenshot.
 * reflow   the page at the CSS viewport a browser zoom produces (both
 *          dimensions shrink), reporting horizontal scrolling, text clipped
 *          inside overflow-hidden containers, and text drawn over text.
 * spacing  the same layout checks after the WCAG 1.4.12 text-spacing
 *          overrides, reporting only what the overrides broke.
 * shot     a screenshot of the page or of one element, outlined.
 */

import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';

// ------------------------------------------------------------------ setup --

const [command, ...rest] = process.argv.slice(2);
const args = {};
for (let i = 0; i < rest.length; i += 1) {
  if (!rest[i].startsWith('--')) continue;
  const next = rest[i + 1];
  if (next === undefined || next.startsWith('--')) args[rest[i].slice(2)] = true;
  else { args[rest[i].slice(2)] = next; i += 1; }
}

const COMMANDS = { scan: runScan, reflow: runReflow, spacing: runSpacing, shot: runShot };
if (!COMMANDS[command] || !args.url) {
  console.error('usage: node scan.mjs <scan|reflow|spacing|shot> --url URL [--toolchain DIR] [options]; see the header of this file');
  process.exit(2);
}

const toolchain = args.toolchain || process.env.WEB_SCAN_TOOLCHAIN;
if (!toolchain) {
  console.error('error: no toolchain; run setup.mjs and pass --toolchain DIR');
  process.exit(2);
}
process.env.PLAYWRIGHT_BROWSERS_PATH = join(resolve(toolchain), 'browsers');
const requireFromToolchain = createRequire(join(resolve(toolchain), 'package.json'));
let chromium;
let axeSource;
try {
  ({ chromium } = requireFromToolchain('playwright'));
  axeSource = readFileSync(requireFromToolchain.resolve('axe-core/axe.min.js'), 'utf8');
} catch {
  console.error(`error: Playwright or axe-core is missing from ${toolchain}; run setup.mjs first`);
  process.exit(2);
}

// Named after the host and the last two path segments, which is what tells
// pages apart; a file:// URL has no host and a long, uninformative directory.
const slug = (() => {
  const u = new URL(args.url);
  const parts = [u.hostname, ...u.pathname.split('/').filter(Boolean).slice(-2)].filter(Boolean);
  return parts.join('-').replace(/[^\p{L}\p{N}]+/gu, '-').replace(/^-|-$/g, '').slice(0, 60) || 'page';
})();
const outDir = resolve(args.out || join(tmpdir(), 'web-scan', slug));
mkdirSync(outDir, { recursive: true });

const size = (text, fallback) => {
  const [w, h] = String(text || fallback).split('x').map(Number);
  return { width: w, height: h };
};

async function open(viewport) {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    viewport,
    userAgent: args.ua ? String(args.ua) : undefined,
  });
  const page = await context.newPage();
  await page.goto(args.url, { waitUntil: 'load', timeout: 120000 });
  await page.waitForTimeout(Number(args.wait || 1500));
  if (args.ready) {
    const deadline = Date.now() + 120000;
    for (;;) {
      const ok = await page.evaluate(`(() => (${args.ready}))()`).catch(() => false);
      if (ok) break;
      if (Date.now() > deadline) throw new Error(`--ready never became true: ${args.ready}`);
      await page.waitForTimeout(1000);
    }
  }
  return { browser, page };
}

function save(name, data) {
  const file = join(outDir, name);
  writeFileSync(file, `${JSON.stringify(data, null, 2)}\n`, 'utf8');
  return file;
}

// ------------------------------------------------------- in-page probes --
// These run inside the browser, so they may not use anything from this module.

function pageProbe() {
  const label = (el) => {
    let s = el.tagName.toLowerCase();
    if (el.id) s += `#${el.id}`;
    else if (typeof el.className === 'string' && el.className.trim()) s += `.${el.className.trim().split(/\s+/)[0]}`;
    return s;
  };
  const shown = (el) => {
    const cs = getComputedStyle(el);
    const r = el.getBoundingClientRect();
    return cs.display !== 'none' && cs.visibility !== 'hidden' && Number(cs.opacity) !== 0 && r.width > 0 && r.height > 0;
  };

  // Colors come back as rgb()/rgba(); anything else (a named color keyword in
  // a newer color space) is skipped rather than guessed at.
  const rgba = (text) => {
    const m = /rgba?\(([^)]+)\)/.exec(text || '');
    if (!m) return null;
    const [r, g, b, a = 1] = m[1].split(/[\s,/]+/).filter(Boolean).map(Number);
    return { r, g, b, a };
  };
  const blend = (top, under) => ({
    r: top.r * top.a + under.r * (1 - top.a),
    g: top.g * top.a + under.g * (1 - top.a),
    b: top.b * top.a + under.b * (1 - top.a),
    a: 1,
  });
  const lum = ({ r, g, b }) => {
    const c = (v) => { const s = v / 255; return s <= 0.04045 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4; };
    return 0.2126 * c(r) + 0.7152 * c(g) + 0.0722 * c(b);
  };
  const hex = (c) => `#${[c.r, c.g, c.b].map((v) => Math.round(v).toString(16).padStart(2, '0')).join('')}`;

  // What is painted behind an element: every semi-transparent background up
  // the ancestor chain, flattened onto white. An image or gradient on the way
  // means the number is only an estimate, and a filter or blend mode means it
  // may be wrong outright; both are flagged for checking on a screenshot.
  const backdrop = (el) => {
    const stack = [];
    let uncertain = null;
    for (let n = el; n && n.nodeType === 1; n = n.parentElement) {
      const cs = getComputedStyle(n);
      if (!uncertain && cs.backgroundImage !== 'none') uncertain = 'background image or gradient';
      if (!uncertain && (cs.filter !== 'none' || cs.mixBlendMode !== 'normal')) uncertain = 'filter or blend mode';
      const bg = rgba(cs.backgroundColor);
      if (bg && bg.a > 0) { stack.push(bg); if (bg.a >= 1) break; }
    }
    let color = { r: 255, g: 255, b: 255, a: 1 };
    for (let i = stack.length - 1; i >= 0; i -= 1) color = blend(stack[i], color);
    return { color, uncertain };
  };

  const contrast = [];
  const seen = new Set();
  for (const el of document.body.querySelectorAll('*')) {
    if (![...el.childNodes].some((n) => n.nodeType === 3 && n.textContent.trim())) continue;
    if (!shown(el)) continue;
    const cs = getComputedStyle(el);
    // -webkit-text-fill-color, when set, is what is painted; `color` is not.
    const painted = rgba(cs.webkitTextFillColor) || rgba(cs.color);
    if (!painted) continue;
    const { color: bg, uncertain } = backdrop(el);
    const fg = painted.a < 1 ? blend(painted, bg) : painted;
    const [hi, lo] = [lum(fg), lum(bg)].sort((a, b) => b - a);
    const ratio = (hi + 0.05) / (lo + 0.05);
    const px = parseFloat(cs.fontSize);
    const bold = Number(cs.fontWeight) >= 700;
    const large = px >= 24 || (px >= 18.66 && bold);
    const needed = large ? 3 : 4.5;
    if (ratio >= needed && !uncertain) continue;
    const key = `${hex(fg)}/${hex(bg)}/${large}`;
    if (seen.has(key)) continue;
    seen.add(key);
    contrast.push({
      ratio: Math.round(ratio * 100) / 100,
      needed,
      foreground: hex(fg),
      background: hex(bg),
      uncertain,
      fontSizePx: px,
      bold,
      element: label(el),
      text: el.textContent.trim().slice(0, 80),
    });
  }

  // WCAG 2.5.8: a pointer target is at least 24 by 24 CSS pixels, unless a
  // 24-pixel circle centered on it touches no other target and no other small
  // target's circle (the spacing exception). Links inside a run of text are
  // exempt too.
  const interactive = 'button, a[href], input:not([type=hidden]), select, textarea, summary, [role=button], [role=link], [role=checkbox], [role=radio], [role=tab], [role=menuitem], [role=switch]';
  const targets = [...document.querySelectorAll(interactive)].filter(shown).map((el) => ({ el, r: el.getBoundingClientRect() }));
  const center = ({ r }) => ({ x: r.left + r.width / 2, y: r.top + r.height / 2 });
  const circleHitsRect = (c, r) => {
    const dx = Math.max(r.left - c.x, 0, c.x - r.right);
    const dy = Math.max(r.top - c.y, 0, c.y - r.bottom);
    return dx * dx + dy * dy < 144;
  };
  const inText = (el) => el.tagName === 'A' && getComputedStyle(el).display === 'inline'
    && [...(el.parentElement?.childNodes || [])].some((n) => n !== el && n.nodeType === 3 && n.textContent.trim().length > 1);
  const small = targets.filter((t) => (t.r.width < 24 || t.r.height < 24) && !inText(t.el));
  const smallTargets = [];
  for (const t of small) {
    const c = center(t);
    const crowdedBy = targets.find((o) => o !== t && !o.el.contains(t.el) && !t.el.contains(o.el) && (
      circleHitsRect(c, o.r)
      || (small.includes(o) && Math.hypot(c.x - center(o).x, c.y - center(o).y) < 24)));
    if (!crowdedBy) continue;
    smallTargets.push({
      element: label(t.el),
      text: (t.el.innerText || t.el.getAttribute('aria-label') || '').trim().slice(0, 60),
      width: Math.round(t.r.width),
      height: Math.round(t.r.height),
      tooCloseTo: label(crowdedBy.el),
    });
    if (smallTargets.length >= 40) break;
  }

  const ids = {};
  for (const el of document.querySelectorAll('[id]')) ids[el.id] = (ids[el.id] || 0) + 1;

  return {
    title: document.title,
    lang: document.documentElement.getAttribute('lang'),
    contrast: contrast.sort((a, b) => a.ratio - b.ratio),
    smallTargets,
    duplicateIds: Object.entries(ids).filter(([, n]) => n > 1).map(([id, count]) => ({ id, count })),
    autoplayingMedia: [...document.querySelectorAll('video[autoplay], audio[autoplay]')].map(label),
  };
}

function layoutProbe() {
  const label = (el) => {
    let s = el.tagName.toLowerCase();
    if (el.id) s += `#${el.id}`;
    else if (typeof el.className === 'string' && el.className.trim()) s += `.${el.className.trim().split(/\s+/)[0]}`;
    return s;
  };
  const shown = (el) => {
    const cs = getComputedStyle(el);
    const r = el.getBoundingClientRect();
    return cs.display !== 'none' && cs.visibility !== 'hidden' && r.width > 0 && r.height > 0;
  };
  // Every element that holds text of its own, with the box its text is laid
  // out in. A Range measures where the text actually flows, including the part
  // an overflow clip hides; the element's own box would stop at the clip.
  const textExtent = (el) => {
    const range = document.createRange();
    range.selectNodeContents(el);
    return range.getBoundingClientRect();
  };
  const leaves = [...document.body.querySelectorAll('*')]
    .filter((el) => [...el.childNodes].some((n) => n.nodeType === 3 && n.textContent.trim().length >= 3))
    .filter(shown)
    .slice(0, 2000);

  // Text cut off by its own box or an ancestor that hides overflow: measured
  // from the text's extent against the clipping box, since scrollHeight is
  // easily inflated by visually hidden content and proves nothing on its own.
  const clipped = [];
  for (const el of leaves) {
    const r = textExtent(el);
    for (let p = el; p && p !== document.body; p = p.parentElement) {
      const cs = getComputedStyle(p);
      const clipY = /hidden|clip/.test(cs.overflowY);
      const clipX = /hidden|clip/.test(cs.overflowX);
      if (!clipX && !clipY) continue;
      const box = p.getBoundingClientRect();
      const below = clipY ? r.bottom - box.bottom : 0;
      const right = clipX ? r.right - box.right : 0;
      if (below > 3 || right > 3) {
        clipped.push({ text: el.innerText.trim().slice(0, 60), clippedBy: label(p), cutBelowPx: Math.max(0, Math.round(below)), cutRightPx: Math.max(0, Math.round(right)) });
      }
      break;
    }
    if (clipped.length >= 25) break;
  }

  const overlapping = [];
  const boxes = leaves.map((el) => ({ el, r: textExtent(el) }));
  outer: for (let i = 0; i < boxes.length; i += 1) {
    for (let j = i + 1; j < boxes.length; j += 1) {
      const a = boxes[i]; const b = boxes[j];
      if (a.el.contains(b.el) || b.el.contains(a.el)) continue;
      const w = Math.min(a.r.right, b.r.right) - Math.max(a.r.left, b.r.left);
      const h = Math.min(a.r.bottom, b.r.bottom) - Math.max(a.r.top, b.r.top);
      if (w > 4 && h > 4) {
        overlapping.push({ a: a.el.innerText.trim().slice(0, 50), b: b.el.innerText.trim().slice(0, 50), overlapPx: [Math.round(w), Math.round(h)] });
        if (overlapping.length >= 25) break outer;
      }
    }
  }

  const doc = document.documentElement;
  return {
    viewport: { width: innerWidth, height: innerHeight },
    horizontalScroll: doc.scrollWidth > doc.clientWidth + 1,
    documentWidth: doc.scrollWidth,
    clipped,
    overlapping,
  };
}

// ------------------------------------------------------------ Tab order --

// Press Tab and record where focus actually lands. For each stop, the styles
// it has while focused are compared with the styles it has once focus moves
// on: no difference means no visible focus indicator (2.4.7). A stop whose
// center is covered by another element is focus obscured (2.4.11). A short
// sequence of stops repeating without focus ever leaving the page is a trap
// (2.1.2) until checked with Escape and Shift+Tab by hand.
async function walkTabOrder(page, limit = 80) {
  // The styles a focus indicator can change. Written out in both evaluate
  // callbacks below, because a page's Content Security Policy can forbid
  // rebuilding a function from text inside the page.
  const focusStyleOf = (el) => {
    const cs = getComputedStyle(el);
    return [cs.outlineStyle, cs.outlineWidth, cs.outlineColor, cs.boxShadow, cs.backgroundColor, cs.borderColor, cs.color, cs.textDecorationLine].join('|');
  };
  await page.evaluate(() => { document.activeElement?.blur?.(); window.scrollTo(0, 0); });

  const stops = [];
  let previous = null;
  for (let i = 0; i < limit; i += 1) {
    await page.keyboard.press('Tab');
    const handle = await page.evaluateHandle(() => document.activeElement);
    const info = await handle.evaluate((el) => {
      if (!el || el === document.body || el === document.documentElement) return null;
      const cs = getComputedStyle(el);
      const style = [cs.outlineStyle, cs.outlineWidth, cs.outlineColor, cs.boxShadow, cs.backgroundColor, cs.borderColor, cs.color, cs.textDecorationLine].join('|');
      const r = el.getBoundingClientRect();
      const cx = r.left + r.width / 2;
      const cy = r.top + r.height / 2;
      const inView = r.width > 0 && r.height > 0 && r.bottom > 0 && r.right > 0 && r.top < innerHeight && r.left < innerWidth;
      const top = inView ? document.elementFromPoint(cx, cy) : null;
      const covered = inView && top && top !== el && !el.contains(top) && !top.contains(el);
      let name = el.tagName.toLowerCase();
      if (el.id) name += `#${el.id}`;
      return {
        element: name,
        text: (el.getAttribute('aria-label') || el.innerText || el.value || '').trim().slice(0, 60),
        inView,
        obscuredBy: covered ? `${top.tagName.toLowerCase()}${top.id ? `#${top.id}` : ''}` : null,
        style,
      };
    });

    if (previous) {
      const after = await previous.handle.evaluate(focusStyleOf).catch(() => null);
      previous.stop.visibleIndicator = after === null ? null : after !== previous.stop.style;
      delete previous.stop.style;
    }

    if (!info) {
      stops.push({ index: i + 1, leftPage: true });
      previous = null;
      continue;
    }
    const stop = { index: i + 1, ...info };
    stops.push(stop);
    previous = { handle, stop };

    const sig = stops.map((s) => (s.leftPage ? '<out>' : `${s.element}|${s.text}`));
    for (let period = 1; period <= 8; period += 1) {
      if (sig.length < period * 3) break;
      const tail = sig.slice(-period * 3);
      const cycle = tail.slice(0, period);
      if (cycle.includes('<out>')) continue;
      if (tail.every((s, k) => s === cycle[k % period])) {
        if (previous) delete previous.stop.style;
        return { stops, suspectedTrap: { period, cycle } };
      }
    }
  }
  if (previous) delete previous.stop.style;
  return { stops, suspectedTrap: null };
}

// ------------------------------------------------------------- commands --

async function runAxe(frame) {
  await frame.addScriptTag({ content: axeSource });
  const result = await frame.evaluate(() => window.axe.run(document, {
    runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'] },
    resultTypes: ['violations', 'incomplete'],
  }));
  const shape = (v) => ({
    rule: v.id,
    impact: v.impact,
    help: v.help,
    criteria: v.tags.filter((t) => /^wcag\d{3,}$/.test(t)),
    count: v.nodes.length,
    examples: v.nodes.slice(0, 8).map((n) => ({ target: n.target.join(' '), html: n.html.slice(0, 240) })),
  });
  return { violations: result.violations.map(shape), needsReview: result.incomplete.map(shape) };
}

async function runScan() {
  const { browser, page } = await open(size(args.viewport, '1280x800'));
  try {
    const axe = await runAxe(page);
    const frames = [];
    if (!args['no-frames']) {
      for (const frame of page.frames()) {
        if (frame === page.mainFrame() || !/^https?:|^file:/.test(frame.url())) continue;
        const holder = await frame.frameElement().catch(() => null);
        const box = holder ? await holder.boundingBox() : null;
        if (!box || box.width < 2 || box.height < 2) continue;
        try {
          frames.push({ url: frame.url(), title: await holder.getAttribute('title'), axe: await runAxe(frame), page: await frame.evaluate(pageProbe) });
        } catch (err) {
          frames.push({ url: frame.url(), error: String(err.message).slice(0, 200) });
        }
      }
    }
    const probe = await page.evaluate(pageProbe);
    // The tree the browser exposes to assistive technology, with the roles it
    // actually computed: landmarks, headings and their levels, names.
    const accessibilityTree = await page.locator('body').ariaSnapshot().catch((err) => `unavailable: ${err.message}`);
    writeFileSync(join(outDir, `${slug}-tree.yaml`), `${accessibilityTree}\n`, 'utf8');
    const treeLines = String(accessibilityTree).split('\n');
    const headings = treeLines.filter((l) => /- heading /.test(l)).map((l) => l.trim().replace(/^- /, ''));
    const landmarks = treeLines.filter((l) => /- (banner|main|navigation|contentinfo|complementary|search|region|form)\b/.test(l)).map((l) => l.trim().replace(/^- /, '').replace(/:$/, ''));

    const tab = await walkTabOrder(page);
    await page.screenshot({ path: join(outDir, `${slug}-page.png`), fullPage: true });

    const real = tab.stops.filter((s) => !s.leftPage);
    // A stop visited more than once (a trap, a wrap) is listed once.
    const once = (list) => [...new Set(list)];
    const report = {
      url: args.url,
      finalUrl: page.url(),
      viewport: page.viewportSize(),
      title: probe.title,
      lang: probe.lang,
      axe,
      landmarks,
      headings,
      accessibilityTreeFile: `${slug}-tree.yaml`,
      contrast: probe.contrast,
      smallTargets: probe.smallTargets,
      duplicateIds: probe.duplicateIds,
      autoplayingMedia: probe.autoplayingMedia,
      keyboard: {
        stops: real.length,
        withoutVisibleIndicator: once(real.filter((s) => s.visibleIndicator === false).map((s) => `${s.element} "${s.text}"`)),
        obscured: once(real.filter((s) => s.obscuredBy).map((s) => `${s.element} "${s.text}" under ${s.obscuredBy}`)),
        outOfView: once(real.filter((s) => !s.inView).map((s) => `${s.element} "${s.text}"`)),
        suspectedTrap: tab.suspectedTrap,
        order: tab.stops,
      },
      frames,
      screenshot: `${slug}-page.png`,
    };
    const file = save(`${slug}.json`, report);
    console.log(`axe: ${axe.violations.length} violation rule(s), ${axe.needsReview.length} needing review; contrast concerns: ${probe.contrast.length}; small targets: ${probe.smallTargets.length}; tab stops: ${real.length}, without visible focus: ${report.keyboard.withoutVisibleIndicator.length}, obscured: ${report.keyboard.obscured.length}${tab.suspectedTrap ? ', SUSPECTED TRAP' : ''}; frames: ${frames.length}`);
    console.log(file);
  } finally {
    await browser.close();
  }
}

// Browser zoom divides the CSS viewport in both dimensions. Emulating it with
// the CSS zoom property instead leaves the viewport and media queries alone,
// which hides exactly the failures this check exists for.
async function runReflow() {
  const base = size(args.viewport, '1280x800');
  const zoom = String(args.zoom || '400');
  const viewport = zoom === '320'
    ? { width: 320, height: 256 }
    : { width: Math.round(base.width / (Number(zoom) / 100)), height: Math.round(base.height / (Number(zoom) / 100)) };
  const { browser, page } = await open(viewport);
  try {
    const layout = await page.evaluate(layoutProbe);
    await page.screenshot({ path: join(outDir, `${slug}-reflow-${zoom}.png`), fullPage: false });
    const file = save(`${slug}-reflow-${zoom}.json`, { url: args.url, zoom, ...layout, screenshot: `${slug}-reflow-${zoom}.png` });
    console.log(`reflow ${zoom} at ${viewport.width}x${viewport.height}: horizontal scroll ${layout.horizontalScroll ? 'yes' : 'no'}, clipped ${layout.clipped.length}, overlapping ${layout.overlapping.length}`);
    console.log(file);
  } finally {
    await browser.close();
  }
}

const TEXT_SPACING = `* { line-height: 1.5 !important; letter-spacing: 0.12em !important; word-spacing: 0.16em !important; }
p { margin-bottom: 2em !important; }`;

async function runSpacing() {
  const { browser, page } = await open(size(args.viewport, '1280x800'));
  try {
    const before = await page.evaluate(layoutProbe);
    await page.addStyleTag({ content: TEXT_SPACING });
    await page.waitForTimeout(800);
    const after = await page.evaluate(layoutProbe);
    await page.screenshot({ path: join(outDir, `${slug}-spacing.png`), fullPage: true });
    // Only what the overrides broke counts against 1.4.12.
    const had = new Set([...before.clipped.map((c) => c.text), ...before.overlapping.map((o) => o.a + o.b)]);
    const result = {
      url: args.url,
      newlyClipped: after.clipped.filter((c) => !had.has(c.text)),
      newlyOverlapping: after.overlapping.filter((o) => !had.has(o.a + o.b)),
      horizontalScroll: after.horizontalScroll,
      screenshot: `${slug}-spacing.png`,
    };
    const file = save(`${slug}-spacing.json`, result);
    console.log(`text spacing: ${result.newlyClipped.length} newly clipped, ${result.newlyOverlapping.length} newly overlapping`);
    console.log(file);
  } finally {
    await browser.close();
  }
}

async function runShot() {
  const { browser, page } = await open(size(args.viewport, '1280x800'));
  try {
    const name = `${slug}-shot.png`;
    if (args.selector) {
      const target = page.locator(String(args.selector)).first();
      await target.scrollIntoViewIfNeeded();
      await target.evaluate((el) => { el.style.outline = '3px solid #d00000'; el.style.outlineOffset = '2px'; });
      const box = await target.boundingBox();
      if (!box) throw new Error(`nothing visible matches ${args.selector}`);
      const pad = 32;
      await page.screenshot({
        path: join(outDir, name),
        clip: { x: Math.max(0, box.x - pad), y: Math.max(0, box.y - pad), width: box.width + pad * 2, height: box.height + pad * 2 },
      });
    } else {
      await page.screenshot({ path: join(outDir, name), fullPage: Boolean(args.full) });
    }
    console.log(join(outDir, name));
  } finally {
    await browser.close();
  }
}

COMMANDS[command]().catch((err) => {
  console.error(`error: ${err.message}`);
  process.exit(1);
});
