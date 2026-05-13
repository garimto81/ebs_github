---
id: B-092
title: "Lobby visual/screenshots — 신 디자인 7장 cascade + 본문 문서 정합 갱신"
backlog-status: done
created: 2026-05-05
updated: 2026-05-05
completed: 2026-05-05
owner: conductor
source: "사용자 directive (2026-05-05): zip 검토 → 7장 캡쳐 → 교체 → 모든 로비 문서 정합 cascade"
related-prd:
  - docs/1. Product/Lobby.md (v1.3.0 Changelog 2026-05-05)
  - docs/2. Development/2.1 Frontend/Lobby/Overview.md (§화면 6/7 신설)
  - docs/2. Development/2.1 Frontend/Lobby/UI.md (mockup HTML 5건 redirect)
  - docs/2. Development/2.1 Frontend/Lobby/Hand_History.md (PNG 인라인)
  - docs/2. Development/2.1 Frontend/Lobby/Table.md (line 303 캡션 보강)
  - docs/2. Development/2.1 Frontend/Lobby/References/EBS_Lobby_Design/README.md (zip sync changelog)
depends-on: B-091
blocks: []
mirror: none
close-date: 2026-05-13
---

# B-092 — Lobby visual/screenshots 신 디자인 7장 cascade

## 배경

2026-05-05 사용자 제공 `EBS Lobby (1).zip` 검토 결과, References 폴더의 디자인 자산 대비 minor 정제 (테이블 ID 표기 `Day2-#071` → `#071`) 발견. 동시에 기존 `visual/screenshots/` 의 6장 (2026-04-15 캡쳐) 이 신 디자인 SSOT (References) 와 시각·정보구조 차이가 큼 (특히 ebs-lobby-01-series.png 의 "월별 그룹핑" 은 2026-05-05 PRD 갱신으로 SUPERSEDED 명시).

본 backlog 는 신 디자인 prototype 캡쳐 7장으로 visual asset 교체 + 모든 로비 관련 문서 정합 갱신을 추적한다.

## 범위

| # | 작업 | 상태 |
|---|------|:----:|
| 1 | zip → References sync (Day2- prefix 제거 8 파일) | ✅ |
| 2 | claude-design 작업 영역 → archive 이동 + .gitignore 추가 | ✅ |
| 3 | `visual/screenshots/` 5장 overwrite (01~05) | ✅ |
| 4 | `visual/screenshots/` 2장 신규 (06 hands / 07 settings) | ✅ |
| 5 | 00 Login 보류 (BS-02-01 분리, 캡쳐 토글 실패) | ⏸ |
| 6 | Overview.md §화면 6 Hand History 신설 | ✅ |
| 7 | Overview.md §화면 7 Settings 신설 | ✅ |
| 8 | Overview.md 화면 표 (line 280) 시각 자료 컬럼 추가 | ✅ |
| 9 | Overview.md line 548 `Day2-#069` → `#069` | ✅ |
| 10 | UI.md mockup HTML 5건 redirect (legacy 보존) | ✅ |
| 11 | Hand_History.md PNG 인라인 + 영역 표 추가 | ✅ |
| 12 | Table.md line 303 캡션 보강 | ✅ |
| 13 | Lobby.md §Ch.8 화면 갤러리 7장 PNG 인라인 (8.7 Settings 신규) + "월별→연도별" 정정 + v1.3.0 Changelog | ✅ |
| 14 | References/README.md zip sync changelog | ✅ |

## 보류 / 후속 (비범위)

| 항목 | 사유 |
|------|------|
| 00 Login 캡쳐 | BS-02-01 auth 로 분리됨. 토글 실패 (localStorage 키 패턴 추측 미스). 별도 ROI 평가 후 재캡쳐. |
| Operations.md PNG 추가 | Settings 전체가 아닌 Preferences 탭 중심 캡쳐가 정합. 별도 ROI 평가. |
| docs/mockups/ebs-lobby-*.html 6건 archive 이동 | UI.md redirect 만으로 충분. 외부 링크 안전 우선. 그대로 유지. |

## 결과 산출물

```
docs/
+- 1. Product/
|  +- Lobby.md                                v1.3.0 (Ch.8 + 7 PNG 인라인)
+- 2. Development/2.1 Frontend/Lobby/
|  +- Overview.md                                 §화면 6/7 신설 + Day2 prefix 제거
|  +- UI.md                                       mockup 5건 redirect
|  +- Hand_History.md                             PNG 인라인
|  +- Table.md                                    line 303 보강
|  +- visual/screenshots/                         5 modified + 2 new
|  +- References/EBS_Lobby_Design/                zip sync (8 files)
+- 2. Development/2.1 Frontend/Backlog/
   +- B-092-lobby-visual-screenshots-cascade-2026-05-05.md   본 항목 (DONE)
```

## 변경 라인 수 (자체 측정)

| 파일 | +/- 라인 |
|------|---------|
| Overview.md | +95 / -6 |
| UI.md | +12 / -5 |
| Hand_History.md | +18 / -1 |
| Table.md | +1 / -1 |
| Lobby.md | +18 / -8 |
| References/README.md | +1 / 0 |
| .gitignore | +4 / 0 |

## Changelog

| 날짜 | 변경 |
|------|------|
| 2026-05-05 | 신규 등재 + 즉시 DONE (당일 완료). 사용자 directive: "Q1~Q5 분기 결정 후 자율 진행" 결과. |
| 2026-05-05 | **확장 (옵션 G — 사람 친화 강화)**. 추가 캡쳐 5장 (00 Login / 04b Floor Map / 04c CC Focus / 04d Launch CC modal / 07b Settings GFX). PRD v1.3.0 → v1.4.0 점진 강화 (Ch.1/3/4/5/6/8 챕터 보존 + 시각 풍부도 7→14장 + 약어 사전 박스 + 18세 일반인 기준 톤). 사용자 directive: Q1-b/Q2-b/Q3-c/Q4-a + 자율 iteration. PRD 폐기 (옵션 A) 거부 → EBS 표준 PRD-Overview 이중 구조 보존. |
