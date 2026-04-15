const { chromium } = require('playwright');
const path = require('path');

const SCREENSHOT_DIR = path.join(__dirname, 'screenshots');
const VISUAL_DIR = __dirname;

// 실패한 3개 재캡처 (정확한 selector 사용)
const captures = [
  // cc-01: 첫 번째 .sec 전체 (카드 배분 - 포커테이블 포함)
  ['flop-games-visual.html', 'body > div:nth-child(2)', 'cc-01-holecards.png'],
  // cc-03: .stgs 내부 두 번째 div (Turn stage)
  ['flop-games-visual.html', '.stgs > div:nth-child(2)', 'cc-03-turn.png'],
  // cc-04: .stgs 내부 세 번째 div (River stage)
  ['flop-games-visual.html', '.stgs > div:nth-child(3)', 'cc-04-river.png'],
];

(async () => {
  const browser = await chromium.launch();
  const context = await browser.newContext({
    viewport: { width: 720, height: 1280 },
    deviceScaleFactor: 2,
  });

  for (const [file, selector, output] of captures) {
    const page = await context.newPage();
    const filePath = `file:///${path.join(VISUAL_DIR, file).replace(/\\/g, '/')}`;
    await page.goto(filePath, { waitUntil: 'networkidle' });
    await page.waitForTimeout(500);

    const element = await page.$(selector);
    if (element) {
      await element.screenshot({
        path: path.join(SCREENSHOT_DIR, output),
        type: 'png',
      });
      console.log(`✅ ${output}`);
    } else {
      console.log(`❌ ${output} — selector "${selector}" not found`);
      // 최종 폴백: 전체 .sec의 index로 시도
      const allSec = await page.$$('.sec');
      if (output.includes('cc-01') && allSec.length > 0) {
        await allSec[0].screenshot({ path: path.join(SCREENSHOT_DIR, output), type: 'png' });
        console.log(`✅ ${output} (sec[0] fallback)`);
      }
    }
    await page.close();
  }

  await browser.close();
})();
