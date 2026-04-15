const { chromium } = require('playwright');
const path = require('path');
const SCREENSHOT_DIR = path.join(__dirname, 'screenshots');
const VISUAL_DIR = __dirname;

const captures = [
  ['flop-games-visual.html', '#deck-intro', 'cc-00-deck.png'],
  ['flop-games-visual.html', '#private-cards', 'cc-00-private.png'],
  ['flop-games-visual.html', '#shared-cards', 'cc-00-shared.png'],
  ['flop-games-visual.html', '#combination', 'cc-00-combination.png'],
  ['flop-games-visual.html', '#rank-basic', 'cc-07a-basic.png'],
  ['flop-games-visual.html', '#rank-mid', 'cc-07b-mid.png'],
  ['flop-games-visual.html', '#rank-rare', 'cc-07c-rare.png'],
];

(async () => {
  const browser = await chromium.launch();
  const ctx = await browser.newContext({ viewport: { width: 720, height: 1280 }, deviceScaleFactor: 2 });
  for (const [file, sel, out] of captures) {
    const page = await ctx.newPage();
    await page.goto(`file:///${path.join(VISUAL_DIR, file).replace(/\\/g, '/')}`, { waitUntil: 'networkidle' });
    await page.waitForTimeout(500);
    const el = await page.$(sel);
    if (el) { await el.screenshot({ path: path.join(SCREENSHOT_DIR, out), type: 'png' }); console.log(`✅ ${out}`); }
    else console.log(`❌ ${out}`);
    await page.close();
  }
  await browser.close();
})();
