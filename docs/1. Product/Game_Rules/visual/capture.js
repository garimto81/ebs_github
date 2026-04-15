// Playwright 섹션별 캡처 스크립트
// Usage: npx playwright test capture.js (or node with playwright)
const { chromium } = require('playwright');
const path = require('path');

const SCREENSHOT_DIR = path.join(__dirname, 'screenshots');
const VISUAL_DIR = __dirname;

// 캡처 정의: [filename, selector, outputName]
const captures = [
  // ═══ Flop Games ═══
  // cc-01: 홀카드 배분 (포커 테이블)
  ['flop-games-visual.html', '.sec:nth-of-type(1) .pt', 'cc-01-holecards.png'],
  // cc-02: Flop 단계
  ['flop-games-visual.html', '.sec:nth-of-type(2) .pt', 'cc-02-flop.png'],
  // cc-03: Turn 단계 (stage 2)
  ['flop-games-visual.html', '.sec:nth-of-type(2) .stgs > div:nth-child(2)', 'cc-03-turn.png'],
  // cc-04: River 단계 (stage 3)
  ['flop-games-visual.html', '.sec:nth-of-type(2) .stgs > div:nth-child(3)', 'cc-04-river.png'],
  // cc-05+06: 승부 비교 (showdown)
  ['flop-games-visual.html', '.sec:nth-of-type(3)', 'cc-05-showdown.png'],
  // cc-07: 핸드 랭킹 테이블
  ['flop-games-visual.html', '.sec:nth-of-type(4)', 'cc-07-rankings.png'],
  // cc-10+11: Omaha 2+3 규칙
  ['flop-games-visual.html', '.sec:nth-of-type(5)', 'cc-10-omaha-rule.png'],
  // cc-12: Hi-Lo 팟 분배
  ['flop-games-visual.html', '.sec:nth-of-type(6)', 'cc-12-hilo-pot.png'],
  // cc-08: Short Deck 순위 비교
  ['flop-games-visual.html', '.sec:nth-of-type(7)', 'cc-08-shortdeck.png'],
  // cc-09: Pineapple
  ['flop-games-visual.html', '.sec:nth-of-type(8)', 'cc-09-pineapple.png'],

  // ═══ Draw ═══
  // dr-01: 초기 5장 (버릴 카드 표시)
  ['draw-visual.html', '.section:nth-of-type(1)', 'dr-01-initial.png'],
  // dr-02: 1차 교환 후
  ['draw-visual.html', '.section:nth-of-type(2)', 'dr-02-exchange1.png'],
  // dr-03: 2차 교환 후
  ['draw-visual.html', '.section:nth-of-type(3)', 'dr-03-exchange2.png'],
  // dr-04: 최종 패 (Stand Pat)
  ['draw-visual.html', '.section:nth-of-type(4)', 'dr-04-final.png'],
  // dr-05: Lowball 랭킹 테이블
  ['draw-visual.html', '.section:nth-of-type(5)', 'dr-05-lowball-ranks.png'],
  // dr-06: 2-3-4-5-6 vs 2-3-4-5-7
  ['draw-visual.html', '.comparison:nth-of-type(1)', 'dr-06-straight-penalty.png'],
  // dr-07: 2-7 vs A-5
  ['draw-visual.html', '.comparison:nth-of-type(2)', 'dr-07-27-vs-a5.png'],
  // dr-08+09+10: Badugi
  ['draw-visual.html', '.section:nth-of-type(6)', 'dr-08-badugi.png'],
  // dr-11: 승부 예시
  ['draw-visual.html', '.comparison:nth-of-type(3)', 'dr-11-showdown.png'],

  // ═══ Draw v3.0 추가 (14종) ═══
  // dr-12: Lowball 퀴즈 (Player A vs B)
  ['draw-visual.html', '#dr-lowball-quiz', 'dr-12-lowball-quiz.png'],
  // dr-13: Lowball 반전 비교표
  ['draw-visual.html', '#dr-lowball-reverse', 'dr-13-lowball-reverse.png'],
  // dr-14: 카드 5장 평가
  ['draw-visual.html', '#dr-card-evaluate', 'dr-14-card-evaluate.png'],
  // dr-15: 교환 진행 총괄
  ['draw-visual.html', '#dr-exchange-progress', 'dr-15-exchange-progress.png'],
  // dr-16: A 함정
  ['draw-visual.html', '#dr-trap-ace', 'dr-16-trap-ace.png'],
  // dr-20: Five Card Draw 카드 평가
  ['draw-visual.html', '#dr-fcd-evaluate', 'dr-20-fcd-evaluate.png'],
  // dr-21: Five Card Draw 교환
  ['draw-visual.html', '#dr-fcd-exchange', 'dr-21-fcd-exchange.png'],
  // dr-22: Five Card Draw 승부
  ['draw-visual.html', '#dr-fcd-showdown', 'dr-22-fcd-showdown.png'],
  // dr-30: Single Draw 비교
  ['draw-visual.html', '#dr-single-draw', 'dr-30-single-draw.png'],
  // dr-40: A-5 에이스 규칙 비교
  ['draw-visual.html', '#dr-a5-ace-rule', 'dr-40-a5-ace-rule.png'],
  // dr-50: Badugi 실전 예시
  ['draw-visual.html', '#dr-badugi-example', 'dr-50-badugi-example.png'],
  // dr-60: Badeucy 팟 분할
  ['draw-visual.html', '#dr-badeucy-split', 'dr-60-badeucy-split.png'],
  // dr-61: Badeucy 딜레마
  ['draw-visual.html', '#dr-badeucy-dilemma', 'dr-61-badeucy-dilemma.png'],
  // dr-70: Badacey 비교
  ['draw-visual.html', '#dr-badacey-compare', 'dr-70-badacey-compare.png'],

  // ═══ Seven Card Games ═══
  // st-01: 3rd Street
  ['seven-card-visual.html', '.poker-table:nth-of-type(1)', 'st-01-3rd-street.png'],
  // st-02: 4th Street
  ['seven-card-visual.html', '.poker-table:nth-of-type(2)', 'st-02-4th-street.png'],
  // st-03: 5th Street
  ['seven-card-visual.html', '.poker-table:nth-of-type(3)', 'st-03-5th-street.png'],
  // st-04: 6th Street
  ['seven-card-visual.html', '.poker-table:nth-of-type(4)', 'st-04-6th-street.png'],
  // st-05: 7th Street
  ['seven-card-visual.html', '.poker-table:nth-of-type(5)', 'st-05-7th-street.png'],
  // st-06: 쇼다운
  ['seven-card-visual.html', '.section:nth-of-type(1)', 'st-06-showdown.png'],
  // st-07: Razz 비교
  ['seven-card-visual.html', '.section:nth-of-type(2)', 'st-07-razz.png'],
  // st-08: Hi-Lo Low 자격
  ['seven-card-visual.html', '.section:nth-of-type(3)', 'st-08-hilo-low.png'],
];

(async () => {
  const browser = await chromium.launch();
  const context = await browser.newContext({
    viewport: { width: 720, height: 1280 },
    deviceScaleFactor: 2,
  });

  let success = 0;
  let failed = 0;

  for (const [file, selector, output] of captures) {
    const page = await context.newPage();
    const filePath = `file:///${path.join(VISUAL_DIR, file).replace(/\\/g, '/')}`;

    try {
      await page.goto(filePath, { waitUntil: 'networkidle' });
      await page.waitForTimeout(500);

      const element = await page.$(selector);
      if (element) {
        await element.screenshot({
          path: path.join(SCREENSHOT_DIR, output),
          type: 'png',
        });
        console.log(`✅ ${output}`);
        success++;
      } else {
        // 폴백: selector 실패 시 전체 페이지의 일부 캡처
        console.log(`⚠️  ${output} — selector "${selector}" not found, trying fallback...`);
        // 폴백으로 body > :nth-child 시도
        const fallback = selector.replace(/\.\w+:nth-of-type/, 'body > *:nth-of-type');
        const fb = await page.$(fallback);
        if (fb) {
          await fb.screenshot({ path: path.join(SCREENSHOT_DIR, output), type: 'png' });
          console.log(`✅ ${output} (fallback)`);
          success++;
        } else {
          console.log(`❌ ${output} — no element found`);
          failed++;
        }
      }
    } catch (err) {
      console.log(`❌ ${output} — ${err.message}`);
      failed++;
    }
    await page.close();
  }

  await browser.close();
  console.log(`\nDone: ${success} captured, ${failed} failed out of ${captures.length}`);
})();
