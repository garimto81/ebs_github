---
id: SG-010
title: "Tooling: spec_drift_check.py 정밀화 (Settings, Schema, WebSocket)"
type: tooling
sub_type: spec_drift_scanner
status: PENDING
owner: conductor
created: 2026-04-20
affects_chapter:
  - tools/spec_drift_check.py
  - docs/4. Operations/Spec_Gap_Registry.md
protocol: Spec_Gap_Triage §7 (Type D — meta)
reimplementability: UNKNOWN
reimplementability_checked: 2026-04-20
reimplementability_notes: "status=PENDING, scanner 정밀화 tooling task"
---
# SG-010 — spec_drift_check.py 정밀화

## 배경

2026-04-20 첫 실행에서 `spec_drift_check.py --all` 은 7 계약 중 4 계약 (api, events, fsm, rfid) 의 D1 을 의미있게 감지했다. 나머지 3 계약은 scanner 한계로 false positive 가 다수 섞였다.

## 미흡 영역

| 계약 | 현재 상태 | 문제 |
|------|----------|------|
| **schema** | D3=25 | 정규식이 markdown inline code (\`table_name\`) 도 CREATE TABLE 로 오인식 |
| **settings** | D2=13 | 탭별 scope 분리 없음, migration 0005 CheckConstraint 파싱 미구현 |
| **websocket** | stub | 미구현. WebSocket_Events.md §4 ↔ team2 websocket/*.py 비교 |

## 개선 후보

| 개선 | 방법 | 우선순위 |
|------|------|----------|
| Schema.md 표준 declaration 블록 확정 | `### 테이블 \`foo\`` 아래 `CREATE TABLE foo (...)` 블록 강제 | HIGH |
| Settings detector — 탭 분리 | `### {탭명}` 아래 필드 표만 추출 + 탭별 key prefix 매핑 | MEDIUM |
| **Settings detector — camelCase ↔ snake_case 정규화** | 2026-04-20 Agent C F5 판정: D3 30건 중 9건이 scanner noise (`animationSpeed` vs `animation_speed` 등). 비교 전 양쪽 key 를 공통 canonical form (snake_case lower) 으로 변환 | **HIGH** |
| WebSocket detector 구현 | `### {eventName}` 패턴 매칭 + `app.state.ws_manager.send(...)` 호출 grep | MEDIUM |
| AST 기반 re-parser | dart_analyzer + libcst 사용 | LOW (파이썬 regex 충분) |
| `--baseline` 옵션 추가 | 기존 drift 는 silent, 신규 drift 만 출력 | HIGH (pre-push hook 개선) |

## 수락 기준

- [ ] `--schema` D3 false positive < 10% (inline code 오인식 제거)
- [ ] `--settings` D2 가 실제 migration 0005 CheckConstraint 와 매칭
- [ ] `--settings` D3 에서 camelCase/snake_case 변형 동일 식별자 처리 (SG-008-b13 참조 — 9건 → D4 전환 예상)
- [ ] `--websocket` detector 동작 (stub 제거)
- [ ] `--baseline logs/drift_baseline.json` 옵션 추가 (pre-push hook 연동)
