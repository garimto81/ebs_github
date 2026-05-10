---
id: B-088-B
title: "team1 기획 문서 REST path kebab → PascalCase 변환 (B-088 subscope)"
status: DONE
created: 2026-04-21
updated: 2026-04-21
owner: team1
resolved-commit: ce7a063
mirror: none
---

# B-088-B — team1 기획 문서 REST path 정렬

## 해결 (2026-04-21 17:20, commit `ce7a063`)

사용자 지시 "남은 미해결 작업 대기하지 말고 진행" 에 따라 team2 PR-4 대기 않고 cut-over 선제 전환:

- ✅ **JSON field snake → camelCase**: 43건 (선행 `29fe1b5`)
- ✅ **Path variable snake → camelCase**: 23건 (선행 `29fe1b5`)
- ✅ **REST path kebab → PascalCase**: **357건 전환 완료** (44 파일, `ce7a063`)
- ✅ **코드 측 Repository/Mock**: 83 + 50 path 동기화 (`ce7a063`)

## 남은 cascade (team2 세션 이행 필요)

실 Backend 연결 복원 = team2 PR-4 (router kebab → PascalCase) 필요.
상세: `docs/4. Operations/Conductor_Backlog/NOTIFY-team2-B088-PR4-rest-path-migration.md`

## 본래 보류 이유 (해결 전 분석 기록)

단순 regex 로 처리 불가 — 수동 분류 필요:

| 분류 | 예시 | 조치 |
|------|------|------|
| Backend REST API path | `/AuditLogs`, `/HandHistory`, `/BlindStructures` | PascalCase 로 변환 필요 |
| Flutter 라우트 | `/Lobby`, `/GraphicEditor`, `/ForgotPassword`, `/Reports/HandsSummary` | 프레임워크 관행 (원칙 1 scope 외) — 유지 |
| URL 예시 (외부) | `https://example.com/hand-history` | 유지 |
| 코드 주석 내 경로 | 컨텍스트 의존 | 수동 판정 |

자동 정규식만으로 위 4 케이스 구분 불가. team2 PR-4 (Backend router PascalCase) 완료 후 backend 실제 path 기준으로 일괄 업데이트가 안전.

## 주요 영향 파일

| 파일 | kebab path 건수 | 비고 |
|------|:---:|------|
| Graphic_Editor/UI.md | 46 | skin-editor 관련 |
| Graphic_Editor/References/skin-editor/prd-skin-editor.prd.md | 15 | draft |
| Graphic_Editor/References/skin-editor/ebs-ui-design-plan.md | 10 | draft |
| Graphic_Editor/References/skin-editor/pokergfx-vs-ebs-skin-editor.prd.md | 33 | draft |
| Graphic_Editor/References/skin-editor/EBS-Skin-Editor_v3.prd.md | 39 | draft |
| Lobby/Overview.md | 18 | 정식 SSOT |
| Lobby/UI.md | 15 | 정식 SSOT |
| archive/ | 81 | historical — 제외 |

## 실행 조건 및 수락 기준

**선행 의존**: team2 PR-4 완료

완료 시점 체크리스트:
- [ ] `Backend_HTTP.md` 의 정식 PascalCase path 목록 확보
- [ ] team1 docs 전수 검색 후 Backend API path 만 교체
- [ ] Flutter 라우트 / URL 예시 / 외부 링크 유지
- [ ] References/skin-editor/ draft 별도 판정 (유지 or 폐기)

## 현재 상태 (2026-04-21 본 commit 후)

| 계층 | 규약 | 잔재 | 상태 |
|------|------|:---:|:----:|
| JSON field | camelCase | 0 snake | ✅ |
| Path variable | camelCase | 0 snake | ✅ |
| REST path | PascalCase | 374 kebab | ⏳ team2 PR-4 대기 |

## 관련

- SSOT: `docs/2. Development/2.5 Shared/Naming_Conventions.md` v2 §1
- Master: `docs/4. Operations/Conductor_Backlog/B-088-naming-convention-camelcase-migration.md`
- 선행 team1 work: `c6bd858` / `de7f55f` / `38a0ed4`
- 본 commit: team1 기획 문서 JSON/path variable camelCase 정렬
