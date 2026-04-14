const { chromium } = require('playwright');
const path = require('path');
const SCREENSHOT_DIR = path.join(__dirname, 'screenshots');
const VISUAL_DIR = __dirname;

const captures = [
  ['betting-system-visual.html', '#chips',          'bt-00-chips.png'],
  ['betting-system-visual.html', '#actions',        'bt-01-actions.png'],
  ['betting-system-visual.html', '#sidepot',        'bt-02-sidepot.png'],
  ['betting-system-visual.html', '#bet-structure',  'bt-03-structure.png'],
  ['betting-system-visual.html', '#blind-position', 'bt-04-blind-position.png'],
  ['betting-system-visual.html', '#ante-types',     'bt-05-ante-types.png'],
  ['betting-system-visual.html', '#straddle',       'bt-06-straddle.png'],
  ['betting-system-visual.html', '#bombpot',        'bt-07-bombpot.png'],
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
