# testing — 테스트 문서 네비게이션

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 테스트 문서 6종 네비게이션 |
| 2026-04-09 | 추가 | TEST-06 앱 테스트 감사, TEST-07 앱 QA 전략 |

---

## 개요

EBS 소프트웨어 QA 테스트 문서 모음. 물리 하드웨어 테스트는 범위 외 — 모든 RFID 테스트는 Mock HAL로만 수행한다.

## 문서 목록

### 전략 & 계획

| 문서 | 파일 | 용도 |
|------|------|------|
| **Test Plan** | `TEST-01-test-plan.md` | 테스트 전략, 피라미드, 도구, 커버리지 목표, CI/CD |
| **E2E Scenarios** | `TEST-02-e2e-scenarios.md` | 방송 하루 순서 기반 10개 E2E 시나리오 |
| **Mock Data** | `TEST-04-mock-data.md` | Mock WSOP LIVE, RFID, Player, Config JSON/YAML |
| **QA Checklist** | `TEST-05-qa-checklist.md` | 수동 QA 체크리스트 56항목 (소프트웨어만) |

### 게임 엔진 (별도 범위)

| 문서 | 파일 | 용도 |
|------|------|------|
| **Game Engine Fixtures** | `TEST-03-game-engine-fixtures.md` | Hold'em 대표 테스트 케이스 32개 (입력/기대출력) |

### 앱 QA (Lobby / CC / Graphic Editor)

| 문서 | 파일 | 용도 |
|------|------|------|
| **App Test Audit** | `TEST-06-app-test-audit.md` | 3개 앱 테스트 품질 감사 결과 (현황 진단) |
| **App QA Strategy** | `TEST-07-app-qa-strategy.md` | 앱별 QA 전략, 테스트 항목, 구현 순서 |

> **앱 QA 구현 시 참조 순서**: TEST-06 (현황) → TEST-07 (전략) → 앱별 행동 명세 (BS-02, BS-05)

## 참조 문서

| 참조 | 경로 |
|------|------|
| 용어/Mock 모드 정의 | `contracts/specs/BS-00-definitions.md` |
| 트리거 경계/Mock 합성 | `contracts/specs/BS-06-game-engine/BS-06-00-triggers.md` |
| RFID HAL 인터페이스 | `contracts/api/API-03-rfid-hal-interface.md` |
| Hold'em 라이프사이클 | `team3-engine/specs/engine-spec/BS-06-01-holdem-lifecycle.md` |
| Hold'em 베팅 | `team3-engine/specs/engine-spec/BS-06-02-holdem-betting.md` |
