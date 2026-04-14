// Playwright 기반 HTML → PNG 렌더러
// 사용: node render.js
// 출력: ../prd-ebs-{software|hardware}-architecture.png

const { chromium } = require('playwright');
const path = require('path');

const TARGETS = [
  {
    html: 'prd-ebs-software-architecture.html',
    png: '../prd-ebs-software-architecture.png',
    viewport: { width: 1500, height: 1200 },
  },
  {
    html: 'prd-ebs-hardware-architecture.html',
    png: '../prd-ebs-hardware-architecture.png',
    viewport: { width: 1400, height: 1500 },
  },
  {
    // SW only (단독 렌더)
    html: 'prd-ebs-software-architecture.html',
    png: '../prd-ebs-software-architecture-only.png',
    viewport: { width: 1500, height: 1200 },
    skip: true, // 기본 비활성, --sw-only 로 활성
  },
];

(async () => {
  const browser = await chromium.launch();
  for (const t of TARGETS.filter(t => !t.skip)) {
    const context = await browser.newContext({
      viewport: t.viewport,
      deviceScaleFactor: 2, // retina quality
    });
    const page = await context.newPage();
    const url = 'file:///' + path.resolve(__dirname, t.html).replace(/\\/g, '/');
    await page.goto(url, { waitUntil: 'networkidle' });
    // Google Fonts 로딩 대기
    await page.waitForTimeout(1200);
    const stage = await page.$('.stage');
    const out = path.resolve(__dirname, t.png);
    await stage.screenshot({ path: out, omitBackground: false });
    console.log('✓ rendered:', t.png);
    await context.close();
  }
  await browser.close();
})();
