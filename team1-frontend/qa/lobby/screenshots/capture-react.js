const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });
  const dir = 'C:/claude/ebs/docs/qa/lobby/screenshots';
  const BASE = 'http://localhost:3333';

  // 1. Login page
  await page.goto(BASE + '/login', { waitUntil: 'networkidle', timeout: 15000 });
  await page.waitForTimeout(1500);
  await page.screenshot({ path: `${dir}/react-00-login.png`, fullPage: true });
  console.log('Captured: react-00-login.png');

  // 2. Try login with wrong credentials to capture error
  const emailInput = page.locator('input[type="email"]');
  const pwdInput = page.locator('input[type="password"]');
  if (await emailInput.count() > 0) {
    await emailInput.fill('admin@ebs.local');
    await pwdInput.fill('password');
    await page.locator('button[type="submit"]').click();
    await page.waitForTimeout(3000);
    await page.screenshot({ path: `${dir}/react-00-login-error.png`, fullPage: true });
    console.log('Captured: react-00-login-error.png');
  }

  // 3. Navigate to /series (will redirect to /login if not authenticated)
  await page.goto(BASE + '/series', { waitUntil: 'networkidle', timeout: 15000 });
  await page.waitForTimeout(2000);
  await page.screenshot({ path: `${dir}/react-01-series.png`, fullPage: true });
  console.log('Captured: react-01-series.png');

  // 4. Check current URL to see if redirected
  const currentUrl = page.url();
  console.log('Current URL after /series:', currentUrl);

  await browser.close();
  console.log('Done.');
})();
