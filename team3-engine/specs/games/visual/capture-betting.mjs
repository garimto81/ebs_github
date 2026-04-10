import { chromium } from 'playwright';
import { fileURLToPath } from 'url';
import path from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const htmlPath = path.join(__dirname, 'st-betting-rules.html');
const outDir = path.join(__dirname, 'screenshots');

const scenes = [
  { id: 's-ante', file: 'st-br-ante.png' },
  { id: 's-bringin', file: 'st-br-bringin.png' },
  { id: 's-complete', file: 'st-br-complete.png' },
  { id: 's-escalation', file: 'st-br-escalation.png' },
  { id: 's-small-big', file: 'st-br-small-big.png' },
  { id: 's-open-pair', file: 'st-br-open-pair.png' },
  { id: 's-cap', file: 'st-br-cap.png' },
  { id: 's-action-order', file: 'st-br-action-order.png' },
];

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 660, height: 800 } });
await page.goto(`file:///${htmlPath.replace(/\\/g, '/')}`);

for (const { id, file } of scenes) {
  const el = await page.locator(`#${id}`);
  await el.screenshot({ path: path.join(outDir, file), type: 'png' });
  console.log(`Captured: ${file}`);
}

await browser.close();
console.log('Done.');
