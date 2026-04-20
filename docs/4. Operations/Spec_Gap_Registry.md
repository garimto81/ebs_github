---
title: Spec Gap Registry — Drift 집계 + 해소 추적
owner: conductor
tier: internal
last-updated: 2026-04-20
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "감지 도구 + 분류 체계 + Registry 자체로 외부 인계 가능"
related:
  - Spec_Gap_Triage.md §7 Type D
  - tools/spec_drift_check.py
  - Conductor_Backlog/
---

# Spec Gap Registry — Spec Drift 집계

> Type D (기획 ↔ 코드 불일치) 의 **현재 상태 snapshot + 해소 추적 index**. 정기 scan (`tools/spec_drift_check.py --all`) 결과를 이 문서가 소화한다.

## 1. 목적

EBS 는 **외부 개발팀 인계용 완결 프로토타입**이다. 기획서와 코드가 서로 다른 값을 선언하면 인계받은 팀이 재구현할 수 없다. 빌드 실패 없이 은밀히 누적되는 drift 를 체계적으로 감지·분류·해소하기 위한 레지스트리.

## 2. 분류 체계

Type D sub-type 정의 및 해소 규칙: `Spec_Gap_Triage.md §7`.

## 3. 감지 도구

- **스캐너**: `tools/spec_drift_check.py`
- **Registry 갱신**: `python tools/spec_drift_check.py --all --format=json > logs/drift_report.json`
- **Pre-push 경고**: `.claude/hooks/pre_push_drift_check.py` (non-blocking)

## 4. 현재 Drift (2026-04-20 scan)

### 4.1 계약별 요약

| 계약 | D1 | D2 | D3 | D4 | Total | 핵심 조치 |
|------|:--:|:--:|:--:|:--:|:-----:|-----------|
| REST API | 10 | 43 | 89 | 18 | 160 | D1 즉시 정정, D3 대부분 Auth_and_Session 병합 필요 |
| OutputEvent | 0 | 0 | 0 | 21 | 21 | **PASS** (2026-04-15 실측 정정 후 정렬) |
| FSM | 1 | 6 | 0 | 17 | 24 | TableFSM case 통일 SG 승격 |
| DB Schema | 0 | 3 | 25 | 0 | 28 | scanner 미완 — 후속 재측정 |
| RFID HAL | 0 | 0 | 5 | 3 | 8 | 문서 보강 (추가 스트림/메서드 누락) |
| Settings | 0 | 13 | 0 | 0 | 13 | scanner false positive — 후속 정밀화 |
| WebSocket | — | — | — | — | — | stub. 후속 구현. |

> 스캐너 자체가 정규식 기반 best-effort 이므로 D2/D3 에는 false positive 가 섞여 있다. D1 은 신뢰도 높음.

### 4.2 실질적으로 중요한 Drift TOP 5

| # | 계약 | 유형 | 요약 | 조치 |
|:-:|------|------|------|------|
| 1 | FSM | D1 | TableFSM 문서=UPPERCASE, 코드=lowercase | SG-009 (code-as-truth) — 문서를 lowercase 로 정정하거나 code 를 UPPERCASE 로 |
| 2 | API | D1 | 10 개 엔드포인트 문서에 `/api/v1` prefix 누락 | Conductor 즉시 정정 (본 커밋) |
| 3 | API | D3 | 89 개 code-only 엔드포인트 — 주로 CRUD DELETE/PATCH, audit, auth | Conductor 이번 커밋에서 핵심군은 문서에 표기. 전량 정리는 SG-008 |
| 4 | Schema | D3 | Schema.md 의 테이블 declaration 이 inline code (\`table_name\`) 기반이라 스캐너가 CREATE TABLE 문을 놓침 | 스캐너 정밀화 SG-010 |
| 5 | RFID | D3 | `onDeckRegistered`, `onAntennaStatusChanged`, `onError`, `onStatusChanged`, `onCardRemoved` 기획에 언급 없음 | RFID_HAL_Interface.md 보강 (이번 커밋 보강 후 재측정) |

### 4.3 즉시 해소 (이번 커밋)

| 계약 | 유형 | 대상 | 조치 |
|------|------|------|------|
| API | D1 | Backend_HTTP.md 10개 엔드포인트 표기 정정 | §1 Base URL 경로 prefix 규약 보강 (`/api/v1` 필수 명시) |
| FSM | D1 | TableFSM case 불일치 | SG-009 승격 (code 가 3개월 migration 를 거쳐 lowercase 로 정착. 문서를 코드에 맞춰 정정) — 본 커밋 포함 |
| RFID | D3 | 5 streams 보강 | RFID_HAL_Interface.md §X 참조 명시 (본 커밋 보강) |

### 4.4 SG 승격 index

| SG ID | 유형 | 계약 | 상태 | 비고 |
|-------|------|------|:----:|------|
| SG-008 | spec_drift | api | PENDING | D3 대량 endpoint 문서화 (CRUD, auth) |
| SG-009 | spec_drift | fsm | IN_PROGRESS | TableFSM case 통일 — 이번 커밋에서 BS_Overview §3.1 직렬화 규약 추가 |
| SG-010 | tooling | meta | PENDING | spec_drift_check.py 정밀화 (Settings, Schema, WebSocket) |
| SG-011 | spec_drift | rfid | PENDING | RFID_HAL_Interface §2.1 single-stream vs code 6-stream |

## 5. 스캔 명령 레퍼런스

```bash
# 전체 스캔 (markdown 리포트)
python tools/spec_drift_check.py --all

# JSON 출력 (Registry 자동 갱신용)
python tools/spec_drift_check.py --all --format=json > logs/drift_report.json

# 단일 계약
python tools/spec_drift_check.py --api
python tools/spec_drift_check.py --events
python tools/spec_drift_check.py --fsm
python tools/spec_drift_check.py --schema
python tools/spec_drift_check.py --rfid
python tools/spec_drift_check.py --settings
```

## 6. 갱신 주기

| 주기 | 트리거 |
|------|--------|
| **매 `git push` 전** | `pre_push_drift_check.py` 가 신규 drift 만 경고 |
| **주 1회 (권장)** | Conductor 가 수동 scan 후 §4.1 테이블 갱신 |
| **대규모 리팩토링 시** | 전량 scan 후 Registry 정비 |

## 7. 스캐너 한계 (Known Limitations)

| 한계 | 영향 | 개선 경로 |
|------|------|-----------|
| 정규식 기반 — 주석 처리된 선언 포함 가능 | false positive 소수 | AST 기반 파서 (후속) |
| Schema detector 가 inline code backtick 을 CREATE TABLE 로 오인 | D2 noise | Schema.md 의 표준 declaration 블록 확정 후 스캐너 정밀화 |
| Settings detector 가 탭별 scope 분리 없음 | D2 전량 false | SG-010 |
| WebSocket detector stub | drift 미감지 | SG-010 |
| 반대 방향 (문서 설명된 미구현 API) 부분 커버 | D2 일부 누락 가능 | TODO 마커 병행 grep |

## Changelog

| 날짜 | 변경 | 비고 |
|------|------|------|
| 2026-04-20 | v1.0 최초 등록 | 7 계약 scan, 3 drift 즉시 해소, SG-008~010 승격 |
