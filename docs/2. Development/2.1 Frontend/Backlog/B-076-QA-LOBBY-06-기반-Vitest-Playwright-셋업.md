---
id: B-076
title: QA-LOBBY-06 기반 Vitest + Playwright 셋업
status: DONE
source: docs/2. Development/2.1 Frontend/Backlog.md
mirror: none
---

# [B-076] QA-LOBBY-06 기반 Vitest + Playwright 셋업
- **날짜**: 2026-04-10
- **teams**: [team1]
- **설명**: `QA-LOBBY-06-quasar-test-strategy.md` 를 기반으로 Vitest + @vue/test-utils + Playwright + MSW server mode 실제 셋업. `vitest.config.ts`, `playwright.config.ts`, `.github/workflows/frontend-test.yml` 작성.
- **수락 기준**: `pnpm test` 가 샘플 unit test 통과, `pnpm e2e` 가 최소 1개 E2E (로그인 → Series) 통과, GitHub Actions 에서 lint+typecheck+unit+e2e 모두 녹색.
- **관련 PRD**: `qa/lobby/QA-LOBBY-06-quasar-test-strategy.md`
- **완료 (2026-04-16)**: Flutter 전환으로 Vitest/Playwright→flutter_test+mocktail 체계로 대체 완료. test/widget_test.dart 통과. QA-LOBBY-06은 Flutter 테스트 전략으로 재정의됨.
