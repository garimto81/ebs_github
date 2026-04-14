import { chromium } from 'playwright';
import { fileURLToPath } from 'url';
import path from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const htmlPath = path.join(__dirname, 'st-card-scenes.html');
const outDir = path.join(__dirname, 'screenshots');

const scenes = [
  { id: 's01', file: 'st-v01-seven-card-layout.png' },
  { id: 's02', file: 'st-v02-quiz-intro.png' },
  { id: 's03', file: 'st-v03-hand-basic.png' },
  { id: 's04', file: 'st-v04-hand-mid.png' },
  { id: 's05', file: 'st-v05-hand-rare.png' },
  { id: 's06', file: 'st-v06-low-qualify.png' },
  { id: 's07', file: 'st-v07-hilo-example.png' },
  { id: 's08', file: 'st-v08-razz-compare.png' },
  { id: 's09', file: 'st-v09-bringin-compare.png' },
  { id: 's10', file: 'st-v10-razz-example.png' },
  { id: 's11', file: 'st-v11-showdown.png' },
  { id: 's12', file: 'st-v12-hilo-pot-split.png' },
  { id: 's13', file: 'st-v13-hilo-dual-select.png' },
];

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 700, height: 800 } });
await page.goto(`file:///${htmlPath.replace(/\\/g, '/')}`);

for (const { id, file } of scenes) {
  const el = await page.locator(`#${id}`);
  await el.screenshot({ path: path.join(outDir, file), type: 'png' });
  console.log(`Captured: ${file}`);
}

await browser.close();
console.log('Done — all scenes captured.');
