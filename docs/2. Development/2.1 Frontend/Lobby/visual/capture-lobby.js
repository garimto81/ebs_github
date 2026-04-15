const { chromium } = require('playwright');
const path = require('path');

const SCREENSHOT_DIR = path.join(__dirname, 'screenshots');
const HTML_FILE = path.join(__dirname, 'ebs-lobby-mockup.html');

const captures = [
  ['#screen-0', 'ebs-lobby-00-login.png'],
  ['#screen-1', 'ebs-lobby-01-series.png'],
  ['#screen-2', 'ebs-lobby-02-events.png'],
  ['#screen-3', 'ebs-lobby-03-flights.png'],
  ['#screen-4', 'ebs-lobby-04-tables.png'],
  ['#screen-5', 'ebs-lobby-05-players.png'],
];

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  await page.goto(`file://${HTML_FILE}`);
  await page.waitForTimeout(500);

  for (const [selector, filename] of captures) {
    const el = await page.$(selector);
    if (el) {
      await el.screenshot({ path: path.join(SCREENSHOT_DIR, filename) });
      console.log(`OK  ${filename}`);
    } else {
      console.log(`FAIL  ${filename} (selector not found: ${selector})`);
    }
  }

  await browser.close();
  console.log(`\nDone. ${captures.length} screenshots saved to ${SCREENSHOT_DIR}`);
})();
