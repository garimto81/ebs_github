---
title: Risk Matrix
owner: conductor
tier: internal
last-updated: 2026-04-22
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "Risk Matrix 완결 (4KB)"
---
# 문서 변경 리스크 분류 기준 (Risk Matrix)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-22 | v2.1 | R6 중앙 서버 SPOF 등재 (Foundation §8.5 N PC + 중앙 서버 아키텍처 반영, B-205) |
| 2026-04-17 | v2.0 | CCR 폐기 반영. 리스크 분류는 유지, 처리 경로를 free_write + decision_owner 로 변경 |
| 2026-04-12 | v1.0 | 3등급 리스크 분류 + Fast-Track 도입 |

## 개요

문서 변경을 3등급으로 분류하여 처리 경로를 차등화합니다.
DORA 연구에 따르면, 리스크 무차별 중앙 승인은 리드타임에 부정적이면서 변경 실패율 감소에 기여하지 않습니다.

## 리스크 등급

### LOW — 추가 전용 (Additive Only)

| 항목 | 기준 |
|------|------|
| **변경 유형** | `add` only (신규 필드, 섹션, enum 값 추가) |
| **기존 항목** | 변경/삭제 없음 |
| **영향팀** | 1개 이하 |
| **Breaking** | 아님 |

**처리 경로**: 자동 검증 + 영향팀 1명 approve → **publisher 팀이 직접 반영**

**예시**:
- 신규 WebSocket 이벤트 타입 추가
- API 엔드포인트에 optional 필드 추가
- 스펙 문서에 설명 섹션 보강
- 문서 오류/오타 수정

### MEDIUM — 비파괴 수정 (Non-Breaking Modification)

| 항목 | 기준 |
|------|------|
| **변경 유형** | `modify` (타입 변경, 범위 변경, 값 수정) |
| **기존 항목** | 변경 있음, 삭제 없음 |
| **영향팀** | 2개 이하 |
| **Breaking** | 아님 (하위 호환 유지) |

**처리 경로**: 영향팀 **전원** approve + 자동 검증 → **publisher 팀이 직접 반영**

**예시**:
- JWT 만료 정책 시간 변경 (1h → 30m)
- 프로토콜명 명시 (기존 미정의 → 확정)
- enum 값의 설명 변경

### HIGH — 파괴적 변경 (Breaking Change)

| 항목 | 기준 |
|------|------|
| **변경 유형** | `remove`, `rename`, 또는 breaking `modify` |
| **기존 항목** | 삭제 또는 구조 변경 |
| **영향팀** | 3개 이상, 또는 cross-cutting |
| **Breaking** | 예 |

**처리 경로**: subscriber 팀 전원 사전 합의 + **Conductor 에스컬레이션** 필수

**예시**:
- 기존 API 엔드포인트 삭제
- 데이터 스키마 구조 변경 (EventFlightStatus enum 전환)
- RBAC 비트플래그 도입 (기존 문자열 → 비트 연산)
- 3개+ 팀 영향 변경

## 등급 판정 규칙

```
Draft 분석
  ├─ 변경 유형이 remove 또는 rename 포함? ──→ HIGH
  ├─ 기존 항목 삭제 있음? ──→ HIGH
  ├─ 영향팀 3개+? ──→ HIGH
  ├─ Breaking 키워드 포함? ──→ HIGH
  │   (breaking, 삭제, deprecated, 구조 변경, 마이그레이션 필수)
  ├─ 변경 유형이 modify 포함? ──→ MEDIUM
  ├─ 영향팀 2개? ──→ MEDIUM
  └─ 그 외 (add only, 영향팀 0-1개) ──→ LOW
```

## publisher의 직접 수정 권한

`contracts/team-policy.json`의 `contract_ownership[file].direct_edit` 값으로 제어:

| direct_edit | 의미 |
|-------------|------|
| `"LOW"` | LOW 등급 변경만 publisher 직접 반영 가능 |
| `"MEDIUM"` | LOW + MEDIUM 등급까지 직접 반영 가능 |
| `"NONE"` | 모든 등급 Conductor 에스컬레이션 필수 (cross-cutting 파일) |

## 프로젝트 리스크 (Foundation Ch.9 기반)

EBS 프로젝트 전체에 적용되는 전략적 리스크 6건.

| # | 리스크 | 영향 | 완화 전략 | 상태 |
|---|--------|------|----------|------|
| R1 | RFID 통합 공급 파트너 미확보 | 높음 | 3개 업체 병행 RFI (Sun-Fly 회신, Angel/엠포플러스 진행 중) | Phase 0 진행 |
| R2 | 22종 게임 엔진 복잡도 과소평가 | 높음 | 1종(Hold'em) → 9종 → 22종 점진적 확장 | Phase 1 대응 |
| R3 | PokerGFX 역설계 IP 리스크 | 중 | 클린룸 설계 원칙 (기능 스펙만 참조, 코드 독립 작성) | 상시 적용 |
| R4 | RFID 리더+안테나 호환성 | 높음 | Phase 1 POC에서 조기 검증 (ST25R3911B + ESP32) | Phase 1 검증 |
| R5 | 운영 무인화 시 기존 스태프 저항 | 중 | Phase 5까지 단계적 전환, AI 도입은 보조 도구로 시작 | Phase 5 대응 |
| R6 | **중앙 서버 SPOF (1 피처 테이블 = 1 PC + 중앙 BO/DB)** | 높음 | Foundation §8.5 복수 테이블 아키텍처 — LAN 장애 · 중앙 서버 다운 · 로컬 fallback 시나리오 `docs/4. Operations/Network_Deployment.md` 에서 정의. crash 복구 = 프로세스 재시작 시 DB snapshot 재로드 (§6.4). 운영 대응: 중앙 서버 redundancy (예: warm-standby) + per-PC 로컬 캐시 — Phase 외 운영 기획 책임 | 기획 완결 (운영 책임 이관) |

## 참고

- DORA: Streamlining Change Approval (dora.dev)
- Architecture Advice Process — Andrew Harmel-Law (Thoughtworks)
- `tools/ccr_validate_risk.py` — 리스크 자동 분류 스크립트
