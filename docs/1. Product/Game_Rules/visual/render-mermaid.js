const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const SCREENSHOT_DIR = path.join(__dirname, 'screenshots');
const diagrams = JSON.parse(fs.readFileSync(path.join(__dirname, 'mermaid_diagrams.json'), 'utf-8'));

(async () => {
  const browser = await chromium.launch();
  const ctx = await browser.newContext({ viewport: { width: 800, height: 600 }, deviceScaleFactor: 2 });

  for (const d of diagrams) {
    const page = await ctx.newPage();
    const html = `<!DOCTYPE html>
<html><head>
<script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
<style>
  body { background: #fff; margin: 0; padding: 20px; font-family: 'Segoe UI', sans-serif; }
  .mermaid { display: inline-block; }
</style>
</head><body>
<div class="mermaid" id="diagram">
${d.code}
</div>
<script>
  mermaid.initialize({ startOnLoad: true, theme: 'default', flowchart: { useMaxWidth: false } });
</script>
</body></html>`;

    await page.setContent(html, { waitUntil: 'networkidle' });
    await page.waitForTimeout(1500);

    const el = await page.$('#diagram svg') || await page.$('#diagram');
    const outFile = path.join(SCREENSHOT_DIR, `mermaid-${String(d.id).padStart(2, '0')}.png`);

    if (el) {
      await el.screenshot({ path: outFile, type: 'png' });
      console.log(`✅ mermaid-${String(d.id).padStart(2, '0')}.png`);
    } else {
      console.log(`❌ mermaid-${String(d.id).padStart(2, '0')}.png (no element)`);
    }
    await page.close();
  }

  await browser.close();
  console.log('Done!');
})();
