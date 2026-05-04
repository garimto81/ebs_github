// Render CC + Settings mockups → PNG
// Usage: node render-mockups.js (playwright installed globally)
const { chromium } = require('C:/Users/AidenKim/AppData/Roaming/npm/node_modules/playwright');
const path = require('path');

const DIR = __dirname;
const OUT = path.join(DIR, '..', 'images', 'prd');

const jobs = [
  { html: 'cc-mockup.html', png: 'app-command-center.png' },
  { html: 'settings-mockup.html', png: 'app-settings-main.png' },
];

(async () => {
  const browser = await chromium.launch();
  const context = await browser.newContext({ viewport: { width: 1280, height: 720 }, deviceScaleFactor: 2 });
  for (const j of jobs) {
    const page = await context.newPage();
    const url = 'file:///' + path.join(DIR, j.html).replace(/\\/g, '/');
    await page.goto(url, { waitUntil: 'networkidle' });
    await page.waitForTimeout(150);
    const outPath = path.join(OUT, j.png);
    await page.screenshot({ path: outPath, clip: { x: 0, y: 0, width: 1280, height: 720 } });
    console.log('OK:', j.png, '→', outPath);
    await page.close();
  }
  await browser.close();
})().catch(e => { console.error(e); process.exit(1); });
