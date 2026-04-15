const { chromium } = require('playwright');
const path = require('path');
const SCREENSHOT_DIR = path.join(__dirname, 'screenshots');
const VISUAL_DIR = __dirname;

const captures = [
  ['core-concepts-flop.html', '#cc-holdem',     'cc-core-01-holdem.png'],
  ['core-concepts-flop.html', '#cc-shortdeck',  'cc-core-02-shortdeck.png'],
  ['core-concepts-flop.html', '#cc-triton',     'cc-core-03-triton.png'],
  ['core-concepts-flop.html', '#cc-pineapple',  'cc-core-04-pineapple.png'],
  ['core-concepts-flop.html', '#cc-omaha',      'cc-core-05-omaha.png'],
  ['core-concepts-flop.html', '#cc-omaha-hilo', 'cc-core-06-omaha-hilo.png'],
  ['core-concepts-flop.html', '#cc-fivesix',    'cc-core-07-fivesix.png'],
  ['core-concepts-flop.html', '#cc-courchevel', 'cc-core-09-courchevel.png'],
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
    else console.log(`❌ ${out} — selector "${sel}" not found`);
    await page.close();
  }
  await browser.close();
  console.log('Done!');
})();
