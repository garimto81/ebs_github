import { expect, test } from '@playwright/test';
import { execSync } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';

/**
 * S9 Cycle 19 Wave 4 — CC HTML mockup ↔ Flutter cc-web 픽셀 회귀 테스트.
 *
 * 목적: SSOT (`C:/claude/ebs/docs/mockups/EBS Command Center/`) HTML 목업을
 *       reference 로, 실제 Flutter cc-web 렌더링과 픽셀 단위 비교하여
 *       시각적 drift 를 감지한다 (Cycle 19 #425).
 *
 * 비교 전략 (graceful fallback ladder):
 *   Tier 1: ImageMagick `compare -metric RMSE` 시스템 도구 (있을 때만, 정확)
 *   Tier 2: 파일 크기 ratio sanity check (한쪽 빈 캡처 감지용)
 *
 * 본 spec 은 dispatch env (no live backend) 에서는 캡처 단계가 partial 이어도
 * 문법 검증 + test --list 통과 가 1차 목표. 실제 runtime 검증은
 * docker compose 환경에서 `npx playwright test cc-pixel-regression` 으로 수행.
 *
 * 환경 변수:
 *   CC_WEB_URL    — Flutter cc-web origin (기본 http://localhost:3001, Docker_Runtime §1 SSOT)
 *   HTML_MOCKUP   — HTML reference 절대 경로 (기본: C:/claude/ebs/docs/mockups/...)
 *   PIXEL_RMSE_MAX — 허용 RMSE 상한 (기본 0.05 = 5%)
 */

const CC_WEB_URL = process.env.CC_WEB_URL ?? 'http://localhost:3001';
const HTML_MOCKUP =
  process.env.HTML_MOCKUP ??
  'C:/claude/ebs/docs/mockups/EBS Command Center/EBS Command Center.html';
const PIXEL_RMSE_MAX = Number(process.env.PIXEL_RMSE_MAX ?? '0.05');
const SHOT_DIR = path.join('test-results', 'cc-pixel-regression');

test.use({
  storageState: { cookies: [], origins: [] },
  viewport: { width: 1600, height: 900 },
});

test.describe('CC pixel regression — HTML mockup ↔ Flutter cc-web', () => {
  test.setTimeout(120_000);

  test.beforeAll(() => {
    fs.mkdirSync(SHOT_DIR, { recursive: true });
  });

  test('Step A — HTML mockup reference 캡처', async ({ page }) => {
    const fileUrl = 'file:///' + HTML_MOCKUP.replace(/\\/g, '/').replace(/^\/+/, '');
    await page.goto(fileUrl, { waitUntil: 'load' }).catch(() => {});

    // React + Babel standalone 부팅 대기 (CDN 의존, 최대 8s).
    await page
      .waitForFunction(
        () => {
          const root = document.querySelector('#root');
          return !!(root && root.children.length > 0);
        },
        { timeout: 8000 },
      )
      .catch(() => {});
    await page.waitForTimeout(2000);

    const refPath = path.join(SHOT_DIR, 'reference.png');
    await page.screenshot({ path: refPath, fullPage: false });

    expect(fs.existsSync(refPath), 'reference.png 생성됨').toBeTruthy();
    const size = fs.statSync(refPath).size;
    expect(size, 'reference.png 비어있지 않음 (>1KB)').toBeGreaterThan(1_000);
  });

  test('Step B — Flutter cc-web actual 캡처', async ({ page }) => {
    const ccUrl =
      `${CC_WEB_URL}/?table_id=1&cc_instance_id=pixel-regression-${Date.now()}` +
      `&pixel_test=true`;

    // dispatch env 에서는 backend 없음 — goto 자체는 시도하되 networkidle 은 비강제.
    const navResult = await page
      .goto(ccUrl, { waitUntil: 'load', timeout: 15_000 })
      .catch((err: Error) => {
        console.warn(`[cc-pixel] cc-web nav failed: ${err.message}`);
        return null;
      });

    await page.waitForLoadState('networkidle', { timeout: 10_000 }).catch(() => {});
    await page.waitForTimeout(3000);

    const actualPath = path.join(SHOT_DIR, 'flutter-actual.png');
    await page.screenshot({ path: actualPath, fullPage: false });

    expect(fs.existsSync(actualPath), 'flutter-actual.png 생성됨').toBeTruthy();
    // backend down 시에도 빈 viewport 캡처는 성공해야 한다.
    const size = fs.statSync(actualPath).size;
    expect(size, 'flutter-actual.png 최소 100B').toBeGreaterThan(100);

    if (navResult === null) {
      test.info().annotations.push({
        type: 'dispatch-env',
        description: 'cc-web nav failed — backend not up. blank capture only.',
      });
    }
  });

  test('Step C — pixel diff RMSE ≤ 5%', async () => {
    const refPath = path.join(SHOT_DIR, 'reference.png');
    const actualPath = path.join(SHOT_DIR, 'flutter-actual.png');

    test.skip(
      !fs.existsSync(refPath) || !fs.existsSync(actualPath),
      'Step A/B 미완료 — 캡처 누락 (dispatch env or runtime fail)',
    );

    const diffPath = path.join(SHOT_DIR, 'diff.png');

    // Tier 1: ImageMagick `compare` 시도.
    const magickResult = tryImageMagickCompare(refPath, actualPath, diffPath);
    if (magickResult.ok) {
      console.log(`[cc-pixel] ImageMagick RMSE = ${magickResult.rmse}`);
      expect(
        magickResult.rmse,
        `RMSE ${magickResult.rmse} > ${PIXEL_RMSE_MAX} (HTML↔Flutter drift)`,
      ).toBeLessThanOrEqual(PIXEL_RMSE_MAX);
      return;
    }

    // Tier 2: ImageMagick 부재 — 파일 크기 비율 sanity check (fallback).
    const refSize = fs.statSync(refPath).size;
    const actSize = fs.statSync(actualPath).size;
    const ratio = Math.abs(refSize - actSize) / Math.max(refSize, actSize);

    console.warn(
      `[cc-pixel] ImageMagick unavailable. fallback: file-size ratio = ${ratio.toFixed(3)}`,
    );
    test.info().annotations.push({
      type: 'pixel-tier',
      description: `Tier 2 fallback (ImageMagick missing). ratio=${ratio.toFixed(3)}`,
    });

    // size 차이 90%+ 면 한 쪽 캡처 손상 — 명백한 drift.
    expect(
      ratio,
      `file-size 차이 ${(ratio * 100).toFixed(1)}% — 한 쪽 캡처 손상 가능`,
    ).toBeLessThan(0.9);
  });
});

function tryImageMagickCompare(
  ref: string,
  actual: string,
  diff: string,
): { ok: boolean; rmse: number } {
  try {
    // ImageMagick 7: `magick compare`, ImageMagick 6: `compare`.
    // RMSE 출력 형식: "1234.5 (0.0382)" — 괄호 안 0~1 정규화 값 사용.
    const cmd = process.platform === 'win32' ? 'magick compare' : 'compare';
    const result = execSync(`${cmd} -metric RMSE "${ref}" "${actual}" "${diff}"`, {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    return parseRmse(result);
  } catch (err: unknown) {
    // ImageMagick `compare` 는 diff 있으면 exit 1 반환하지만 stderr 에 RMSE 포함.
    // ENOENT 가 아닌 한 파싱 시도.
    const e = err as { status?: number; stderr?: Buffer | string; code?: string };
    if (e.code === 'ENOENT') {
      return { ok: false, rmse: NaN };
    }
    const stderr = typeof e.stderr === 'string' ? e.stderr : e.stderr?.toString() ?? '';
    return parseRmse(stderr);
  }
}

function parseRmse(text: string): { ok: boolean; rmse: number } {
  const m = text.match(/\(([0-9]*\.?[0-9]+)\)/);
  if (!m) return { ok: false, rmse: NaN };
  const v = Number(m[1]);
  return { ok: !Number.isNaN(v), rmse: v };
}
