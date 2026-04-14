const { chromium } = require('playwright');
const path = require('path');
const SCREENSHOT_DIR = path.join(__dirname, 'screenshots');
const VISUAL_DIR = __dirname;

const captures = [
  // ═══ PL Scenarios ═══
  ['bt-pl-scenarios.html', '#pl-situation-a', 'bt-pl-situation-a.png'],
  ['bt-pl-scenarios.html', '#pl-situation-b', 'bt-pl-situation-b.png'],
  ['bt-pl-scenarios.html', '#pl-step1',       'bt-pl-step1.png'],
  ['bt-pl-scenarios.html', '#pl-step2',       'bt-pl-step2.png'],
  ['bt-pl-scenarios.html', '#pl-situation-c', 'bt-pl-situation-c.png'],
  ['bt-pl-scenarios.html', '#pl-situation-d', 'bt-pl-situation-d.png'],
  ['bt-pl-scenarios.html', '#pl-summary',     'bt-pl-summary.png'],
  // ═══ FL Compare + Cap ═══
  ['bt-fl-compare.html',   '#fl-range-compare', 'bt-fl-range-compare.png'],
  ['bt-fl-compare.html',   '#fl-cap',           'bt-fl-cap.png'],
];

(async () => {
  const browser = await chromium.launch();
  const ctx = await browser.newContext({ viewport: { width: 720, height: 1280 }, deviceScaleFactor: 2 });
  for (const [file, sel, out] of captures) {
    const page = await ctx.newPage();
    await page.goto(`file:///${path.join(VISUAL_DIR, file).replace(/\\/g, '/')}`, { waitUntil: 'networkidle' });
    await page.waitForTimeout(500);
    const el = await page.$(sel);
    if (el) { await el.screenshot({ path: path.join(SCREENSHOT_DIR, out), type: 'png' }); console.log(`OK ${out}`); }
    else console.log(`FAIL ${out} — selector "${sel}" not found`);
    await page.close();
  }
  await browser.close();
  console.log('Done!');
})();
