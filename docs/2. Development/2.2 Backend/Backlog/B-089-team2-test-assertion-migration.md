---
id: B-089
title: "B-088 후속 — test assertion snake→camelCase 완전 교체"
status: PENDING
source: docs/4. Operations/Plans/B088_team2_execution_plan_2026-04-21.md §2.5
---

# [B-089] team2 test assertion 완전 교체 (B-088 PR 2 후속)

- **날짜**: 2026-04-21
- **teams**: [team2]
- **선행**: B-088 PR 2 (EbsBaseModel + schemas migration 완료 — 2026-04-21)

## 배경

B-088 PR 2 infrastructure 도입 (EbsBaseModel, alias_generator=to_camel, populate_by_name=True) 후 response JSON 이 자동으로 camelCase 로 직렬화. 기존 test assertion 이 snake_case 로 남아있어 regression 발생:

- **규모**: 24 파일 자동 치환 후 187/247 통과 (76%)
- **남은 실패**: 52 tests + 8 errors (migrations_runtime 관련)
- **잔여 snake_case 필드**: WSOP sync fixture / WS command payload / operator denied message 등 자동 치환에서 누락된 필드

## 설명

남은 test 실패를 해소하여 247/247 baseline 복구.

### 대상 필드 (잔여 식별 필요)

- `test_wsop_sync_fixtures.py` — WSOP LIVE fixture JSON 이 snake_case 로 저장되어있음. 실제 WSOP LIVE 는 camelCase → fixture 도 camelCase 로 교체 필요
- `test_ws_cc_commands.py` — WS command payload 필드 (action_type, action_amount 등)
- `test_sync_ssot_routes.py` — sync route response field
- `test_wsop_sync_events.py` — event 매핑 field
- `test_websocket.py` — WS envelope

### 전략

1. 실패 test 하나씩 `pytest -x --tb=short` 로 필드명 식별
2. `.replace('"snake_field"', '"camelField"')` 패턴 추가 치환
3. WSOP fixture JSON 은 별도 작업 — WSOP LIVE 원본 규약 확인 후 일괄 변환
4. Migrations runtime 8 errors — bcrypt/conftest 관련, 별건 이슈 가능

## 수락 기준

- [ ] `pytest tests/ -q` 결과 247 passed, 0 failed (baseline 복구)
- [ ] WSOP LIVE fixture JSON 은 camelCase (실 spec 정렬)
- [ ] B-088 PR 3/4 진입 전 이 항목 완료

## 의존

- **Blocks**: B-088 PR 3 (WS PascalCase), PR 4 (REST path PascalCase) — test 가 통과해야 다음 PR 진행 가능
- **Blocked by**: 없음 (B-088 PR 2 완료 후 즉시 착수 가능)

## 변경 이력

| 날짜 | 변경 |
|------|------|
| 2026-04-21 | 신규 작성 — B-088 PR 2 infrastructure 도입 시 식별된 regression 해소 |
