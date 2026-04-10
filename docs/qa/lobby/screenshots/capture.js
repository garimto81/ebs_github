const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });
  const dir = 'C:/claude/ebs/docs/qa/lobby/screenshots';

  // 00 - Login screen
  await page.goto('http://localhost:3333', { waitUntil: 'networkidle', timeout: 10000 });
  await page.waitForTimeout(2000);

  // Click login
  const loginBtn = page.locator('text=로그인');
  if (await loginBtn.isVisible()) {
    await loginBtn.click();
    await page.waitForTimeout(3000);
  }
  await page.screenshot({ path: `${dir}/01-after-login.png`, fullPage: true });
  console.log('01-after-login captured');

  await browser.close();
  console.log('Done');
})();
