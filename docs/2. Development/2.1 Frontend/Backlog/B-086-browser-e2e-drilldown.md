---
id: B-086
title: "Browser E2E 러너에 drill-down + 탭 순회 시나리오 추가"
status: DONE
completed: 2026-04-17
branch: work/team1/20260417-api-alignment
source: docs/2. Development/2.1 Frontend/Backlog.md
---

# B-086 — tools/run_browser_e2e.py drill-down 확장

## 배경

기존 러너는 `/lobby` 진입까지만 검증. Event 클릭 → Tables 자동 로드나 Settings/Staff/GFX/Reports 탭 전환 시 발생하는 런타임 에러/API 404는 감지 못 함.

## 완료 내역

- Event 행 클릭 시 `/api/v1/tables` 응답 포착 (5초 타임아웃)
- Settings/Staff/GFX/Reports 아이콘 순차 클릭 (좌표 기반)
- 각 단계 스크린샷: `04c-drill-down`, `06-settings`, `07-staff`, `08-gfx`, `09-reports`
- API 4xx/5xx + Console error + 빨간 에러 박스 픽셀 감지 유지

## 제약

- Flutter CanvasKit 렌더러로 좌표 기반 클릭 (HTML selector 불가)
- 좌표는 viewport 1280×720 기준. Responsive breakpoint 변경 시 재조정 필요
- 아이콘 위치는 현재 Lobby 레이아웃 하드코딩

## 후속

- B-F007: Flutter Semantics 활성화 후 role selector 기반으로 전환 (안정성)
