import { chromium } from 'playwright';
import { fileURLToPath } from 'url';
import path from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const htmlPath = path.join(__dirname, 'st-step4-action-flow.html');
const outDir = path.join(__dirname, 'screenshots');

const scenes = [
  { id: 's4-1', file: 'st-s4-4th-street.png' },
  { id: 's4-2', file: 'st-s4-5th-street.png' },
  { id: 's4-3', file: 'st-s4-6th-street.png' },
  { id: 's4-4', file: 'st-s4-7th-street.png' },
];

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 680, height: 900 } });
await page.goto(`file:///${htmlPath.replace(/\\/g, '/')}`);

for (const { id, file } of scenes) {
  const el = await page.locator(`#${id}`);
  await el.screenshot({ path: path.join(outDir, file), type: 'png' });
  console.log(`Captured: ${file}`);
}

await browser.close();
console.log('Done.');
