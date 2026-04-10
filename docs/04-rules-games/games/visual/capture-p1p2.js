const { chromium } = require('playwright');
const path = require('path');
const SCREENSHOT_DIR = path.join(__dirname, 'screenshots');
const VISUAL_DIR = __dirname;

const captures = [
  // P2: 52장 전체 그리드 (deck-intro 교체)
  ['flop-games-visual.html', '#deck-intro', 'cc-00-deck.png'],
  // P1: 5장 선택 과정
  ['flop-games-visual.html', '#five-card-selection', 'cc-00-five-selection.png'],
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
