---
doc_type: "plan"
doc_id: "EBS-CONSOLE-V1-PLAN"
version: "3.0.0"
status: "approved"
owner: "BRACELET STUDIO"
created: "2026-02-23"
last_updated: "2026-03-31"
phase: "phase-1"
priority: "critical"

depends_on:
  - "docs/00-prd/ebs-console.prd.md"
  - "docs/01_PokerGFX_Analysis/ebs-console-feature-triage.md"
---

# EBS v1.0 개발 계획서

> **목표**: EBS v1.0 — Hold'em 1종으로 8시간 연속 라이브 방송 가능한 MVP. **2027년 1월 런칭 목표.**
> **기술 스택**: Flutter + Dart + Rive (v33.0.0 전환)
> **화면 구조**: Lobby + Console + Command Center (3화면)

---

## 1. 전제 조건

v1.0 개발을 시작하기 전 충족되어야 하는 조건:

| 전제 조건 | 상태 | 담당 |
|----------|:----:|------|
| RFID 업체 선정 (Phase 0) | 진행 중 | 운영팀 |
| POC 하드웨어 확보 (ST25R3911B-DISCO) | 미착수 | 기술팀 |
| PokerGFX 기능 분석 완료 | **완료** | Phase 0 |
| EBS console 기획서 확정 | **완료** | Phase 0 |
| 개발 환경 설정 | 미착수 | 기술팀 |

**v1.0 RFID 정책**: RFID 미연결 시 수동 카드 입력 폴백으로 운영. v1.0은 RFID 없이도 동작해야 한다.

---

## 2. v1.0 개발 범위 (~45개 기능)

| 카테고리 | v1.0 개수 | 핵심 목적 |
|----------|:---------:|---------|
| Command Center | 16 | 실시간 게임 커맨드 입력 — 액션/베팅 (TAG HAND, CHOP, RUN IT 2x 제외) |
| Lobby > Setup | 10 | 테이블 설정, 게임 유형, 플레이어/스택 입력 |
| Viewer Overlay | 10 | NDI 방송 오버레이 출력 |
| Security | 3 | Trustless/Realtime Mode, 딜레이 |
| GFX Console | 3 | 기본 현황 (플레이어 수, 스택) |
| Hand History | 1 | 현재 세션 핸드 상세 뷰 |
| Server 관리 | 2 | NDI 출력, 레이아웃 |
| **합계** | **~45** | |

---

## 3. 6-Layer 개발 계획

65개 기능을 의존성 순서로 6개 레이어로 분류. 각 레이어는 이전 레이어 완료 후 시작.

### Layer 1: 인프라 (6주 예상)

> 방송 시작 전 필수 기반 구조. 다른 모든 레이어가 이에 의존.

| 기능 ID | 기능명 | 설명 |
|---------|-------|------|
| SEC-009 | WebSocket 암호화 | Server↔Frontend WSS(TLS) 기반 |
| SV-006 | Live/Delay 이중 출력 | 출력 파이프라인 기반 |
| SV-007 | Secure Delay 설정 | 딜레이 버퍼 구조 |
| SV-008 | Video Size / Frame Rate | 출력 해상도/프레임레이트 |

**추가 인프라 작업 (기능 ID 외):**
- DB 스키마: cards, hands, sessions, players 테이블
- Serial 통신 레이어: USB Serial 수신 → WebSocket 브로드캐스트
- OBS Browser Source 연동 기반 (HTTP 서버)

**병렬 개발 가능:** 서버 코드와 프론트엔드 기반 UI 동시 진행

---

### Layer 2: 게임 설정 (4주 예상)

> 방송 전 설정 화면. Pre-Start Setup 완성.

| 기능 ID | 기능명 | 비고 |
|---------|-------|------|
| PS-001 | Event Name 입력 | |
| PS-002 | Game Type 선택 | HOLDEM / PLO4 / PLO5 / SHORT DECK |
| PS-003 | Min Chip 설정 | |
| PS-004 | 플레이어 이름 입력 | 자동완성 지원 |
| PS-005 | 칩 스택 입력 | 숫자 검증 포함 |
| PS-006 | 포지션 할당 | Dealer 버튼 위치 |
| PS-007 | RFID 카드 감지 상태 | 수동 입력 폴백 포함 |
| PS-008 | Ante/SB/BB 설정 | |
| PS-010 | Dealer 위치 조정 | 드래그 앤 드롭 |
| PS-012 | TRACK THE ACTION 버튼 | 화면 전환 트리거 |

**결과물:** Lobby 1단계(직접 수정 모드)의 Setup 완료 후 Command Center로 진입 가능한 화면. 2단계(WSOPLIVE 연동, 대회→이벤트→테이블 3-depth)는 Phase 3+에서 구현.

---

### Layer 3: Command Center (8주 예상)

> v1.0 핵심. Command Center의 실시간 게임 커맨드 입력.

#### 3.1 게임 상태 + 좌석 (Layer 3a)

| 기능 ID | 기능명 | 의존 |
|---------|-------|------|
| AT-005 | 게임 타입 선택 | Layer 2 완료 |
| AT-006 | Blinds 표시 | Layer 2 완료 |
| AT-007 | Hand 번호 추적 | |
| AT-008 | 10인 좌석 레이아웃 | |
| AT-009 | 플레이어 상태 표시 | AT-008 |
| AT-010 | Action-on 하이라이트 | AT-009 |
| AT-011 | 포지션 표시 | AT-008 |

#### 3.2 액션 입력 (Layer 3b)

| 기능 ID | 기능명 | 의존 |
|---------|-------|------|
| AT-012 | 기본 액션 버튼 | AT-009 |
| AT-013 | UNDO 버튼 | AT-012 |
| AT-014 | 키보드 단축키 | AT-012 |
| AT-015 | 베팅 금액 직접 입력 | AT-012 |
| AT-016 | +/- 조정 버튼 | AT-015 |
| AT-017 | Quick Bet 버튼 | AT-015 |
| AT-018 | Min/Max 범위 표시 | AT-015 |
| AT-021 | HIDE GFX | |
| AT-023 | ADJUST STACK | AT-009 |

#### 3.3 보드 카드 (Layer 3c)

| 기능 ID | 기능명 | 의존 |
|---------|-------|------|
| AT-019 | Community Cards 표시 | |
| AT-020 | 보드 카드 업데이트 | AT-019, RFID or 수동 |

---

### Layer 4: 오버레이 출력 (6주 예상)

> OBS Browser Source로 방송에 송출되는 시청자용 오버레이.

#### 4.1 플레이어 정보 오버레이

| 기능 ID | 기능명 | 의존 |
|---------|-------|------|
| VO-002 | Blinds 정보 | Layer 3a |
| VO-003 | Chip Counts | Layer 3a |
| VO-005 | Hole Cards 표시 | AT-020 |
| VO-006 | Player Name + Stack | Layer 2, 3a |
| VO-007 | 마지막 액션 표시 | AT-012 |
| VO-009 | Board Cards | AT-019, AT-020 |
| VO-010 | Pot Display | AT-015 |
| VO-012 | Street 표시 | AT-019 |
| VO-013 | To Act 표시 | AT-010 |
| VO-014 | Folded Player 스타일 | AT-009 |

#### 4.2 이벤트 정보 오버레이

| 기능 ID | 기능명 | 의존 |
|---------|-------|------|
| VO-001 | Event Logo | Layer 2 (PS-001) |
| VO-011 | Event Info | Layer 2 (PS-001) |

#### 4.3 GFX 레이아웃 설정

| 기능 ID | 기능명 | 의존 |
|---------|-------|------|
| SV-005 | Chroma Key | Layer 1 |
| SV-012 | Board Position | Layer 1 |
| SV-013 | Player Layout | Layer 1 |
| SV-017 | Action Clock | Layer 3b |
| SV-019 | BB 표시 모드 | VO-003 |
| SV-020 | 통화 기호 설정 | VO-003 |

---

### Layer 5: 보안 + 딜레이 (4주 예상)

> Trustless/Realtime Mode 전환. 홀카드 딜레이 방송.

| 기능 ID | 기능명 | 의존 |
|---------|-------|------|
| SEC-001 | 30초 딜레이 버퍼링 | Layer 1 (SV-006, SV-007) |
| SEC-002 | 카운트다운 표시 | SEC-001 |
| SEC-003 | DB 조회 지연 | SEC-001 |
| SEC-004 | 즉시 카드 표시 | Layer 4 (VO-005) |
| SEC-005 | 모드 표시 | SEC-001, SEC-004 |
| SEC-010 | Trustless/Realtime 토글 | SEC-001, SEC-004 |

---

### Layer 6: 마무리 + 모니터링 (2주 예상)

> 상태 표시, 기본 현황 패널. Layer 1~5 이후 통합.

| 기능 ID | 기능명 | 의존 |
|---------|-------|------|
| AT-001 | Network 연결 상태 | Layer 1 |
| AT-002 | Table 연결 상태 | Layer 1 |
| AT-003 | Stream 상태 | OBS 연동 |
| AT-004 | Record 상태 | OBS 연동 |
| GC-013 | Total Players | Layer 2 |
| GC-014 | Remaining Players | Layer 3a |
| GC-015 | Average Stack | Layer 3a |
| ST-007 | Hands Played | AT-007 |
| HH-008 | 핸드 상세 뷰 | Layer 3 |

---

## 4. 마일스톤

| 마일스톤 | 완료 기준 | 목표 시기 |
|---------|---------|---------|
| **M0** — RIVE POC | 1080p 60fps RIVE 오버레이 렌더링 검증 | 2026년 4월 |
| **M1** — 인프라 완성 | WebSocket 서버 + DB + NDI 출력 기반 동작 | 2026년 5월 |
| **M2** — 설정 완성 | Pre-Start Setup 화면 + Hold'em FSM + 핸드 평가기 | 2026년 6월 |
| **M3** — Command Center | CC 코어 완성, 핸드 100회 자동 시뮬레이션 통과 | 2026년 8월 |
| **M4** — 방송 출력 | Viewer Overlay + 보안/딜레이 모드 동작 | 2026년 9월 |
| **M5** — QA | 8시간 연속 방송 시뮬레이션 + 실제 딜러 운용 테스트 | 2026년 11~12월 |
| **M6** — 런칭 | 홀덤 1종 프로덕션 배포 | **2027년 1월** |

**전체 예상 기간**: 39주 (2026년 4월 ~ 2027년 1월)
**크리티컬 패스**: ~28주 (QA 4주 포함), **버퍼**: ~11주

---

## 5. 기술 스택

| 레이어 | 결정 | 비고 |
|-------|------|------|
| Frontend | **Flutter + Dart** | Lobby + Console + Command Center + Overlay |
| Backend | Python FastAPI | WebSocket + REST API |
| 렌더링 | **RIVE (Flutter 네이티브)** | .riv 파일 Flutter Rive 패키지로 로드, 스킨 에디터 1단계 |
| 빌드 타겟 | Windows Desktop + Web + iPad | 크로스 플랫폼 단일 코드베이스 |
| 출력 | **NDI + ATEM 스위처** | 외부 연동 도구 상세는 별도 결정 |
| DB | 미정 | 별도 기술 결정 문서에서 확정 |
| RFID | ST25R3911B + ESP32 | 수동 입력 폴백 = 1급 기능 |

> 렌더링은 ADR-005에 의해 RIVE로 확정. v33.0.0에서 React→Flutter 전환. 스킨 에디터 1단계는 Rive Editor 외부 활용.

---

## 6. 리스크

| 리스크 | 가능성 | 영향 | 완화 방법 |
|-------|:----:|:----:|---------|
| RFID 업체 선정 지연 | 중 | 중 | v1.0은 수동 입력 폴백으로 RFID 없이도 진행 |
| 기술 스택 결정 지연 | 저 | 고 | Phase 0 종료 전 기술 결정 문서 작성 |
| 65개 기능 범위 크리프 | 중 | 중 | 트리아지 문서가 배제 기준 역할, 변경 시 PRD 개정 필요 |
| Layer 3 복잡도 과소평가 | 중 | 고 | 게임 규칙/엣지케이스 상세 명세 사전 작성 |
| OBS Browser Source 호환성 | 저 | 중 | 사전 POC로 OBS 연동 방식 확인 |

---

## 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 3.1.0 | 2026-03-31 | Lobby 2단계 개발 전략 추가 (1단계 직접 수정 / 2단계 WSOPLIVE 3-depth), PRD v33.1.0 동기화 |
| 3.0.0 | 2026-03-31 | Flutter/Rive 전환, Action Tracker→Command Center 이름 변경, Pre-Start Setup→Lobby > Setup 이관, 3화면 구조(Lobby+Console+CC) 반영, PRD v33.0.0 동기화 |
| 2.0.0 | 2026-03-27 | 런칭 타임라인 확정 (2027-01), 기술 스택 확정 (RIVE/NDI/FastAPI), 기능 범위 65→~45 축소, 마일스톤 날짜 지정 |
| 1.0.0 | 2026-02-23 | 최초 작성 (ebs-console.prd.md 기반) |

---
**Version**: 2.0.0 | **Updated**: 2026-03-27
