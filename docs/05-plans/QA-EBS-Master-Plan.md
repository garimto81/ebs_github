# QA-EBS-Master-Plan — EBS 5-Phase QA 마스터 플랜

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | v1.0.0 전체 5-Phase QA Master Plan |
| 2026-04-08 | §8 → §8.5.1 추가 | Hi/Lo Split 게임 7종 Lo 판정 규칙 매트릭스 |
| 2026-04-08 | §8 → §8.7.1 추가 | Draw 게임 7종 카드 교환 라운드 매트릭스 (PRD-GAME-02 재검증) |

---

## 개요

EBS Core(WSOP LIVE + RFID + Command Center → Game Engine → Overlay Graphics)의 구현 착수 전에 **각 Phase의 통과 기준, 실패 시나리오 커버리지, 기획 환류 경로**를 확정한다. 이 문서는 sibling 레포 개발자가 "무엇을 어떻게 검증할 것인가"를 착수 시점부터 알 수 있게 한다.

---

## 목차

1. [QA 범위 & 전제](#1-qa-범위--전제)
2. [5-Phase QA 전략](#2-5-phase-qa-전략)
3. [테스트 환경 & 도구](#3-테스트-환경--도구)
4. [테스트 유형 매트릭스](#4-테스트-유형-매트릭스)
5. [입력 QA — RFID 소프트웨어 계층](#5-입력-qa--rfid-소프트웨어-계층)
6. [입력 QA — WSOP LIVE API](#6-입력-qa--wsop-live-api)
7. [입력 QA — Command Center](#7-입력-qa--command-center)
8. [처리 QA — Game Engine](#8-처리-qa--game-engine)
9. [처리 QA — 3입력 동시성](#9-처리-qa--3입력-동시성)
10. [출력 QA — Overlay Graphics](#10-출력-qa--overlay-graphics)
11. [UI QA — Lobby / Console / Action Tracker](#11-ui-qa--lobby--console--action-tracker)
12. [성능 & Soak 테스트](#12-성능--soak-테스트)
13. [RACI 매트릭스](#13-raci-매트릭스)
14. [결함 관리 & Phase Gate](#14-결함-관리--phase-gate)
15. [QA 결과 문서화 & 기획 환류 파이프라인](#15-qa-결과-문서화--기획-환류-파이프라인)
16. [부록 A: Feature ID → TC ID + BS-xx 매핑](#16-부록-a-feature-id--tc-id--bs-xx-매핑)
17. [부록 B: 용어 & 상태값 레지스트리](#17-부록-b-용어--상태값-레지스트리)

---

## 1. QA 범위 & 전제

### EBS Core 정의

```
WSOP LIVE(대회정보) + RFID(카드) + Command Center(액션) → Game Engine → Overlay Graphics
```

EBS QA는 이 파이프라인의 **소프트웨어 계층 전체**를 검증한다.

### 테스트 대상

| 범주 | 수량 | 설명 |
|------|:----:|------|
| Feature Catalog | 134개 | 144개 중 SRC-001~010 제외 |
| 게임 변형 | 22종 | Flop 12 + Draw 7 + Stud 3 |
| 화면 | 3개 | Lobby, Command Center, Settings |
| 입력 파이프라인 | 3개 | WSOP LIVE API, RFID, CC |

### 비대상 (명시적 제외)

| 항목 | 제외 사유 |
|------|----------|
| SRC-001~010 (Sources) | OBS/vMix 위임, EBS 범위 외 |
| WSOP LIVE 자체 | EBS 외부 시스템, 단방향 API 소비만 |
| 포스트프로덕션 (Adobe) | 시간축 경계 — EBS는 실시간 라이브만 |
| 방송 송출 장비 (ATEM 등) | 하드웨어 인프라 |
| 물리 RFID 하드웨어 | ST25R3911B, ESP32, 안테나 — sibling 레포 영역 |
| UX/사용성 테스트 | 별도 트랙 분리 |

### 기술 스택

| 계층 | 스택 | 비고 |
|------|------|------|
| Lobby | React / Next.js (TBD) | 웹 기반 |
| Command Center | Flutter / Dart | 크로스 플랫폼 앱 |
| Overlay Graphics | Flutter / Dart + Rive (.riv) | 벡터 애니메이션 |
| Game Engine | 순수 Dart | FSM 기반 |
| Back Office | Python / FastAPI | SQLite → PostgreSQL |
| 출력 | NDI / HDMI (ATEM 스위처) | 방송 송출 |

### 핵심 전제

1. **Mock HAL 전략**: RFID 하드웨어 없이 모든 소프트웨어 기능 검증 가능. `MockRfidReader` → `CardDetected` 이벤트 합성. Mock에서 바뀌는 것은 RFID HAL 구현체 1개뿐
2. **수동 폴백 필수**: 모든 자동 입력(RFID, API)에 대해 수동 입력 경로가 존재하며, QA에서 반드시 검증
3. **SysOp 참조**: Lobby 수동 생성 시나리오는 WSOP LIVE SysOp(시스템 운영 관리자 도구) 기능을 참조
4. **Mix 게임 강제 포함**: HORSE, 8-Game, PPC, Dealer's Choice 등 17종 Mix 이벤트 전환 시나리오를 모든 관련 섹션에 포함
5. **"충분하다" 판정 금지**: 어떤 입력 경로든 "정상 케이스만으로 충분하다"고 판정하지 않음. 수동 폴백, SysOp 시나리오, Mix 게임 전환 점검 필수

---

## 2. 5-Phase QA 전략

### Phase별 QA 목표 매트릭스

| Phase | 기간 | 범위 | KPI | 완료 정의 |
|:-----:|------|------|-----|----------|
| 1 POC | 2026 H1 | RFID E2E 5단계 | 인식률 ≥ 99.5%, 지연 < 200ms, 연속 ≥ 4시간 | 5단계 시나리오 E2E 1회 통과 |
| 2 Hold'em | 2026 H2 | Hold'em 1종 완벽 | 인식률 ≥ 99.9%, 지연 < 100ms, 복제율 ≥ 90%, 연속 ≥ 12시간 | 8시간 연속 방송 가능 |
| 3 확장 | 2027 H1 | 22종 게임 | 전 게임 기능 체크리스트 **PASS** | 22종 × 기본 시나리오 전부 통과 |
| 4 안정화 | 2027 H2 | 성능 + 장애 복구 | 24시간 연속, Chaos 매트릭스 전 셀 통과 | 프로덕션 승인 |
| 5 자동화 | 2028+ | QA 자동화 + CI/CD | 자동 회귀 커버리지 ≥ 80% | CI/CD 파이프라인 통합 |

### Phase 1 POC — 5단계 시나리오

| 단계 | 시나리오 | Mock/Real | 검증 대상 | 테스트 유형 |
|:----:|---------|:---------:|----------|-----------|
| 1 | 로그인 + RBAC 기본 | Mock | 인증 흐름, Admin/Operator/Viewer 접근 | E2E |
| 2 | 카드덱 등록 | Mock RFID 데이터 | UID → Suit/Rank 매핑 52장 | Integration |
| 3 | 게임 설정 | Mock | 홀덤 선택, 플레이어 6명 등록 | E2E |
| 4 | RFID 입력 | Mock RFID 데이터 | 카드 스캔 → Game Engine 인식 | Integration |
| 5 | 오버레이 출력 | Real | Rive 렌더링 → 방송 화면 | E2E |

> **수동 폴백**: 단계 2, 4에서 Mock RFID 실패 시 52장 그리드 수동 입력 경로도 검증한다.

### Phase 2 Hold'em — 확장 시나리오

| 시나리오 | 검증 대상 | TC 범위 |
|---------|----------|--------|
| 홀덤 FSM 9상태 전체 전이 | 상태 기계 정확성 | TC-G1-002-* |
| All-In + Side Pot | 팟 분배 계산 정확성 | TC-G1-001-* |
| Miss Deal | 핸드 무효화 + 재시작 | TC-G1-001-* |
| Run It Twice | 복수 보드 처리 | TC-G1-023-* |
| Bomb Pot | 전원 강제 베팅 | TC-G1-001-* |
| 블라인드/앤티 7종 | std, button, bb, bb_bb1st, live, tb, tb_tb1st | TC-G1-001-* |
| Security Delay | 출력 지연 정확성 | TC-OUT-006-* |
| 12시간 Soak | 메모리, 프레임, GC pause | TC-SOAK-* |

### Phase 3 확장 — 22종 게임 커버리지 전략

| 계열 | 게임 수 | 전략 |
|------|:-------:|------|
| Flop | 12 | 홀덤 TC 기반 확장, 홀카드 장수(2~6)와 Hi/Lo 분할만 차분 검증 |
| Draw | 7 | 카드 교환(Draw) 라운드 신규 TC + 드로우 순서 |
| Stud | 3 | Up/Down 카드 순서, 3rd Street 베팅 시작 |

**Mix 게임 전환 QA**:

| Mix 유형 | 포함 게임 | 전환 검증 |
|---------|----------|----------|
| HORSE | Hold'em, Omaha Hi-Lo, Razz, Stud, Stud Hi-Lo | 5종 순환 시 상태 초기화 |
| 8-Game | HORSE + 2-7 Triple, NL Hold'em, PL Omaha | 8종 순환 |
| PPC | Dealer's Choice subset | 임의 전환 |
| Dealer's Choice | 22종 전체 | 플레이어 선택 → 즉시 전환, 이전 게임 상태 완전 정리 |

### Phase 4~5 — 안정화 & 자동화

| Phase | QA 초점 | 신규 TC |
|:-----:|---------|--------|
| 4 | 24시간 Soak, Chaos 매트릭스 전 셀, 복구 시간 측정 | TC-CHAOS-*, TC-SOAK-24H-* |
| 5 | CI/CD 통합, 자동 회귀 스위트, 릴리스 자동 검증 | 기존 TC 자동화 전환 |

---

## 3. 테스트 환경 & 도구

### 소프트웨어 테스트 환경

| 계층 | 도구 | 용도 |
|------|------|------|
| Unit / Widget | Flutter test (`dart test`) | Game Engine FSM, 팟 계산, UI 컴포넌트 |
| Integration | Flutter `integration_test` | 3입력 파이프라인, API → Engine → Overlay |
| E2E (Lobby) | Playwright | 웹 기반 Lobby 전체 경로 |
| E2E (CC/Overlay) | Flutter driver | Flutter 앱 전체 경로 |
| 성능 벤치마크 | 커스텀 Dart 벤치마크 | 지연 측정, 프레임레이트 |

### Mock 서버

| Mock 대상 | 구현 방식 | 데이터 |
|----------|----------|--------|
| WSOP LIVE API | HTTP Mock 서버 | 대회/선수/블라인드 JSON replay |
| RFID 리더 | `MockRfidReader` (Dart) | 52장 UID 시퀀스 재생 |
| 네트워크 장애 | tc netem 또는 동등 도구 | 지연 주입, 단절 재현, 복구 검증 |

> **Mock HAL 원칙**: `IRfidReader` Dart 추상 인터페이스를 공유하며 Riverpod DI로 Real/Mock 교체. Mock에서 바뀌는 것은 HAL 구현체 1개뿐.

### 테스트 계정 (RBAC 3티어)

| 역할 | 권한 | 검증 목적 |
|------|------|----------|
| **Admin** | 전체 화면/기능 접근 | 전 기능 정상 동작 |
| **Operator** | 할당된 1개 테이블 CC만 | 접근 제한 검증, 다른 테이블 차단 |
| **Viewer** | 읽기 전용 | 쓰기 차단, 버튼 비활성화 |

### 출력 검증

| 항목 | 방법 |
|------|------|
| NDI 출력 | 프레임 캡처 + 타임스탬프 주입 → 지연 측정 |
| HDMI/SDI 출력 | ATEM 스위처 경유 캡처 |
| Rive 렌더링 | Flutter Widget Test + 시각 스냅샷 비교 |
| 지연 측정 | Game Engine 이벤트 발생 시각 → Overlay 렌더링 완료 시각 차이 |

### 제외 장비

| 장비 | 사유 |
|------|------|
| ST25R3911B | 물리 RFID 리더 — sibling 레포 |
| ESP32 | RFID 펌웨어 — sibling 레포 |
| RFID 안테나 | 물리 하드웨어 — sibling 레포 |

---

## 4. 테스트 유형 매트릭스

| 유형 | 범위 | 자동화 | 빈도 | 도구 |
|------|------|:------:|------|------|
| Unit | Game Engine FSM, 팟 계산, 핸드 평가 | ✅ | 매 커밋 | `dart test` |
| Widget | Flutter UI 컴포넌트 | ✅ | 매 커밋 | Flutter test |
| Integration | 3입력 파이프라인, API → Engine → Overlay | ✅ | 매 PR | `integration_test` |
| E2E | Phase 1 5단계, Lobby → CC → Overlay 전체 경로 | 일부 | 매 릴리스 | Playwright + Flutter driver |
| Regression | 22종 게임별 기본 시나리오 | ✅ | 매 릴리스 | 자동화 스위트 |
| Performance | 지연 측정, 프레임레이트, 인식률 | 일부 | Phase Gate | 커스텀 벤치마크 |
| Soak | 장시간 연속 운영 (4H/12H/24H) | 일부 | Phase Gate | 자동 스크립트 |
| Chaos | 3입력 동시 실패 / 복구 | 수동 | Phase Gate | 네트워크 시뮬레이터 |
| RBAC | 역할별 접근 권한 | ✅ | 매 릴리스 | E2E 시나리오 |

### 유형별 Phase 매핑

| 유형 | Phase 1 | Phase 2 | Phase 3 | Phase 4 | Phase 5 |
|------|:-------:|:-------:|:-------:|:-------:|:-------:|
| Unit | ✅ | ✅ | ✅ | ✅ | ✅ |
| Widget | ✅ | ✅ | ✅ | ✅ | ✅ |
| Integration | ✅ | ✅ | ✅ | ✅ | ✅ |
| E2E | ✅ | ✅ | ✅ | ✅ | ✅ |
| Regression | — | ✅ | ✅ | ✅ | ✅ |
| Performance | — | ✅ | — | ✅ | ✅ |
| Soak | ✅(4H) | ✅(12H) | — | ✅(24H) | ✅ |
| Chaos | — | — | — | ✅ | ✅ |
| RBAC | ✅ | ✅ | ✅ | ✅ | ✅ |

### 자동화 목표

| Phase | 자동 TC 비율 | 수동 TC 비율 |
|:-----:|:-----------:|:-----------:|
| 1~2 | ≥ 50% | ≤ 50% |
| 3 | ≥ 60% | ≤ 40% |
| 4 | ≥ 70% | ≤ 30% |
| 5 | ≥ 80% | ≤ 20% |

---

## 5. 입력 QA — RFID 소프트웨어 계층

> **물리 하드웨어 테스트 제외**. Mock RFID 데이터(52장 UID) → 소프트웨어 레벨만 검증한다.

### 카드 등록 경우의 수 매트릭스

| 조건 | 입력 | 기대 동작 | TC ID |
|------|------|----------|-------|
| 52장 정상 매핑 | Mock UID 52개 순차 | 모두 Suit/Rank 매핑 성공 | TC-SYS-004-01 |
| Duplicate UID | 동일 UID 2회 전송 | 에러 감지 + 경고 표시 | TC-SYS-004-02 |
| 미등록 카드 | 매핑에 없는 UID | **Not Registered** 상태 표시 | TC-SYS-004-03 |
| 부분 인식 (1~3장 누락) | 49~51개 UID | 누락 카드 표시 + 수동 입력 활성화 | TC-SYS-004-04 |
| 자동 등록 (Mock 모드) | "자동 등록" 1클릭 | 가상 매핑 52장 즉시 완료 | TC-SYS-004-05 |
| 덱 교체 | 등록 완료 후 새 덱 스캔 | 기존 매핑 해제 + 신규 등록 | TC-SYS-004-06 |

### Mock RFID 연결 상태 매트릭스

| 조건 | 기대 동작 | TC ID |
|------|----------|-------|
| Mock RFID 정상 연결 | 데이터 스트림 수신 중 표시 | TC-MW-005-01 |
| Mock RFID 연결 단절 | 수동 입력 모드 자동 전환 | TC-MW-005-02 |
| Mock RFID 연결 복구 | 자동 모드 복귀 + 데이터 정합성 확인 | TC-MW-005-03 |
| Mock RFID 지연 (>500ms) | 경고 표시 + 대기 | TC-MW-005-04 |

### 수동 폴백 시나리오 (CRITICAL)

| 조건 | 입력 | 기대 동작 | TC ID |
|------|------|----------|-------|
| 52장 그리드 수동 입력 | GUI에서 카드 선택 | Game Engine에 정확히 전달 | TC-G1-015-01 |
| 수동 입력 중 RFID 복구 | RFID 재연결 | 수동 입력 데이터 유지 + 전환 확인 | TC-G1-015-02 |
| 수동 + 자동 혼합 | 일부 RFID + 일부 수동 | 두 소스 데이터 병합 정확성 | TC-G1-015-03 |
| SysOp 모드 수동 등록 | API 없이 수동 덱 생성 | Back Office DB에 저장 | TC-G1-015-04 |

### DeckFSM 상태 전이

| From | To | 조건 | TC ID |
|------|-----|------|-------|
| **UNREGISTERED** | **REGISTERING** | 덱 등록 시작 | TC-DECK-FSM-01 |
| **REGISTERING** | **REGISTERED** | 52장 전부 매핑 완료 | TC-DECK-FSM-02 |
| **REGISTERING** | **PARTIAL** | 49~51장 매핑 (1~3장 누락) | TC-DECK-FSM-03 |
| **REGISTERED** | **UNREGISTERED** | 덱 교체 요청 | TC-DECK-FSM-04 |
| 모든 상태 | **MOCK** | 수동 모드 전환 | TC-DECK-FSM-05 |
| **MOCK** | **REGISTERING** | RFID 복구 후 재등록 | TC-DECK-FSM-06 |
| **PARTIAL** | **REGISTERED** | 누락 카드 수동 보완 | TC-DECK-FSM-07 |

### GEB/GEP Feature별 TC 할당

| Feature ID | 기능명 | TC 범위 |
|-----------|-------|--------|
| GEB-001 | 트리뷰 | TC-GEB-001-01~03 |
| GEB-002 | 드래그 | TC-GEB-002-01~02 |
| GEB-003 | 크기 조절 | TC-GEB-003-01~02 |
| GEB-004 | 속성 편집 | TC-GEB-004-01~03 |
| GEB-005 | 좌표 설정 | TC-GEB-005-01~02 |
| GEB-006 | 이미지/텍스트 배치 | TC-GEB-006-01~03 |
| GEB-007 | Pip 배치 | TC-GEB-007-01~02 |
| GEB-008 | 커뮤니티 영역 | TC-GEB-008-01~03 |
| GEB-009 | 팟 영역 | TC-GEB-009-01~02 |
| GEB-010 | 딜러 영역 | TC-GEB-010-01~02 |
| GEB-011 | z-order | TC-GEB-011-01~02 |
| GEB-012 | 가시성 | TC-GEB-012-01~02 |
| GEB-013 | Undo | TC-GEB-013-01~03 |
| GEB-014 | 캔버스 크기 | TC-GEB-014-01~02 |
| GEB-015 | 내보내기 | TC-GEB-015-01~02 |
| GEP-001 | 이름 표시 | TC-GEP-001-01~02 |
| GEP-002 | 칩 표시 | TC-GEP-002-01~02 |
| GEP-003 | 홀카드 (2~6장) | TC-GEP-003-01~04 |
| GEP-004 | 베팅 | TC-GEP-004-01~03 |
| GEP-005 | 액션 표시 | TC-GEP-005-01~02 |
| GEP-006 | 승률 | TC-GEP-006-01~03 |
| GEP-007 | 핸드랭크 | TC-GEP-007-01~02 |
| GEP-008 | Fold 표시 | TC-GEP-008-01~02 |
| GEP-009 | 승자 표시 | TC-GEP-009-01~02 |
| GEP-010 | 배경 | TC-GEP-010-01~02 |
| GEP-011 | 카드 애니메이션 | TC-GEP-011-01~02 |
| GEP-012 | 칩 애니메이션 | TC-GEP-012-01~02 |
| GEP-013 | Stud 레이아웃 | TC-GEP-013-01~03 |
| GEP-014 | Draw 레이아웃 | TC-GEP-014-01~03 |
| GEP-015 | Hi-Lo 분할 | TC-GEP-015-01~03 |

---

## 6. 입력 QA — WSOP LIVE API

WSOP LIVE API는 단방향(WSOP LIVE → EBS)으로 대회 일정, 블라인드 구조, 선수 정보(사진/국적/통계), 테이블 배정을 수신한다.

### 정상 수신 매트릭스

| 데이터 유형 | 수신 조건 | 기대 동작 | TC ID |
|-----------|----------|----------|-------|
| Tournament | 정상 응답 | Lobby 자동 동기화 | TC-MW-001-01 |
| Player | 정상 응답 | 선수 사진/국적/통계 표시 | TC-MW-001-02 |
| Blind Structure | 정상 응답 | 블라인드 레벨 자동 적용 | TC-MW-001-03 |
| Table Assignment | 정상 응답 | 좌석 배치 반영 | TC-MW-001-04 |

### 장애 시나리오 매트릭스

| 조건 | 기대 동작 | TC ID |
|------|----------|-------|
| 네트워크 단절 30초+ | 로컬 캐시 **READ-ONLY** 모드 전환 | TC-MW-001-05 |
| 지연 2~5초 | 로딩 표시 + 수신 대기 | TC-MW-001-06 |
| 부분 응답 (Player만 실패) | 나머지 정상 + Player 재시도 | TC-MW-001-07 |
| 부분 응답 (Blind만 실패) | 나머지 정상 + Blind 재시도 | TC-MW-001-08 |
| 스키마 변경 (필드 추가) | 미지 필드 무시, 기존 동작 유지 | TC-MW-001-09 |
| 스키마 변경 (필드 삭제) | 누락 필드 기본값 표시 + 경고 | TC-MW-001-10 |
| 역방향 쓰기 시도 | **차단** (단방향 API 정책) | TC-MW-001-11 |
| 장시간 단절 후 복구 | 전체 동기화 + 데이터 정합성 확인 | TC-MW-001-12 |

### 수동 입력 폴백 (SysOp 참조)

| 조건 | 입력 | 기대 동작 | TC ID |
|------|------|----------|-------|
| API 없이 수동 Event 생성 | Lobby에서 수동 입력 | CC로 정상 전달 | TC-MW-001-13 |
| 수동 Series 생성 | SysOp 참조 수동 입력 | Back Office DB 저장 | TC-MW-001-14 |
| 수동 Player 등록 | 이름/국적 직접 입력 | 오버레이에 정상 표시 | TC-MW-001-15 |
| 수동 Blind Structure | 레벨별 수동 입력 | Game Engine에 정확히 전달 | TC-MW-001-16 |
| API 복구 후 수동 데이터 | 수동 → 자동 전환 | 수동 데이터 보존 + API 데이터 병합 | TC-MW-001-17 |

### Mix 게임 모드 API 수신

| 조건 | 기대 동작 | TC ID |
|------|----------|-------|
| Single 게임 이벤트 수신 | 단일 게임 유형 적용 | TC-MW-001-18 |
| Fixed Mix 이벤트 수신 (HORSE) | 5종 게임 순환 설정 자동 적용 | TC-MW-001-19 |
| Choice Mix 이벤트 수신 | Dealer's Choice 모드 활성화 | TC-MW-001-20 |
| Mix 이벤트에서 게임 변경 알림 | 실시간 게임 유형 전환 | TC-MW-001-21 |

### 로컬 캐시 검증

| 조건 | 기대 동작 | TC ID |
|------|----------|-------|
| 캐시 유효 (단절 < 5분) | 캐시 데이터로 정상 운영 | TC-MW-002-01 |
| 캐시 만료 (단절 > 30분) | 만료 경고 + 수동 모드 권고 | TC-MW-002-02 |
| 캐시 무결성 검증 | 재연결 시 서버 데이터와 비교 | TC-MW-002-03 |

---

## 7. 입력 QA — Command Center

Command Center는 Flutter 앱으로 8개 액션 버튼(Fold, Check, Bet, Call, Raise, All-in, New Hand, Deal)을 통해 Game Engine에 명령을 전달한다.

### 액션 버튼 경우의 수 매트릭스 (홀덤 기준)

| 게임 상태 | 액션 | 기대 동작 | TC ID |
|----------|------|----------|-------|
| **PRE_FLOP**, action_on=player | Fold | player → **folded**, 다음 액션 전달 | TC-G1-001-01 |
| **PRE_FLOP**, action_on=player | Check | 유효성 검사 (BB만 가능) | TC-G1-001-02 |
| **PRE_FLOP**, action_on=player | Bet | 금액 입력 + 팟 업데이트 | TC-G1-001-03 |
| **PRE_FLOP**, action_on=player | Call | 현재 베팅 매칭 | TC-G1-001-04 |
| **PRE_FLOP**, action_on=player | Raise | 레이즈 금액 입력 + 유효성 검증 | TC-G1-001-05 |
| **PRE_FLOP**, action_on=player | All-in | 전체 칩 투입 | TC-G1-001-06 |
| **FLOP~RIVER**, action_on=player | Check | 베팅 없을 때만 허용 | TC-G1-001-07 |
| **IDLE** | New Hand | 새 핸드 시작 준비 | TC-G1-001-08 |
| **SETUP_HAND** | Deal | 카드 딜 시작 | TC-G1-001-09 |
| 모든 상태 | 비활성 액션 클릭 | 무반응 (버튼 비활성화) | TC-G1-001-10 |

### Undo/Redo 검증

| 조건 | 기대 동작 | TC ID |
|------|----------|-------|
| 단일 Undo | 직전 액션 취소, 상태 복원 | TC-G1-001-11 |
| 연속 Undo 3회 | 3단계 이전으로 복원 | TC-G1-001-12 |
| Undo 후 Redo | 취소된 액션 재적용 | TC-G1-001-13 |
| Undo 후 새 액션 | Redo 스택 클리어 | TC-G1-001-14 |
| Undo 불가 상태 (핸드 시작점) | Undo 버튼 비활성화 | TC-G1-001-15 |

### 1 Lobby : N CC 동시성

| 조건 | 기대 동작 | TC ID |
|------|----------|-------|
| 1 Lobby : 2 CC 동시 활성 | 같은 테이블 동시 액션 시 WebSocket 우선순위 해소 | TC-MW-008-01 |
| CC 크래시 후 재시작 | `last_table_id`로 자동 복귀, 세션 복원 | TC-MW-008-02 |
| CC 연결 단절 30초 | Lobby에 연결 상태 경고 표시 | TC-MW-008-03 |
| CC 연결 복구 | 상태 동기화 + 누락 이벤트 재전송 | TC-MW-008-04 |
| 2 CC가 같은 테이블에 동시 액션 | 충돌 해소 (타임스탬프 우선) | TC-MW-008-05 |

### RBAC 접근 제어

| 역할 | CC 접근 | 기대 동작 | TC ID |
|------|:------:|----------|-------|
| **Admin** | 모든 테이블 | 전 기능 사용 가능 | TC-SYS-001-01 |
| **Operator** | 할당 테이블만 | 다른 테이블 접근 시 거부 | TC-SYS-001-02 |
| **Operator** | 미할당 테이블 | 에러 메시지 + 접근 차단 | TC-SYS-001-03 |
| **Viewer** | 모든 테이블 | 읽기만 가능, 액션 버튼 비활성화 | TC-SYS-001-04 |

### Mix 게임 전환 시 CC 동작

| 조건 | 기대 동작 | TC ID |
|------|----------|-------|
| HORSE 게임 전환 알림 | CC에 새 게임 유형 표시 + 액션 버튼 재구성 | TC-MW-008-06 |
| Dealer's Choice 전환 | 게임 선택 UI 활성화 | TC-MW-008-07 |
| 게임 전환 중 진행 중 액션 | 현재 핸드 완료 후 전환 | TC-MW-008-08 |

---

## 8. 처리 QA — Game Engine

Game Engine은 순수 Dart FSM 기반으로 22종 게임을 처리한다. 홀덤 명세(BS-06-01~08)를 기준으로 한다.

### 8.1 홀덤 FSM 9개 상태 전이 매트릭스

| From | To | 조건 | TC ID |
|------|-----|------|-------|
| **IDLE** | **SETUP_HAND** | `StartHand()`, `pl_dealer` != -1, seats ≥ 2 | TC-G1-002-01 |
| **SETUP_HAND** | **PRE_FLOP** | blinds posted + hole cards dealt | TC-G1-002-02 |
| **PRE_FLOP** | **FLOP** | 베팅 라운드 완료 | TC-G1-002-03 |
| **FLOP** | **TURN** | 베팅 라운드 완료 | TC-G1-002-04 |
| **TURN** | **RIVER** | 베팅 라운드 완료 | TC-G1-002-05 |
| **RIVER** | **SHOWDOWN** | 베팅 라운드 완료 | TC-G1-002-06 |
| **SHOWDOWN** | **HAND_COMPLETE** | 승자 결정 + 팟 분배 완료 | TC-G1-002-07 |
| **HAND_COMPLETE** | **IDLE** | 핸드 정리 완료 | TC-G1-002-08 |
| **PRE_FLOP~RIVER** | **SHOWDOWN** | 1인 제외 전원 Fold | TC-G1-002-09 |
| **PRE_FLOP~RIVER** | **RUN_IT_MULTIPLE** | All-In + Run It Twice 활성화 | TC-G1-002-10 |
| **RUN_IT_MULTIPLE** | **SHOWDOWN** | 복수 보드 처리 완료 | TC-G1-002-11 |

### 8.2 무효 전이 (거부 검증)

| From | To (시도) | 기대 | TC ID |
|------|----------|------|-------|
| **IDLE** | **FLOP** | 거부 (SETUP_HAND 필수) | TC-G1-002-12 |
| **SHOWDOWN** | **PRE_FLOP** | 거부 (HAND_COMPLETE 경유 필수) | TC-G1-002-13 |
| **HAND_COMPLETE** | **SHOWDOWN** | 거부 (역방향 금지) | TC-G1-002-14 |

### 8.3 블라인드/앤티 7종

| ante_type | 설명 | 검증 포인트 | TC ID |
|-----------|------|-----------|-------|
| `std` | 전원 앤티 | 전원 공제 확인 | TC-G1-003-01 |
| `button` | 버튼 앤티 | 딜러만 공제 | TC-G1-003-02 |
| `bb` | BB 앤티 | BB만 공제 | TC-G1-003-03 |
| `bb_bb1st` | BB 앤티 (BB 선행) | 순서: BB 앤티 → BB 블라인드 | TC-G1-003-04 |
| `live` | 라이브 앤티 | UTG 라이브 앤티 | TC-G1-003-05 |
| `tb` | 테이블 앤티 | 딜러 대신 공제 | TC-G1-003-06 |
| `tb_tb1st` | 테이블 앤티 (선행) | 순서: 앤티 → 블라인드 | TC-G1-003-07 |

### 8.4 All-In + Side Pot

| 조건 | 기대 동작 | TC ID |
|------|----------|-------|
| 2인 All-In (동일 스택) | 단일 Main Pot | TC-G1-004-01 |
| 2인 All-In (다른 스택) | Main Pot + Side Pot 1개 | TC-G1-004-02 |
| 3인 All-In (모두 다른 스택) | Main + Side 1 + Side 2 | TC-G1-004-03 |
| All-In + 나머지 베팅 계속 | Side Pot 별도 관리 | TC-G1-004-04 |
| All-In 후 Fold 동시 발생 | Side Pot 분배 순서 검증 | TC-G1-004-05 |
| 10인 테이블 전원 All-In | 최대 Side Pot 생성 + 분배 | TC-G1-004-06 |

### 8.5 핸드 평가

| 조건 | 기대 동작 | TC ID |
|------|----------|-------|
| 일반 승자 결정 | 핸드 랭킹 정확성 | TC-G1-005-01 |
| 동점 (Split Pot) | 균등 분배 + 홀수 칩 처리 | TC-G1-005-02 |
| Hi/Lo Split (Omaha Hi-Lo) | Hi 승자 + Lo 승자 별도 결정 | TC-G1-005-03 |
| Lo 조건 미충족 | Hi 승자가 전체 팟 획득 | TC-G1-005-04 |
| Kicker 비교 | 동일 랭크 시 Kicker 정확 비교 | TC-G1-005-05 |

### 8.5.1 Hi/Lo Split 게임 Lo 판정 규칙 매트릭스

Hi/Lo 게임 7종의 Lo 판정 규칙 차이를 검증한다. Lo 미충족 시 처리가 게임별로 다르다.

| 게임 | Lo 판정 규칙 | Lo 미충족 시 | TC ID |
|------|------------|------------|-------|
| Omaha Hi-Lo | 8-or-better | Hi만 수상 | TC-G1-005-06 |
| 5Card Omaha Hi-Lo | 8-or-better | Hi만 수상 | TC-G1-005-07 |
| 6Card Omaha Hi-Lo | 8-or-better | Hi만 수상 | TC-G1-005-08 |
| Courchevel Hi-Lo | 8-or-better | Hi만 수상 | TC-G1-005-09 |
| 7-Card Stud Hi-Lo | 8-or-better | Hi만 수상 | TC-G1-005-10 |
| Badeucy | Badugi + 2-7 로우 | 항상 분할 | TC-G1-005-11 |
| Badacey | Badugi + A-5 로우 | 항상 분할 | TC-G1-005-12 |

### 8.6 예외 시나리오

| 조건 | 기대 동작 | TC ID |
|------|----------|-------|
| Miss Deal | 핸드 무효화 + 카드 회수 + 재딜 | TC-G1-006-01 |
| Run It Twice | 복수 보드 생성 + 각 보드별 승자 | TC-G1-006-02 |
| Bomb Pot | 전원 강제 베팅 + PRE_FLOP 스킵 | TC-G1-006-03 |
| 플레이어 이탈 (mid-hand) | 해당 좌석 **sitting_out** + 핸드 계속 | TC-G1-006-04 |
| 타임아웃 | 자동 Fold 또는 Check | TC-G1-006-05 |
| 카드 부족 (Stud 8인+) | 커뮤니티 카드 전환 | TC-G1-006-06 |

### 8.7 22종 게임별 매트릭스

| 게임 | 정상 | All-In | Miss Deal | Run It Twice | Bomb Pot | Hi/Lo Split |
|------|:----:|:------:|:---------:|:------------:|:--------:|:-----------:|
| Texas Hold'em | TC-G1-010-01 | TC-G1-010-02 | TC-G1-010-03 | TC-G1-010-04 | TC-G1-010-05 | N/A |
| 6+ Hold'em (S>T) | TC-G1-010-06 | TC-G1-010-07 | TC-G1-010-08 | TC-G1-010-09 | TC-G1-010-10 | N/A |
| 6+ Hold'em (T>S) | TC-G1-010-11 | TC-G1-010-12 | TC-G1-010-13 | TC-G1-010-14 | TC-G1-010-15 | N/A |
| Pineapple | TC-G1-010-16 | TC-G1-010-17 | TC-G1-010-18 | TC-G1-010-19 | TC-G1-010-20 | N/A |
| Omaha | TC-G1-011-01 | TC-G1-011-02 | TC-G1-011-03 | TC-G1-011-04 | TC-G1-011-05 | N/A |
| Omaha Hi-Lo | TC-G1-011-06 | TC-G1-011-07 | TC-G1-011-08 | TC-G1-011-09 | TC-G1-011-10 | TC-G1-011-11 |
| 5Card Omaha | TC-G1-011-12 | TC-G1-011-13 | TC-G1-011-14 | TC-G1-011-15 | TC-G1-011-16 | N/A |
| 5Card Omaha Hi-Lo | TC-G1-011-17 | TC-G1-011-18 | TC-G1-011-19 | TC-G1-011-20 | TC-G1-011-21 | TC-G1-011-22 |
| 6Card Omaha | TC-G1-012-01 | TC-G1-012-02 | TC-G1-012-03 | TC-G1-012-04 | TC-G1-012-05 | N/A |
| 6Card Omaha Hi-Lo | TC-G1-012-06 | TC-G1-012-07 | TC-G1-012-08 | TC-G1-012-09 | TC-G1-012-10 | TC-G1-012-11 |
| Courchevel | TC-G1-012-12 | TC-G1-012-13 | TC-G1-012-14 | TC-G1-012-15 | TC-G1-012-16 | N/A |
| Courchevel Hi-Lo | TC-G1-012-17 | TC-G1-012-18 | TC-G1-012-19 | TC-G1-012-20 | TC-G1-012-21 | TC-G1-012-22 |
| 5Card Draw | TC-G1-013-01 | TC-G1-013-02 | TC-G1-013-03 | N/A | TC-G1-013-04 | N/A |
| 2-7 Single | TC-G1-013-05 | TC-G1-013-06 | TC-G1-013-07 | N/A | TC-G1-013-08 | N/A |
| 2-7 Triple | TC-G1-013-09 | TC-G1-013-10 | TC-G1-013-11 | N/A | TC-G1-013-12 | N/A |
| A-5 Triple | TC-G1-013-13 | TC-G1-013-14 | TC-G1-013-15 | N/A | TC-G1-013-16 | N/A |
| Badugi | TC-G1-013-17 | TC-G1-013-18 | TC-G1-013-19 | N/A | TC-G1-013-20 | N/A |
| Badeucy | TC-G1-013-21 | TC-G1-013-22 | TC-G1-013-23 | N/A | TC-G1-013-24 | TC-G1-013-25 |
| Badacey | TC-G1-013-26 | TC-G1-013-27 | TC-G1-013-28 | N/A | TC-G1-013-29 | TC-G1-013-30 |
| 7-Card Stud | TC-G1-014-01 | TC-G1-014-02 | TC-G1-014-03 | N/A | TC-G1-014-04 | N/A |
| 7-Card Stud Hi-Lo | TC-G1-014-05 | TC-G1-014-06 | TC-G1-014-07 | N/A | TC-G1-014-08 | TC-G1-014-09 |
| Razz | TC-G1-014-10 | TC-G1-014-11 | TC-G1-014-12 | N/A | TC-G1-014-13 | N/A |

> **Run It Twice**: Draw/Stud 게임은 Run It Twice 비적용 (N/A).
> **Hi/Lo Split**: 해당하는 게임만 TC 할당 (Omaha Hi-Lo, 5Card Omaha Hi-Lo, 6Card Omaha Hi-Lo, Courchevel Hi-Lo, Badeucy, Badacey, 7-Card Stud Hi-Lo).

### 8.7.1 Draw 게임 카드 교환 라운드 매트릭스

Draw 계열 7종 고유의 카드 교환 시나리오를 검증한다. 교환 장수 제한은 PRD-GAME-02 기준.

| 게임 | 교환 라운드 수 | 교환 장수 제한 | Stand Pat | TC ID |
|------|:----------:|:----------:|:---------:|-------|
| Five Card Draw | 1 | 0~3 | 허용 | TC-G1-015-01 |
| 2-7 Single Draw | 1 | 0~5 | 허용 | TC-G1-015-02 |
| 2-7 Triple Draw | 3 | 0~5 | 허용 | TC-G1-015-03 |
| A-5 Triple Draw | 3 | 0~5 | 허용 | TC-G1-015-04 |
| Badugi | 3 | 0~4 | 허용 | TC-G1-015-05 |
| Badeucy | 3 | 0~5 | 허용 | TC-G1-015-06 |
| Badacey | 3 | 0~5 | 허용 | TC-G1-015-07 |

> **Five Card Draw**: PRD-GAME-02에 따라 교환 장수 **0~3장** 제한 (0~5가 아님).
> **Badugi**: 4장 게임이므로 교환 장수 **0~4장** 제한.

### 8.8 Mix 게임 전환 QA

| Mix 유형 | 전환 시나리오 | 검증 포인트 | TC ID |
|---------|------------|-----------|-------|
| HORSE | 5종 순환 전환 | 이전 게임 상태 완전 초기화 | TC-G1-020-01 |
| HORSE | 전환 중 진행 중 핸드 | 현재 핸드 완료 후 전환 | TC-G1-020-02 |
| 8-Game | 8종 순환 전환 | 상태 초기화 + 블라인드/앤티 재설정 | TC-G1-020-03 |
| PPC | Dealer's Choice subset | 플레이어 선택 → 즉시 전환 | TC-G1-020-04 |
| Dealer's Choice | 임의 전환 (22종) | 이전 게임 잔여 상태 0 확인 | TC-G1-020-05 |
| Dealer's Choice | 동일 게임 연속 선택 | 상태 초기화 없이 계속 | TC-G1-020-06 |
| 전체 Mix | 전환 후 FSM 상태 | **IDLE**에서 시작 확인 | TC-G1-020-07 |

### 8.9 bet_structure별 검증

| bet_structure | 설명 | 검증 포인트 | TC ID |
|:------------:|------|-----------|-------|
| NL (0) | No Limit | 최소 베팅 = BB, 최대 = 전 스택 | TC-G1-007-01 |
| FL (1) | Fixed Limit | 베팅/레이즈 고정 금액 | TC-G1-007-02 |
| PL (2) | Pot Limit | 최대 베팅 = 현재 팟 | TC-G1-007-03 |

### 8.10 game_type별 검증

| game_type | 설명 | 추가 검증 | TC ID |
|:---------:|------|----------|-------|
| Cash (0) | 캐시 게임 | 리바이/애드온 없음 | TC-G1-008-01 |
| Regular (1) | 일반 토너먼트 | 블라인드 자동 상승 | TC-G1-008-02 |
| Bounty (2) | 바운티 | 바운티 처리 | TC-G1-008-03 |
| Mystery (3) | 미스터리 바운티 | 바운티 금액 랜덤 | TC-G1-008-04 |
| Flip (4) | 플립 | All-In 강제 | TC-G1-008-05 |
| Shootout (5) | 슛아웃 | 테이블 승자 진출 | TC-G1-008-06 |
| Satellite (6) | 새틀라이트 | 상위 대회 티켓 | TC-G1-008-07 |
| SNG (7) | SNG | 빠른 시작 | TC-G1-008-08 |

---

## 9. 처리 QA — 3입력 동시성

3개 입력(WSOP LIVE API, RFID, Command Center)이 동시에 동작하는 환경에서의 경합, 장애, 복구를 검증한다.

### 3입력 우선순위 정책

| 경합 상황 | 우선 적용 | 후순위 처리 | TC ID |
|----------|----------|-----------|-------|
| RFID 카드 인식 + CC 수동 카드 입력 동시 | RFID (자동) | CC 수동 입력 무시 + 경고 | TC-SYNC-001-01 |
| API 블라인드 변경 + CC 수동 블라인드 변경 | API (원본) | CC 변경 거부 + 알림 | TC-SYNC-001-02 |
| API 테이블 배정 변경 + CC 핸드 진행 중 | CC 핸드 완료 대기 | 핸드 종료 후 배정 적용 | TC-SYNC-001-03 |

### Chaos 테스트 매트릭스 (3×3)

| 장애 조합 | 기대 동작 | 복구 검증 | TC ID |
|----------|----------|----------|-------|
| RFID 실패 단독 | 수동 입력 전환, 게임 계속 | RFID 복구 시 자동 복귀 | TC-CHAOS-001 |
| API 실패 단독 | 로컬 캐시 READ-ONLY | API 복구 시 동기화 | TC-CHAOS-002 |
| CC 실패 단독 | Lobby 경고, 게임 일시 정지 | CC 복구 시 세션 재개 | TC-CHAOS-003 |
| RFID + API 실패 | 수동 입력 + 캐시 모드 | 순차 복구 시 정합성 | TC-CHAOS-004 |
| RFID + CC 실패 | 수동 입력 불가 + 게임 정지 | 양쪽 복구 후 상태 검증 | TC-CHAOS-005 |
| API + CC 실패 | 캐시 모드 + 게임 정지 | 순차 복구 시 데이터 일관성 | TC-CHAOS-006 |
| 3입력 전체 실패 | 전체 정지 + 긴급 상태 표시 | 순차 복구 순서 무관하게 정합성 | TC-CHAOS-007 |
| 3입력 전체 실패 → RFID만 복구 | 수동 CC로 게임 부분 재개 | 나머지 복구 시 완전 복귀 | TC-CHAOS-008 |
| 간헐적 RFID (50% 인식) | 부분 인식 + 수동 보완 혼합 | 안정화 후 정확성 검증 | TC-CHAOS-009 |

### 복구 정합성 검증

| 검증 항목 | 방법 | TC ID |
|----------|------|-------|
| 팟 금액 일관성 | 장애 전 팟 = 복구 후 팟 | TC-SYNC-002-01 |
| 카드 상태 일관성 | 딜된 카드 목록 불변 | TC-SYNC-002-02 |
| FSM 상태 일관성 | 장애 전 FSM 상태 보존 | TC-SYNC-002-03 |
| 플레이어 스택 일관성 | 베팅 내역 무손실 | TC-SYNC-002-04 |
| Overlay 표시 일관성 | 복구 후 Overlay 정확 반영 | TC-SYNC-002-05 |

### SysOp / 수동 폴백 통합

| 시나리오 | 기대 동작 | TC ID |
|---------|----------|-------|
| 3입력 전체 장애 시 SysOp 수동 운영 | 완전 수동 모드로 게임 진행 가능 | TC-SYNC-003-01 |
| 수동 운영 중 자동 복구 | 수동 데이터 보존 + 자동 전환 | TC-SYNC-003-02 |

---

## 10. 출력 QA — Overlay Graphics

Overlay Graphics는 Flutter + Rive (.riv) 기반으로 Game Engine 이벤트를 실시간 방송 그래픽으로 렌더링한다.

### Layer 1 실시간 그래픽 8종 트리거 매트릭스

| 그래픽 요소 | 트리거 이벤트 | 표시 조건 | TC ID |
|-----------|------------|----------|-------|
| 홀카드 | `CardDealt` | 카드 딜 완료 | TC-OUT-001-01 |
| 보드 카드 | `BoardUpdate` | Flop/Turn/River | TC-OUT-001-02 |
| 팟 | `PotUpdate` | 베팅 변경 | TC-OUT-001-03 |
| 승률 | `OddsCalculated` | 실시간 계산 완료 | TC-OUT-001-04 |
| 액션 배지 | `ActionReceived` | CC 액션 수신 | TC-OUT-001-05 |
| 블라인드 표시 | `BlindUpdate` | 레벨 변경 | TC-OUT-001-06 |
| 타이머 | `TimerTick` | 매 초 | TC-OUT-001-07 |
| 포지션 표시 | `DealerButton` | 딜러 변경 | TC-OUT-001-08 |

### Rive 애니메이션 검증

| 시나리오 | 기대 동작 | TC ID |
|---------|----------|-------|
| 카드 딜 애니메이션 | 지정 시간 내 완료 (< 500ms) | TC-OUT-002-01 |
| Fold 애니메이션 | 카드 페이드아웃 | TC-OUT-002-02 |
| All-In 애니메이션 | 칩 이동 + 강조 효과 | TC-OUT-002-03 |
| 승자 하이라이트 | 승자 카드/칩 강조 | TC-OUT-002-04 |
| 빠른 연속 이벤트 | 큐잉 + 순서 보장 + 드랍 없음 | TC-OUT-002-05 |
| Rive 파일 로딩 실패 | 폴백 정적 이미지 표시 | TC-OUT-002-06 |

### 해상도 전환

| 시나리오 | 기대 동작 | TC ID |
|---------|----------|-------|
| 1080p → 4K 전환 | 게임 중단 없이 해상도 변경 | TC-OUT-003-01 |
| 4K → 1080p 전환 | UI 요소 비례 축소 | TC-OUT-003-02 |
| 전환 중 이벤트 발생 | 이벤트 큐잉 → 전환 완료 후 처리 | TC-OUT-003-03 |

### NDI/SDI 출력

| 시나리오 | 기대 동작 | TC ID |
|---------|----------|-------|
| NDI 정상 출력 | 프레임 드랍 0, 지연 < 100ms | TC-OUT-004-01 |
| NDI 연결 끊김 | Lobby 경고 배지 표시 | TC-OUT-004-02 |
| NDI 재연결 | 자동 복구 + 프레임 연속성 확인 | TC-OUT-004-03 |
| HDMI 출력 (ATEM 경유) | 정상 프레임 전달 | TC-OUT-004-04 |
| Security Delay 적용 | 설정 지연시간만큼 정확히 지연 | TC-OUT-005-01 |
| Security Delay 해제 | 즉시 실시간 전환 | TC-OUT-005-02 |

### 지연 측정

| 측정 구간 | 목표 | 방법 | TC ID |
|----------|------|------|-------|
| Game Engine → Overlay 렌더링 | < 100ms (Phase 2) | 타임스탬프 주입 비교 | TC-PERF-001-01 |
| Overlay 렌더링 → NDI 출력 | < 50ms | 프레임 캡처 비교 | TC-PERF-001-02 |
| E2E (CC 입력 → 방송 화면) | < 200ms (Phase 1) | 전체 파이프라인 측정 | TC-PERF-001-03 |

### Feature ID → TC 할당 (Output 관련)

| Feature ID | 기능명 | TC 범위 |
|-----------|-------|--------|
| OUT-001 | 그래픽 출력 | TC-OUT-001-01 ~ 08 |
| OUT-002 | NDI 출력 | TC-OUT-004-01 ~ 03 |
| OUT-003 | HDMI 출력 | TC-OUT-004-04 |
| OUT-005 | 출력 해상도 설정 | TC-OUT-003-01 ~ 03 |
| OUT-006 | Security Delay 모드 | TC-OUT-005-01 ~ 02 |
| OUT-007 | 지연 시간 설정 | TC-PERF-001-01 ~ 03 |
| OUT-008 | 크로마키 출력 | TC-OUT-006-01 ~ 02 |
| OUT-009 | 출력 미리보기 | TC-OUT-007-01 ~ 02 |

### Mix 게임 전환 시 Overlay 동작

| 시나리오 | 기대 동작 | TC ID |
|---------|----------|-------|
| 게임 전환 시 Overlay 초기화 | 이전 그래픽 제거, 새 레이아웃 로드 | TC-OUT-008-01 |
| Draw 게임 전환 → 카드 영역 변경 | 드로우 표시 영역 활성화 | TC-OUT-008-02 |
| Stud 전환 → Up/Down 카드 레이아웃 | Stud 전용 카드 배치 | TC-OUT-008-03 |
| Hi/Lo 게임 → 분할 표시 | Hi/Lo 승자 동시 표시 | TC-OUT-008-04 |

---

## 11. UI QA — Lobby / Console / Action Tracker

### 11.1 Lobby 5계층 네비게이션 (BS-02 기반)

| 계층 | 화면 | 검증 항목 | TC ID |
|:----:|------|----------|-------|
| L1 | Season 목록 | 시즌 CRUD + API 동기화 | TC-UI-001-01 |
| L2 | Series 목록 | 시리즈 CRUD + 필터링 | TC-UI-001-02 |
| L3 | Event 목록 | 이벤트 CRUD + Mix 게임 설정 | TC-UI-001-03 |
| L4 | Table 목록 | 테이블 CRUD + TableFSM 상태 표시 | TC-UI-001-04 |
| L5 | Table 상세 | 좌석 배치 + CC 연결 상태 | TC-UI-001-05 |

### Lobby 수동 생성 시나리오 (CRITICAL)

| 시나리오 | 기대 동작 | TC ID |
|---------|----------|-------|
| API 없이 수동 Season 생성 | DB에 저장 + 목록 표시 | TC-UI-002-01 |
| 수동 Series 생성 | 게임 유형 + 바이인 직접 설정 | TC-UI-002-02 |
| 수동 Event 생성 + Mix 게임 | HORSE/8-Game 선택 가능 | TC-UI-002-03 |
| 수동 Table 생성 + 좌석 배치 | 2~10인 수동 배치 | TC-UI-002-04 |
| 수동 Player 등록 (사진/국적) | 데이터 직접 입력 + Overlay 반영 | TC-UI-002-05 |

### TableFSM 상태 전이

| From | To | 트리거 | TC ID |
|------|----|--------|-------|
| **EMPTY** | **SETUP** | 테이블 생성 | TC-UI-003-01 |
| **SETUP** | **LIVE** | 게임 시작 (좌석 ≥ 2) | TC-UI-003-02 |
| **LIVE** | **PAUSED** | 일시 정지 | TC-UI-003-03 |
| **PAUSED** | **LIVE** | 재개 | TC-UI-003-04 |
| **LIVE** | **CLOSED** | 게임 종료 | TC-UI-003-05 |
| **PAUSED** | **CLOSED** | 정지 중 종료 | TC-UI-003-06 |

### 11.2 Console / Settings 4섹션

| 섹션 | 설정 항목 | 검증 | TC ID |
|------|----------|------|-------|
| Output | 해상도, NDI/HDMI 선택 | 변경 즉시 적용 | TC-UI-004-01 |
| Overlay | 스킨 선택, 폰트, 색상 | Rive 미리보기 동기화 | TC-UI-004-02 |
| Game | 앤티/블라인드 구조, 타이머 | Game Engine 즉시 반영 | TC-UI-004-03 |
| Statistics | VPIP/PFR/AF 표시 설정 | 통계 패널 갱신 | TC-UI-004-04 |

### 11.3 Action Tracker 회귀

| 화면 | 베이스라인 | 회귀 검증 | TC ID |
|------|----------|----------|-------|
| AT 대시보드 | AT 8 mockup | 레이아웃 일치 | TC-UI-005-01 |
| AT 테이블 뷰 | AT 8 mockup | 좌석 배치 정확성 | TC-UI-005-02 |
| AT 핸드 히스토리 | AT 8 mockup | 데이터 표시 정확성 | TC-UI-005-03 |
| AT 통계 패널 | AT 8 mockup | 수치 계산 정확성 | TC-UI-005-04 |

### 11.4 RBAC 화면 접근 매트릭스

| 화면 | Admin | Operator | Viewer |
|------|:-----:|:--------:|:------:|
| Lobby (전체) | ✅ | ✅ (읽기) | ✅ (읽기) |
| Lobby CRUD | ✅ | — | — |
| CC (할당 테이블) | ✅ | ✅ | ✅ (읽기) |
| CC (미할당 테이블) | ✅ | — | ✅ (읽기) |
| Settings (Output) | ✅ | — | — |
| Settings (Overlay) | ✅ | ✅ | — |
| Settings (Game) | ✅ | — | — |
| Settings (Statistics) | ✅ | ✅ | ✅ (읽기) |
| Skin Editor | ✅ | — | — |

### 11.5 Skin Editor QA

| Feature ID | 기능 | TC 범위 |
|-----------|------|--------|
| SK-001 | 스킨 로드 | TC-SK-001-01 ~ 02 |
| SK-002 | 스킨 저장 (AES 암호화) | TC-SK-002-01 ~ 03 |
| SK-003 | 신규 생성 | TC-SK-003-01 ~ 02 |
| SK-004 | 미리보기 | TC-SK-004-01 ~ 02 |
| SK-005 | 배경 설정 | TC-SK-005-01 ~ 02 |
| SK-006 ~ SK-016 | 카드/좌석/폰트/색상 등 | TC-SK-006-01 ~ TC-SK-016-02 |

### Mix 게임 시 UI 변경

| 시나리오 | 기대 동작 | TC ID |
|---------|----------|-------|
| HORSE 이벤트 → Lobby 표시 | "HORSE" 게임 유형 + 5종 목록 | TC-UI-006-01 |
| 게임 전환 시 Lobby 상태 갱신 | 현재 게임 유형 실시간 표시 | TC-UI-006-02 |
| Dealer's Choice → CC 게임 선택 UI | 드롭다운으로 22종 선택 가능 | TC-UI-006-03 |

---

## 12. 성능 & Soak 테스트

### Phase별 연속 운영 목표

| Phase | 연속 시간 | 측정 항목 | 통과 기준 | TC ID |
|:-----:|:--------:|----------|----------|-------|
| 1 POC | ≥ 4시간 | 메모리, 프레임, RFID 인식률 | 인식률 ≥ 99.5%, 지연 < 200ms, 크래시 0 | TC-SOAK-001 |
| 2 Hold'em | ≥ 12시간 | 메모리, 프레임, GC pause, 인식률 | 인식률 ≥ 99.9%, 지연 < 100ms, 크래시 0 | TC-SOAK-002 |
| 3 확장 | ≥ 12시간 | 22종 게임 순환 + 메모리 | 전 게임 정상 동작, 메모리 누수 없음 | TC-SOAK-003 |
| 4 안정화 | ≥ 24시간 | 전체 스택 | 모든 메트릭 안정, 자동 복구 동작 | TC-SOAK-004 |

### 성능 측정 항목

| 항목 | 측정 방법 | 임계값 | TC ID |
|------|----------|--------|-------|
| Flutter 앱 메모리 | DevTools Profiler | 증가 추세 < 10MB/h | TC-PERF-002-01 |
| 프레임레이트 | Flutter Performance Overlay | ≥ 60fps (드랍 < 1%) | TC-PERF-002-02 |
| GC Pause | Dart Observatory | < 16ms (60fps 프레임 예산) | TC-PERF-002-03 |
| Rive 렌더링 지연 | 타임스탬프 비교 | < 33ms per frame | TC-PERF-002-04 |
| WebSocket 메시지 지연 | 라운드트립 측정 | < 50ms | TC-PERF-002-05 |
| API 응답 시간 | HTTP 클라이언트 로그 | < 500ms (p95) | TC-PERF-002-06 |
| DB 쿼리 시간 | FastAPI 미들웨어 | < 100ms (p95) | TC-PERF-002-07 |

### Soak 중 자동 계측

| 이벤트 | 자동 기록 |
|--------|----------|
| 메모리 스냅샷 | 10분 간격 |
| 프레임 드랍 카운트 | 1분 간격 |
| RFID 인식 성공/실패 | 매 이벤트 |
| Game Engine FSM 전이 | 매 전이 |
| 에러/경고 로그 | 실시간 |

> 물리 RFID 인식률 측정은 sibling 레포 영역. 이 문서의 Soak는 소프트웨어 앱 레벨 연속 운영만 다룬다.

---

## 13. RACI 매트릭스

### Sibling 레포별 × 테스트 유형 RACI

| 테스트 유형 | ebs (기획) | ebs_reverse (역설계) | ebs_ui (UI) | ui_overlay (Overlay) | ebs_hw (HW) |
|-----------|:----------:|:-------------------:|:-----------:|:-------------------:|:-----------:|
| Unit | — | C | R/A | R/A | R/A |
| Widget | — | — | R/A | R/A | — |
| Integration | C | I | R/A | R/A | I |
| E2E | A | I | R | R | I |
| Regression | A | I | R | R | — |
| Performance | C | I | R | R/A | I |
| Soak | A | — | R | R | R |
| Chaos | A | — | R | R | I |
| RBAC | C | — | R/A | — | — |

> **R** = Responsible, **A** = Accountable, **C** = Consulted, **I** = Informed

### Phase Gate 승인자

| Phase | 승인자 | 필요 증거 |
|:-----:|--------|----------|
| 1 → 2 | Project Lead + QA Lead | Phase 1 KPI 전 항목 PASS |
| 2 → 3 | Project Lead + QA Lead | Phase 2 KPI + 홀덤 전 TC PASS |
| 3 → 4 | Project Lead + QA Lead + Architect | 22종 게임 기본 TC 전부 PASS |
| 4 → 5 | Full Team | 24시간 Soak + Chaos 전 셀 PASS |

---

## 14. 결함 관리 & Phase Gate

### 결함 심각도 정의

| 심각도 | 정의 | 예시 | SLA |
|--------|------|------|-----|
| **Critical** | 핵심 기능 완전 불가, 데이터 손실 | FSM 전이 오류로 게임 진행 불가, 팟 계산 오류 | 즉시 수정 (다음 빌드) |
| **Major** | 핵심 기능 부분 불가, 우회 가능 | Side Pot 분배 오류 (수동 교정 가능), Undo 실패 | 해당 Phase 내 수정 |
| **Minor** | 비핵심 기능, UI 결함 | 폰트 깨짐, 애니메이션 끊김, 로그 오류 | 다음 Phase 수정 가능 |

### Phase 전환 조건

| 조건 | Phase 1→2 | Phase 2→3 | Phase 3→4 | Phase 4→5 |
|------|:---------:|:---------:|:---------:|:---------:|
| Critical 미해결 | 0 | 0 | 0 | 0 |
| Major 미해결 | ≤ 3 | ≤ 3 | ≤ 5 | ≤ 2 |
| Minor 미해결 | 제한 없음 | 제한 없음 | 제한 없음 | ≤ 10 |
| KPI 달성 | 전 항목 | 전 항목 | 전 항목 | 전 항목 |
| 회귀 스위트 통과 | — | 100% | 100% | 100% |

### 회귀 테스트 실행 조건

| 트리거 | 실행 범위 |
|--------|----------|
| Game Engine 변경 | 해당 게임 + 홀덤 기본 TC |
| Overlay 변경 | 해당 그래픽 + 전체 트리거 TC |
| CC 변경 | 액션 매트릭스 + Undo TC |
| RFID 소프트웨어 변경 | DeckFSM + 52장 매핑 TC |
| API 클라이언트 변경 | 정상/장애 매트릭스 TC |
| Phase Gate 직전 | 해당 Phase 전체 TC |

### Known Issue 관리

| 상태 | 처리 |
|------|------|
| **Open** | 활발히 수정 중 |
| **Deferred** | 다음 Phase로 이관 (Major 이하만 허용) |
| **Won't Fix** | 기술 제약로 수정 불가 (PRD에 대안 명세 필수) |
| **Resolved** | 수정 완료 + 재검증 PASS |

---

## 15. QA 결과 문서화 & 기획 환류 파이프라인

QA의 궁극적 목적은 "구현이 맞는지 확인"뿐 아니라 **"기획이 맞는지 검증"**이다. QA 결과가 기획 문서(Foundation PRD, BS-xx)를 수정하는 환류 경로를 정의한다.

> **범위**: 이 섹션은 기능 검증(Functional QA)의 환류만 다룬다. UX/사용성 테스트는 별도 트랙으로 분리하며, 이 문서 범위 밖이다.

### 15.1 QA 결과 보고서 형식

| 필드 | 설명 |
|------|------|
| Test Case ID | `TC-<FeatureID>-<case#>` (캐노니컬 ID 재사용) |
| 결과 | **PASS** / **FAIL** / **BLOCK** / **SKIP** |
| 재현 경로 | 실패 시 정확한 재현 스텝 |
| 기대 동작 | BS-xx 또는 PRD에 명시된 기대 |
| 실제 동작 | 관찰된 실제 동작 |
| 근본 원인 분류 | 5분류 (15.2 참조) |
| 영향 문서 | 수정 필요 시 대상 문서 경로 (`BS-04 §2.3` 또는 `PRD §6.2` 형식) |

**결과별 문서화 규칙**:

| 결과 | 처리 |
|------|------|
| **PASS** | 증거(스크린샷/로그) 아카이빙 + 회귀 베이스라인 등록 |
| **FAIL** | 근본 원인 분류 + 영향 문서 필수 기입 + 재현 경로 필수 |
| **BLOCK** | 차단 원인 명시 (선행 기능 미구현 / BS 미작성 / 환경 미구축 구분) |
| **SKIP** | 사유 기록 (해당 Phase 범위 외 등) |

**기입 예시**:

| TC ID | 결과 | 근본 원인 | 영향 문서 | 요약 |
|-------|------|----------|----------|------|
| TC-SYS-004-03 | **FAIL** | 구현 결함 | — | Mock RFID Duplicate UID 전송 시 에러 핸들러 미호출 |
| TC-G1-007-02 | **FAIL** | 미정의 경우 | `BS-06-05 §Side Pot` | 3인 All-In + 1인 Fold 동시 시 Side Pot 분배 순서 미명시 |
| TC-MW-002-01 | **FAIL** | 기획 결함 | `PRD §8.2` + `BS-02 §E` | 게임 종료 후 "Live"→"Empty" 직행 — "Closing" 중간 상태 누락 |
| TC-OUT-005-01 | **BLOCK** | BS 미작성 | `BS-07 (미존재)` | Overlay 트리거 명세 미작성으로 기대 동작 정의 불가 |
| TC-G1-015-01 | **FAIL** | 기술 제약 | `PRD §6.4` | 6+ Short Deck 실시간 확률 계산 < 100ms 불가 — 사전 계산 테이블 전환 필요 |

### 15.2 근본 원인 5분류

| # | 분류 | 정의 | 기획 수정 | 처리 경로 |
|:-:|------|------|:---------:|----------|
| 1 | **구현 결함** | 기획 명세대로 구현되지 않음 | — | sibling 레포 이슈 |
| 2 | **기획 결함** | 기획 명세 자체에 논리적 오류/누락 | ✅ | PRD/BS-xx 수정 PR + Edit History |
| 3 | **미정의 경우** | 기획 명세에 해당 시나리오 미정의 (가장 빈번) | ✅ | BS-xx 경우의 수 매트릭스 행 추가 |
| 4 | **기술 제약** | 기획은 맞지만 기술적 한계로 구현 불가 | ✅ | PRD/BS-xx에 대안 명세 + 원본 ~~취소선~~ |
| 5 | **환경 문제** | 테스트 환경, 선행 의존성, Mock 설정 오류 | — | 환경 재설정 / 선행 완료 대기 |

**판단 가이드**: "기획서에 이 시나리오가 적혀 있는가?"
- Yes + 구현 오류 → 1 (구현 결함)
- Yes + 기술 불가 → 4 (기술 제약)
- Yes + 논리 오류 → 2 (기획 결함)
- No → 3 (미정의 경우)
- 테스트 인프라 문제 → 5 (환경 문제)

### 15.3 환류 판정 매트릭스

| 결과 | 근본 원인 | 기획 수정 | 처리 |
|------|----------|:---------:|------|
| **PASS** | — | — | 증거 아카이빙 + 회귀 베이스라인 등록 |
| **FAIL** | 구현 결함 | — | sibling 레포 이슈 생성 |
| **FAIL** | 기획 결함 | ✅ | PRD/BS-xx Edit History 추가 + 경우의 수 매트릭스 수정 |
| **FAIL** | 미정의 경우 | ✅ | BS-xx에 새 경우의 수 행 추가 → TC 추가 생성 |
| **FAIL** | 기술 제약 | ✅ | PRD/BS-xx 원래 명세 ~~취소선~~ + 대안 명세 추가 |
| **BLOCK** | BS 미작성 | — | Phase Gate 산정에서 **제외** (BS 완성까지 보류) |
| **BLOCK** | 선행 기능 미구현 | — | 선행 TC 해소 후 재실행 |
| **SKIP** | Phase 범위 외 | — | 다음 Phase에서 재활성화 |

### 15.4 기획 문서 수정 워크플로우

```
QA 실행 → 결과 보고서 → 근본 원인 5분류
  |
  +-- 구현 결함 --> sibling 레포 이슈 (기획 레포 변경 없음)
  |
  +-- 기획 결함 --> PRD/BS-xx 수정 PR (기획 레포)
  |     +-- 수정 완료 --> 해당 TC 재실행 --> PASS 확인
  |
  +-- 미정의 경우 --> BS-xx 경우의 수 매트릭스 확장 PR
  |     +-- 새 경우의 수 기반 TC 추가 --> 재실행
  |
  +-- 기술 제약 --> PRD/BS-xx 대안 명세 PR + 원본 취소선
  |     +-- 대안 기반 TC 재작성 --> 재실행
  |
  +-- BLOCK(BS 미작성) --> Phase Gate 산정 제외
  |     +-- BS 완성 후 활성화
  |
  +-- 환경 문제 --> 환경 수정 --> 재실행
```

**무한 루프 방지**: 동일 TC에 대해 **3회 재QA** 후에도 **FAIL**이면 에스컬레이션 (Lead → Architect 리뷰). 에스컬레이션 후에도 미해소 시 해당 TC를 Phase Gate에서 **Known Issue로 격리** (Critical 제외 — Critical은 반드시 해소).

### 15.5 추적성 체인

양방향 추적 3단 체인:

```
Foundation PRD 섹션 <-> Feature Catalog ID <-> BS-xx 섹션 <-> Test Case ID <-> QA 결과
```

- Feature Catalog ID → BS-xx 매핑 테이블은 부록 A에 포함
- 각 TC FAIL 리포트에 "영향 문서" 필드 필수 → 역추적 1단계로 완결

**Phase Gate 차단 조건**:

| 기준 | 조건 |
|------|------|
| Critical (기획 결함/미정의/기술 제약) | **0건** 이어야 통과 |
| Major | ≤ 3건 (Known Issue 등록 + 다음 Phase 초반 해소 약속) |
| Minor | Phase Gate 차단 대상 아님 |
| BLOCK (BS 미작성) | Phase Gate 산정 **제외** (BS 완성 시 다음 Phase에서 검증) |

### 15.6 선행 조건

| 선행 조건 | 영향 | 처리 |
|----------|------|------|
| **BS-07 (Overlay Graphics)** 미작성 | §10 출력 QA의 TC 전부 **BLOCK** | BS-07 완성 전까지 Phase Gate 제외 |
| 홀덤 외 게임 BS 미작성 | 해당 게임 TC 전부 **BLOCK** | BS-06-xx 완성 전까지 Phase Gate 제외 |
| 이 문서는 BS 작성과 병렬 진행 가능 | **BLOCK** TC는 BS 완성 시점에 활성화 | — |

---

## 16. 부록 A: Feature ID → TC ID + BS-xx 매핑

134개 feature (SRC-001~010 제외)의 TC ID 및 BS-xx 매핑. TC ID 형식: `TC-<FeatureID>-<case#>`

### Main Window (MW-001 ~ MW-010, SRC 제외)

| Feature ID | 기능명 | BS 참조 | TC 범위 | Phase |
|-----------|-------|--------|--------|:-----:|
| MW-001 | 게임 유형 선택 (22개 변형) | BS-02 | TC-MW-001-01 ~ 21 | 2 |
| MW-002 | 게임 시작/종료 | BS-02 | TC-MW-002-01 ~ 03 | 2 |
| MW-003 | 핸드 번호 표시 | BS-02 | TC-MW-003-01 ~ 02 | 2 |
| MW-004 | 접속 클라이언트 목록 | BS-02 | TC-MW-004-01 ~ 02 | 2 |
| MW-005 | RFID 연결 상태 (12대) | BS-04 | TC-MW-005-01 ~ 04 | 1 |
| MW-006 | 서버 IP/포트 표시 | BS-02 | TC-MW-006-01 | 2 |
| MW-007 | 라이선스 상태 | — | TC-MW-007-01 | — |
| MW-008 | 탭 네비게이션 (7개 탭) | BS-02 | TC-MW-008-01 ~ 08 | 2 |
| MW-009 | 로그 패널 | BS-02 | TC-MW-009-01 ~ 02 | 2 |
| MW-010 | 긴급 중지 | BS-02 | TC-MW-010-01 ~ 02 | 2 |

### Outputs (OUT-001 ~ OUT-012)

| Feature ID | 기능명 | BS 참조 | TC 범위 | Phase |
|-----------|-------|--------|--------|:-----:|
| OUT-001 | 그래픽 출력 | BS-07 | TC-OUT-001-01 ~ 08 | 2 |
| OUT-002 | NDI 출력 | BS-07 | TC-OUT-004-01 ~ 03 | 2 |
| OUT-003 | HDMI 출력 | BS-07 | TC-OUT-004-04 | 2 |
| OUT-004 | SDI 출력 | BS-07 | TC-OUT-004-05 | 3 |
| OUT-005 | 출력 해상도 설정 | BS-07 | TC-OUT-003-01 ~ 03 | 2 |
| OUT-006 | Security Delay 모드 | BS-07 | TC-OUT-005-01 ~ 02 | 2 |
| OUT-007 | 지연 시간 설정 | BS-07 | TC-PERF-001-01 ~ 03 | 2 |
| OUT-008 | 크로마키 출력 | BS-07 | TC-OUT-006-01 ~ 02 | 2 |
| OUT-009 | 출력 미리보기 | BS-07 | TC-OUT-007-01 ~ 02 | 2 |
| OUT-010 | Cross-GPU 출력 | BS-07 | TC-OUT-010-01 | 3 |
| OUT-011 | ATEM 스위처 연동 | BS-07 | TC-OUT-011-01 | 3 |
| OUT-012 | 녹화 | BS-07 | TC-OUT-012-01 | 3 |

### GFX1 — 게임 제어 (G1-001 ~ G1-024)

| Feature ID | 기능명 | BS 참조 | TC 범위 | Phase |
|-----------|-------|--------|--------|:-----:|
| G1-001 | 좌석 배치 | BS-06 | TC-G1-001-01 ~ 15 | 2 |
| G1-002 | 이름 표시 | BS-06 | TC-G1-002-01 ~ 16 | 2 |
| G1-003 | 칩 표시 | BS-06 | TC-G1-003-01 ~ 09 | 2 |
| G1-004 | 홀카드 표시 | BS-06 | TC-G1-004-01 ~ 09 | 2 |
| G1-005 | 팟 표시 | BS-06 | TC-G1-005-01 ~ 08 | 2 |
| G1-006 | 보드 카드 표시 | BS-06 | TC-G1-006-01 ~ 07 | 2 |
| G1-007 | 베팅 표시 | BS-06 | TC-G1-007-01 ~ 03 | 2 |
| G1-008 | 승률 표시 | BS-06 | TC-G1-008-01 ~ 08 | 2 |
| G1-009 | 핸드랭크 표시 | BS-06 | TC-G1-009-01 ~ 05 | 2 |
| G1-010 | 폴드 표시 | BS-06 | TC-G1-010-01 ~ 31 | 2 |
| G1-011 | 딜러 버튼 | BS-06 | TC-G1-011-01 ~ 03 | 2 |
| G1-012 | 블라인드 표시 | BS-06 | TC-G1-012-01 ~ 22 | 2 |
| G1-013 | All-in 표시 | BS-06 | TC-G1-013-01 ~ 30 | 2 |
| G1-014 | 수동 카드 입력 | BS-06 | TC-G1-014-01 ~ 13 | 2 |
| G1-015 | 핸드 번호 | BS-06 | TC-G1-015-01 ~ 04 | 2 |
| G1-016 | 사이드팟 표시 | BS-06 | TC-G1-016-01 ~ 03 | 3 |
| G1-017 | Rabbit Hunt | BS-06 | TC-G1-017-01 ~ 02 | 3 |
| G1-018 | Bounty 표시 | BS-06 | TC-G1-018-01 ~ 03 | 3 |
| G1-019 | 국기 표시 | BS-06 | TC-G1-019-01 ~ 02 | 3 |
| G1-020 | 단축키 | BS-06 | TC-G1-020-01 ~ 07 | 3 |
| G1-021 | Ante 표시 | BS-06 | TC-G1-021-01 ~ 02 | 3 |
| G1-022 | 애니메이션 | BS-06 | TC-G1-022-01 ~ 03 | 3 |
| G1-023 | Run It Twice | BS-06 | TC-G1-023-01 ~ 03 | 3 |
| G1-024 | 블라인드 타이머 | BS-06 | TC-G1-024-01 ~ 02 | 3 |

### GFX2 — 통계 (G2-001 ~ G2-013)

| Feature ID | 기능명 | BS 참조 | TC 범위 | Phase |
|-----------|-------|--------|--------|:-----:|
| G2-001 | VPIP | BS-06 | TC-G2-001-01 ~ 02 | 2 |
| G2-002 | PFR | BS-06 | TC-G2-002-01 ~ 02 | 2 |
| G2-003 | AF | BS-06 | TC-G2-003-01 ~ 02 | 2 |
| G2-004 | 핸드수 | BS-06 | TC-G2-004-01 ~ 02 | 2 |
| G2-005 | 프로필 | BS-06 | TC-G2-005-01 ~ 02 | 2 |
| G2-006 | 순위 | BS-06 | TC-G2-006-01 ~ 02 | 2 |
| G2-007 | 남은 인원 | BS-06 | TC-G2-007-01 ~ 02 | 2 |
| G2-008 | 상금 | BS-06 | TC-G2-008-01 ~ 02 | 2 |
| G2-009 | 초기화 | BS-06 | TC-G2-009-01 | 2 |
| G2-010 | 칩 그래프 | BS-06 | TC-G2-010-01 ~ 02 | 3 |
| G2-011 | Payout 표시 | BS-06 | TC-G2-011-01 ~ 02 | 3 |
| G2-012 | ICM 계산 | BS-06 | TC-G2-012-01 ~ 03 | 3 |
| G2-013 | 내보내기 | BS-06 | TC-G2-013-01 ~ 02 | 3 |

### GFX3 — 방송 연출 (G3-001 ~ G3-013)

| Feature ID | 기능명 | BS 참조 | TC 범위 | Phase |
|-----------|-------|--------|--------|:-----:|
| G3-001 | 하단 자막 | BS-07 | TC-G3-001-01 ~ 02 | 2 |
| G3-002 | 방송 제목 | BS-07 | TC-G3-002-01 ~ 02 | 2 |
| G3-003 | 티커 | BS-07 | TC-G3-003-01 ~ 02 | 3 |
| G3-004 | 스폰서 | BS-07 | TC-G3-004-01 ~ 02 | 3 |
| G3-005 | 오버레이 전환 | BS-07 | TC-G3-005-01 ~ 02 | 3 |
| G3-006 | 멀티레이어 | BS-07 | TC-G3-006-01 ~ 02 | 3 |
| G3-007 | 프리셋 | BS-07 | TC-G3-007-01 ~ 02 | 3 |
| G3-008 | 타이머 | BS-07 | TC-G3-008-01 ~ 02 | 3 |
| G3-009 | 오프닝 애니메이션 | BS-07 | TC-G3-009-01 ~ 02 | 3 |
| G3-010 | 엔딩 애니메이션 | BS-07 | TC-G3-010-01 ~ 02 | 3 |
| G3-011 | Twitch 채팅 | BS-07 | TC-G3-011-01 ~ 02 | 3 |
| G3-012 | PIP | BS-07 | TC-G3-012-01 ~ 02 | 3 |
| G3-013 | 커스텀 오버레이 | BS-07 | TC-G3-013-01 ~ 02 | 3 |

### System (SYS-001 ~ SYS-016)

| Feature ID | 기능명 | BS 참조 | TC 범위 | Phase |
|-----------|-------|--------|--------|:-----:|
| SYS-001 | 서버 포트 설정 | BS-03 | TC-SYS-001-01 ~ 04 | 1 |
| SYS-002 | 자동 탐색 | BS-03 | TC-SYS-002-01 ~ 02 | 2 |
| SYS-003 | 라이선스 | BS-03 | TC-SYS-003-01 ~ 02 | 2 |
| SYS-004 | 카드 인식 (12대) | BS-04 | TC-SYS-004-01 ~ 11 | 1 |
| SYS-005 | 상태 모니터 | BS-04 | TC-SYS-005-01 ~ 04 | 1 |
| SYS-006 | 카드 테스트 | BS-04 | TC-SYS-006-01 ~ 03 | 2 |
| SYS-007 | 네트워크 설정 | BS-03 | TC-SYS-007-01 ~ 02 | 2 |
| SYS-008 | 보안 통신 | BS-03 | TC-SYS-008-01 ~ 02 | 2 |
| SYS-009 | 출력 설정 | BS-07 | TC-SYS-009-01 ~ 02 | 2 |
| SYS-010 | 스킨 경로 | BS-07 | TC-SYS-010-01 ~ 02 | 2 |
| SYS-011 | 로그 설정 | BS-03 | TC-SYS-011-01 ~ 02 | 3 |
| SYS-012 | Master/Slave | BS-03 | TC-SYS-012-01 ~ 03 | 3 |
| SYS-013 | 단축키 설정 | BS-03 | TC-SYS-013-01 ~ 02 | 3 |
| SYS-014 | 성능 설정 | BS-03 | TC-SYS-014-01 ~ 02 | 3 |
| SYS-015 | 언어 설정 | BS-03 | TC-SYS-015-01 ~ 02 | 3 |
| SYS-016 | 백업/복원 | BS-03 | TC-SYS-016-01 ~ 03 | 3 |

### Skin Editor (SK-001 ~ SK-016)

| Feature ID | 기능명 | BS 참조 | TC 범위 | Phase |
|-----------|-------|--------|--------|:-----:|
| SK-001 | 스킨 로드 | BS-07 | TC-SK-001-01 ~ 02 | 2 |
| SK-002 | 스킨 저장 (AES) | BS-07 | TC-SK-002-01 ~ 03 | 2 |
| SK-003 | 신규 생성 | BS-07 | TC-SK-003-01 ~ 02 | 2 |
| SK-004 | 미리보기 | BS-07 | TC-SK-004-01 ~ 02 | 2 |
| SK-005 | 배경 설정 | BS-07 | TC-SK-005-01 ~ 02 | 2 |
| SK-006 | 카드 디자인 | BS-07 | TC-SK-006-01 ~ 02 | 3 |
| SK-007 | 좌석 위치 | BS-07 | TC-SK-007-01 ~ 02 | 3 |
| SK-008 | 폰트 설정 | BS-07 | TC-SK-008-01 ~ 02 | 3 |
| SK-009 | 색상 팔레트 | BS-07 | TC-SK-009-01 ~ 02 | 3 |
| SK-010 | Undo/Redo | BS-07 | TC-SK-010-01 ~ 03 | 3 |
| SK-011 | 이미지 가져오기 | BS-07 | TC-SK-011-01 ~ 02 | 3 |
| SK-012 | 애니메이션 속도 | BS-07 | TC-SK-012-01 ~ 02 | 3 |
| SK-013 | 투명도 | BS-07 | TC-SK-013-01 ~ 02 | 3 |
| SK-014 | 레이어 관리 | BS-07 | TC-SK-014-01 ~ 02 | 3 |
| SK-015 | 복사 | BS-07 | TC-SK-015-01 ~ 02 | 3 |
| SK-016 | 내보내기 | BS-07 | TC-SK-016-01 ~ 02 | 3 |

### Graphic Editor — Board (GEB-001 ~ GEB-015)

| Feature ID | 기능명 | BS 참조 | TC 범위 | Phase |
|-----------|-------|--------|--------|:-----:|
| GEB-001 | 트리뷰 | BS-07 | TC-GEB-001-01 ~ 03 | 2 |
| GEB-002 | 드래그 | BS-07 | TC-GEB-002-01 ~ 02 | 2 |
| GEB-003 | 크기 조절 | BS-07 | TC-GEB-003-01 ~ 02 | 2 |
| GEB-004 | 속성 편집 | BS-07 | TC-GEB-004-01 ~ 03 | 2 |
| GEB-005 | 좌표 설정 | BS-07 | TC-GEB-005-01 ~ 02 | 2 |
| GEB-006 | 이미지/텍스트 배치 | BS-07 | TC-GEB-006-01 ~ 03 | 2 |
| GEB-007 | Pip 배치 | BS-07 | TC-GEB-007-01 ~ 02 | 2 |
| GEB-008 | 커뮤니티 영역 | BS-07 | TC-GEB-008-01 ~ 03 | 2 |
| GEB-009 | 팟 영역 | BS-07 | TC-GEB-009-01 ~ 02 | 3 |
| GEB-010 | 딜러 영역 | BS-07 | TC-GEB-010-01 ~ 02 | 3 |
| GEB-011 | z-order | BS-07 | TC-GEB-011-01 ~ 02 | 3 |
| GEB-012 | 가시성 | BS-07 | TC-GEB-012-01 ~ 02 | 3 |
| GEB-013 | Undo | BS-07 | TC-GEB-013-01 ~ 03 | 3 |
| GEB-014 | 캔버스 크기 | BS-07 | TC-GEB-014-01 ~ 02 | 3 |
| GEB-015 | 내보내기 | BS-07 | TC-GEB-015-01 ~ 02 | 3 |

### Graphic Editor — Player (GEP-001 ~ GEP-015)

| Feature ID | 기능명 | BS 참조 | TC 범위 | Phase |
|-----------|-------|--------|--------|:-----:|
| GEP-001 | 이름 표시 | BS-07 | TC-GEP-001-01 ~ 02 | 2 |
| GEP-002 | 칩 표시 | BS-07 | TC-GEP-002-01 ~ 02 | 2 |
| GEP-003 | 홀카드 (2~6장) | BS-07 | TC-GEP-003-01 ~ 04 | 2 |
| GEP-004 | 베팅 | BS-07 | TC-GEP-004-01 ~ 03 | 2 |
| GEP-005 | 액션 표시 | BS-07 | TC-GEP-005-01 ~ 02 | 2 |
| GEP-006 | 승률 | BS-07 | TC-GEP-006-01 ~ 03 | 2 |
| GEP-007 | 핸드랭크 | BS-07 | TC-GEP-007-01 ~ 02 | 2 |
| GEP-008 | Fold 표시 | BS-07 | TC-GEP-008-01 ~ 02 | 2 |
| GEP-009 | 승자 표시 | BS-07 | TC-GEP-009-01 ~ 02 | 3 |
| GEP-010 | 배경 | BS-07 | TC-GEP-010-01 ~ 02 | 3 |
| GEP-011 | 카드 애니메이션 | BS-07 | TC-GEP-011-01 ~ 02 | 3 |
| GEP-012 | 칩 애니메이션 | BS-07 | TC-GEP-012-01 ~ 02 | 3 |
| GEP-013 | Stud 레이아웃 | BS-07 | TC-GEP-013-01 ~ 03 | 3 |
| GEP-014 | Draw 레이아웃 | BS-07 | TC-GEP-014-01 ~ 03 | 3 |
| GEP-015 | Hi-Lo 분할 | BS-07 | TC-GEP-015-01 ~ 03 | 3 |

### 요약 통계

| 프리픽스 | 기능 수 | QA 대상 | Phase 1 | Phase 2 | Phase 3+ |
|---------|:-------:|:-------:|:-------:|:-------:|:--------:|
| MW | 10 | 10 | 1 | 8 | — |
| SRC | 10 | **제외** | — | — | — |
| OUT | 12 | 12 | — | 9 | 3 |
| G1 | 24 | 24 | — | 15 | 9 |
| G2 | 13 | 13 | — | 9 | 4 |
| G3 | 13 | 13 | — | 2 | 11 |
| SYS | 16 | 16 | 3 | 7 | 6 |
| SK | 16 | 16 | — | 5 | 11 |
| GEB | 15 | 15 | — | 8 | 7 |
| GEP | 15 | 15 | — | 8 | 7 |
| **합계** | **144** | **134** | **4** | **71** | **59** |

---

## 17. 부록 B: 용어 & 상태값 레지스트리

### 핵심 FSM 상태값

| FSM | 상태값 |
|-----|--------|
| TableFSM | **EMPTY** → **SETUP** → **LIVE** → **PAUSED** → **CLOSED** |
| DeckFSM | **UNREGISTERED** → **REGISTERING** → **REGISTERED** → **PARTIAL** → **MOCK** |
| 홀덤 FSM | **IDLE** → **SETUP_HAND** → **PRE_FLOP** → **FLOP** → **TURN** → **RIVER** → **SHOWDOWN** → **RUN_IT_MULTIPLE** → **HAND_COMPLETE** |

### 핵심 Enum

| Enum | 값 |
|------|-----|
| `PlayerStatus` | **active**, **folded**, **allin**, **eliminated**, **sitting_out** |
| `ante_type` | `std`, `button`, `bb`, `bb_bb1st`, `live`, `tb`, `tb_tb1st` (7종) |
| `bet_structure` | `NL` (0), `FL` (1), `PL` (2) (3종) |
| `game_type` | `Cash` (0), `Regular` (1), `Bounty` (2), `Mystery` (3), `Flip` (4), `Shootout` (5), `Satellite` (6), `SNG` (7) (8종) |

### 22종 게임 분류

| 계열 | 게임 (22종) |
|------|-----------|
| Flop (12) | Texas Hold'em, 6+ Hold'em (S>T), 6+ Hold'em (T>S), Pineapple, Omaha, Omaha Hi-Lo, 5-Card Omaha, 5-Card Omaha Hi-Lo, 6-Card Omaha, 6-Card Omaha Hi-Lo, Courchevel, Courchevel Hi-Lo |
| Draw (7) | 5-Card Draw, 2-7 Single Draw, 2-7 Triple Draw, A-5 Triple Draw, Badugi, Badeucy, Badacey |
| Stud (3) | 7-Card Stud, 7-Card Stud Hi-Lo, Razz |

### TC 결과 상태

| 상태 | 정의 |
|------|------|
| **PASS** | 기대 동작과 일치 |
| **FAIL** | 기대 동작과 불일치 (근본 원인 5분류 필수) |
| **BLOCK** | 선행 조건 미충족으로 실행 불가 |
| **SKIP** | 해당 Phase 범위 외 |

### 심각도

| 심각도 | 정의 |
|--------|------|
| **Critical** | 핵심 기능 완전 불가, 데이터 손실 |
| **Major** | 핵심 기능 부분 불가, 우회 가능 |
| **Minor** | 비핵심 기능, UI/UX 결함 |

---

<!-- END OF DOCUMENT -->
