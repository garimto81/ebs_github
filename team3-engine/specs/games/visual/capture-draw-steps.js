const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 800, height: 2000 } });

  const htmlPath = path.resolve(__dirname, 'mockups/draw-exchange-concept.html');
  await page.goto(`file:///${htmlPath.replace(/\\/g, '/')}`);
  await page.waitForTimeout(500);

  const outDir = path.resolve(__dirname, 'screenshots');

  // Step 1: 카드 받기 (title + facedown + revealed cards + eval)
  // Find first .step element
  const steps = await page.$$('.step');
  const dividers = await page.$$('hr.step-divider');

  // Step 1: from start of first .step to first hr
  const step1Top = await steps[0].evaluate(el => el.getBoundingClientRect().top);
  const div1Bottom = await dividers[0].evaluate(el => el.getBoundingClientRect().bottom);
  await page.screenshot({
    path: path.join(outDir, 'dr-draw-step1-receive.png'),
    clip: { x: 0, y: step1Top - 10, width: 800, height: div1Bottom - step1Top + 20 }
  });
  console.log('Captured: dr-draw-step1-receive.png');

  // Step 2a: 버리기 (second .step to second hr)
  const step2aTop = await steps[1].evaluate(el => el.getBoundingClientRect().top);
  const div2Bottom = await dividers[1].evaluate(el => el.getBoundingClientRect().bottom);
  await page.screenshot({
    path: path.join(outDir, 'dr-draw-step2a-discard.png'),
    clip: { x: 0, y: step2aTop - 10, width: 800, height: div2Bottom - step2aTop + 20 }
  });
  console.log('Captured: dr-draw-step2a-discard.png');

  // Step 2b: 새 카드 받기 (third .step to third hr)
  const step2bTop = await steps[2].evaluate(el => el.getBoundingClientRect().top);
  const div3Bottom = await dividers[2].evaluate(el => el.getBoundingClientRect().bottom);
  await page.screenshot({
    path: path.join(outDir, 'dr-draw-step2b-newcards.png'),
    clip: { x: 0, y: step2bTop - 10, width: 800, height: div3Bottom - step2bTop + 20 }
  });
  console.log('Captured: dr-draw-step2b-newcards.png');

  // Step 3: 결과 비교 (fourth .step)
  const step3Top = await steps[3].evaluate(el => el.getBoundingClientRect().top);
  const step3Bottom = await steps[3].evaluate(el => el.getBoundingClientRect().bottom);
  await page.screenshot({
    path: path.join(outDir, 'dr-draw-step3-result.png'),
    clip: { x: 0, y: step3Top - 10, width: 800, height: step3Bottom - step3Top + 20 }
  });
  console.log('Captured: dr-draw-step3-result.png');

  await browser.close();
  console.log('Done! 4 screenshots captured.');
})();
