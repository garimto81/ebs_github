// Playwright script to capture individual diagram sections as PNG
// Usage: npx playwright test capture-diagrams.js (or node with playwright)
const { chromium } = require('playwright');
const path = require('path');

const DIAGRAM_NAMES = [
  'diagram-01-phase-roadmap',
  'diagram-02-system-concept',
  'diagram-03-app-ecosystem',
  'diagram-04-broadcast-prep',
  'diagram-05-hand-sequence',
  'diagram-06-broadcast-end',
  'diagram-07-error-recovery',
  'diagram-08-screen-map',
  'diagram-09-game-distribution',
  'diagram-10-antenna-layout',
  'diagram-11-card-registration',
  'diagram-12-security-mode',
  'diagram-13-priority-grid',
  'diagram-14-roadmap-dependency',
  'diagram-15-viewer-journey',
];

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({
    viewport: { width: 1000, height: 800 },
  });

  const htmlPath = path.resolve(__dirname, 'clone-prd-diagrams.html');
  const outputDir = path.resolve(__dirname, '..', 'images');

  await page.goto(`file://${htmlPath}`);
  await page.waitForLoadState('networkidle');

  const sections = await page.locator('.diagram-section').all();
  console.log(`Found ${sections.length} diagram sections`);

  for (let i = 0; i < sections.length; i++) {
    const name = DIAGRAM_NAMES[i] || `diagram-${String(i + 1).padStart(2, '0')}`;
    const outputPath = path.join(outputDir, `${name}.png`);

    await sections[i].screenshot({
      path: outputPath,
      scale: 'device',
    });
    console.log(`Captured: ${name}.png`);
  }

  await browser.close();
  console.log(`\nDone! ${sections.length} diagrams captured to ${outputDir}`);
})();
