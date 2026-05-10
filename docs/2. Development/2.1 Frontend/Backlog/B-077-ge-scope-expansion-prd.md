---
id: B-077
title: "GE scope 확장 PRD 작성 (BS-08-05/06/07 — Trigger / DB Mapping / Extension Points)"
status: PENDING
source: docs/3. Change Requests/done/CR-conductor-20260421-ge-scope-expansion.md
owner: team1
created: 2026-04-21
blocked-by: "사용자 confirm 5개 항목 (CR-conductor-20260421-ge-scope-expansion.md §'미확정')"
mirror: none
---

# B-077 — GE scope 확장 PRD 작성

## 배경

CR-conductor-20260421-ge-scope-expansion 결정에 따라 team1 GE 의 scope 가 **trigger / db mapping / extension points** 3개 영역으로 확장됨. 본 task 는 3개 PRD 작성.

## 작업 항목

### B-077-1 — BS-08-05 Trigger Mapping PRD

| 항목 | 내용 |
|------|------|
| 파일 | `docs/2. Development/2.1 Frontend/Graphic_Editor/Trigger_Mapping.md` |
| legacy-id | BS-08-05 |
| 요구 prefix | GET-01 ~ GET-NN |
| 핵심 spec | trigger DSL 문법, 입력 source enumeration (RFID/CC/WSOP/Engine/User), trigger → 이미지 호출 매핑, sandbox 격리 |
| 의존 | 사용자 confirm — 입력 source 범위, DSL 형태 (선언적 vs 절차적) |

### B-077-2 — BS-08-06 DB Mapping PRD

| 항목 | 내용 |
|------|------|
| 파일 | `docs/2. Development/2.1 Frontend/Graphic_Editor/DB_Mapping.md` |
| legacy-id | BS-08-06 |
| 요구 prefix | GED-01 ~ GED-NN |
| 핵심 spec | skin field ↔ Backend Schema (DATA-04) 매핑, 이미지 자산 저장 위치 결정, refresh 정책 |
| publisher | team2 (Schema.md SSOT 유지) |
| subscriber | team1 GE |
| 의존 | 사용자 confirm — 매핑 방향성, 이미지 저장 위치 |

### B-077-3 — BS-08-07 Extension Points PRD

| 항목 | 내용 |
|------|------|
| 파일 | `docs/2. Development/2.1 Frontend/Graphic_Editor/Extension_Points.md` |
| legacy-id | BS-08-07 |
| 요구 prefix | GEX-01 ~ GEX-NN |
| 핵심 spec | plugin slot interface 정의 (외부 개발팀 인계용), trust boundary, 권한 모델, 구현 out-of-scope |
| 의존 | 사용자 confirm — trust model |

## 후속 (PRD 완료 후)

- `BS_Overview.md` § GE 행 갱신 (8 → 11 하위 문서)
- `Graphic_Editor_API.md` (API-07) trigger 엔드포인트 추가 검토 (team2)
- `team-policy.json` `Graphic_Editor_API` subscriber 변경 없음 (team1, team4 유지)

## blocked-by

다음 5개 사용자 confirm 후 작업 시작:

1. 트리거 입력 소스 범위 (RFID/CC/WSOP/Engine/사용자 정의 중 어디까지)
2. 트리거 DSL 형태 (선언적 YAML/JSON vs 절차적 Lua/Python sandbox)
3. DB 매핑 방향성 (단방향 read vs 양방향)
4. 이미지 자산 저장 위치 (.gfskin ZIP 내부 vs CDN vs hybrid)
5. 확장 plugin trust boundary (1st-party only vs 3rd-party 허용)
