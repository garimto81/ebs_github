const { chromium } = require('playwright');
const path = require('path');
const SCREENSHOT_DIR = path.join(__dirname, 'screenshots');
const VISUAL_DIR = __dirname;

// ID 기반 재캡처 — 잘못된 8장 수정
const captures = [
  // Flop Games — Flop stage
  ['flop-games-visual.html', '#cc-flop-stage', 'cc-02-flop.png'],

  // Draw — 6장 재캡처
  ['draw-visual.html', '#dr-exchange1', 'dr-02-exchange1.png'],
  ['draw-visual.html', '#dr-standpat', 'dr-04-final.png'],
  ['draw-visual.html', '#dr-straight-penalty', 'dr-06-straight-penalty.png'],
  ['draw-visual.html', '#dr-27-vs-a5', 'dr-07-27-vs-a5.png'],
  ['draw-visual.html', '#dr-badugi', 'dr-08-badugi.png'],

  // Stud — 2장 재캡처
  ['seven-card-visual.html', '#st-showdown', 'st-06-showdown.png'],
  ['seven-card-visual.html', '#st-razz', 'st-07-razz.png'],
];

(async () => {
  const browser = await chromium.launch();
  const ctx = await browser.newContext({
    viewport: { width: 720, height: 1280 },
    deviceScaleFactor: 2,
  });

  let ok = 0, fail = 0;
  for (const [file, sel, out] of captures) {
    const page = await ctx.newPage();
    const url = `file:///${path.join(VISUAL_DIR, file).replace(/\\/g, '/')}`;
    await page.goto(url, { waitUntil: 'networkidle' });
    await page.waitForTimeout(500);

    const el = await page.$(sel);
    if (el) {
      await el.screenshot({ path: path.join(SCREENSHOT_DIR, out), type: 'png' });
      console.log(`✅ ${out}`);
      ok++;
    } else {
      console.log(`❌ ${out} — selector "${sel}" not found`);
      fail++;
    }
    await page.close();
  }

  await browser.close();
  console.log(`\nDone: ${ok} ok, ${fail} failed`);
})();
