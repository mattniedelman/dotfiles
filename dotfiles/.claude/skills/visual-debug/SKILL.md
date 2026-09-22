---
name: visual-debug
description: Use when a web page or SVG is visually mis-rendering -- wrong layout, missing elements, clipped content, invisible shapes, bad positioning -- and you need to see what is actually rendering before reading source code
---

# Visual Debug

**Screenshot first. Source second.**

Reading source before seeing the rendering is the most common visual debugging mistake.
The DOM you read in source is the intended DOM. The rendered output is the actual DOM.
These diverge in exactly the ways that cause visual bugs.

## Step 1 -- Take a screenshot

Use Playwright to capture what is actually rendering:

```bash
npx playwright screenshot --full-page http://localhost:PORT /tmp/debug-screenshot.png
```

Or if the project has a Playwright setup:

```bash
npx playwright test --headed --screenshot=on
```

For a specific element (e.g., an SVG chart):

```bash
node -e "
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto('http://localhost:PORT');
  await page.locator('svg').screenshot({ path: '/tmp/debug-svg.png' });
  await browser.close();
})();
"
```

Then **read the image** with the Read tool. Claude can see it.

## Step 2 -- Describe what you see

Before touching source, state specifically:

- Are elements present but in the wrong position?
- Are elements completely absent?
- Are elements present but invisible (blank area where content should be)?
- Is content clipped at an edge?
- Are dimensions wrong (too tall, too wide, zero height)?

This narrows the failure class before a single line of source is read.

## Step 3 -- Match symptom to root cause

### SVG-specific symptoms

| Symptom | First suspect |
|---|---|
| Bars/shapes present but all at top | y-axis not inverted (SVG y increases downward; bar height = `chartH - value`, not `value`) |
| All shapes stacked at x=0 | x scale not applied, or band/ordinal scale misconfigured |
| Content absent entirely | Data array empty at render time; check data loading, not the rendering code |
| Shapes present but invisible | `fill` matches background, or `opacity: 0`, or `display: none` on group |
| Content clipped at boundary | `viewBox` too small, or `overflow: hidden` on SVG or container element |
| Shapes have zero height/width | Scale domain or range produces zero; or `chartHeight`/`chartWidth` is `0` on first render |
| Everything offset by a fixed amount | Margin applied twice -- once in scale range, once in a `transform` on the group |
| Correct structure but wrong size | SVG `width`/`height` attributes missing; SVG sizing from CSS only, but `viewBox` absent |

### CSS layout symptoms

| Symptom | First suspect |
|---|---|
| Element absent from view | `visibility: hidden`, `opacity: 0`, or off-screen `position: absolute` |
| Container present but empty-looking | `overflow: hidden` cropping children |
| Element in wrong place | Stacking context issue; `z-index` or `position` on a parent |
| Responsive breakage | `width: 100%` on SVG without `viewBox` -- SVG scales but content doesn't |

## Step 4 -- Inspect the live DOM

After screenshot confirms the symptom class, inspect the actual rendered attributes:

```bash
node -e "
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto('http://localhost:PORT');
  const attrs = await page.evaluate(() => {
    const el = document.querySelector('svg rect:first-child');
    if (!el) return 'no rect found';
    return {
      x: el.getAttribute('x'),
      y: el.getAttribute('y'),
      width: el.getAttribute('width'),
      height: el.getAttribute('height'),
      fill: el.getAttribute('fill'),
      computed: getComputedStyle(el).display
    };
  });
  console.log(JSON.stringify(attrs, null, 2));
  await browser.close();
})();
"
```

Look for: `NaN`, negative values, `0` dimensions, `fill="none"`, unexpected `display: none`.

Also check the browser console for errors:

```bash
node -e "
const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  const errors = [];
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  await page.goto('http://localhost:PORT');
  await page.waitForTimeout(1000);
  console.log(errors.join('\n') || 'no console errors');
  await browser.close();
})();
"
```

## Step 5 -- Read source with the diagnosis in hand

Only now open the source file, and read it looking for the specific cause the DOM inspection pointed to -- not the whole file.

If DOM inspection showed `height="0"` on rects: read only the height/scale calculation.
If DOM inspection showed all rects at `x="0"`: read only the x scale setup.
If the element is absent entirely: read the data loading and conditional rendering, not the SVG drawing code.

## Common mistakes to avoid

**Reading source before screenshotting** -- you will form a hypothesis from the code and look for evidence of it. The screenshot removes this bias; it tells you what actually happened.

**Restarting the dev server as a first move** -- a running server is giving you real evidence. Don't discard it.

**Adding console.log before looking at the DOM** -- the DOM already has the rendered attribute values. Look there first; it costs nothing and requires no code change.

**Debugging SVG coordinate math mentally** -- SVG coordinate systems are counterintuitive. Don't reason about them; inspect the actual computed values in the live DOM.

## If Playwright is not available

Take a screenshot manually (browser DevTools > screenshot, or OS screenshot tool) and pass the image path to the Read tool. The analysis steps are the same.

If a screenshot is not possible at all, use DOM inspection via curl or a headless fetch to get the rendered HTML, then read the specific attribute values rather than reasoning from source.
