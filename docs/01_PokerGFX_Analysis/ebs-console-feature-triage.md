---
doc_type: "triage"
version: "2.0.0"
status: "draft"
created: "2026-02-23"
updated: "2026-03-01"
---

# EBS console 기능 트리아지

> **BRACELET STUDIO** | EBS Project

## 개요

EBS console은 PokerGFX를 대체하는 방송 프로덕션 통제 소프트웨어다. 기존의 "149개 전부 구현" 접근을 버리고, Keep/Drop/Defer 분류로 현실적인 개발 범위를 확정한다. 트리아지 기준은 세 가지다: ①이 기능 없이 라이브 방송 가능한가(NO → v1.0 Keep), ②다른 도구(OBS, 수동)로 대체 가능한가(NO → v1.0 Keep), ③WSOP LIVE DB/RFID 인프라가 전제 조건인가(YES → v3.0 Defer).

### 분류 기준 상세

| 분류 | 조건 | 목표 |
|------|------|------|
| **v1.0 Keep** | 방송 필수 / 대체 불가 / RFID 없이도 작동 | Broadcast Ready |
| **v2.0 Defer** | 방송 가능하나 품질 향상 / 통계·분석 / 커스터마이징 | Operational Excellence |
| **v3.0 Defer** | RFID 인프라 또는 WSOP LIVE DB 전제 | EBS Native |
| **Drop** | 해설자 기능 / 외부 SNS 연동 / 편집 워크플로우 | 배제 |

### 버전 목표

| 버전 | 목표 | 핵심 가치 |
|------|------|----------|
| v1.0 Broadcast Ready | EBS console로 라이브 방송 즉시 가능 | 최소 필수 기능으로 실전 운영 |
| v2.0 Operational Excellence | 통계·분석·방송 품질 고도화 | 운영 완성도 확보 |
| v3.0 EBS Native | PokerGFX에 없는 EBS 고유 기능 구현 | 인프라 통합 및 자동화 |

## 트리아지 결과 요약

| 카테고리 | 전체 | v1.0 Keep | v2.0 Defer | v3.0 Defer | Drop |
|----------|:----:|:---------:|:----------:|:----------:|:----:|
| Action Tracker | 26 | 22 | 4 | 0 | 0 |
| Pre-Start Setup | 13 | 10 | 0 | 3 | 0 |
| Viewer Overlay | 14 | 10 | 4 | 0 | 0 |
| GFX Console | 25 | 3 | 18 | 2 | 3 |
| Security | 11 | 7 | 3 | 1 | 0 |
| Equity & Stats | 19 | 1 | 15 | 0 | 3 |
| Hand History | 11 | 1 | 8 | 0 | 2 |
| Server 관리 | 30 | 14 | 3 | 2 | 11 |
| **합계** | **149** | **68** | **55** | **8** | **19** |

> v1.0 목표 범위: ~55-65개. 실제 결정: 68개 (방송 필수 기능 + PRD-0004 v22.0.0 복원 3개 포함, overlay Drop 반영)

## 기능별 트리아지 결정

### 1. Action Tracker (26개)

| ID | 기능 | 결정 | 버전 | 근거 |
|----|------|:----:|:----:|------|
| AT-001 | Network 연결 상태 | Keep | v1.0 | 서버 연결 단절 시 방송 불가 — 대체 수단 없음 |
| AT-002 | Table 연결 상태 | Keep | v1.0 | RFID 테이블 연결 감시 — 방송 운영 필수 |
| AT-003 | Stream 상태 | Keep | v1.0 | OBS 스트림 연결 상태 확인 — 방송 중단 감지 필수 |
| AT-004 | Record 상태 | Keep | v1.0 | 녹화 여부 확인 — 방송 운영 기본 정보 |
| AT-005 | 게임 타입 선택 | Keep | v1.0 | HOLDEM/PLO 선택 없이 방송 시작 불가 |
| AT-006 | Blinds 표시 | Keep | v1.0 | SB/BB 정보 없으면 오버레이 데이터 불완전 |
| AT-007 | Hand 번호 추적 | Keep | v1.0 | 핸드 식별 기준 — 자동 증가, 수동 조정 |
| AT-008 | 10인 좌석 레이아웃 | Keep | v1.0 | 포커 테이블 핵심 UI — 이것 없이 액션 추적 불가 |
| AT-009 | 플레이어 상태 표시 | Keep | v1.0 | Active/Folded 상태 없으면 오버레이 연출 불가 |
| AT-010 | Action-on 하이라이트 | Keep | v1.0 | 현재 액션 차례 강조 — 방송 연출 필수 |
| AT-011 | 포지션 표시 | Keep | v1.0 | D/SB/BB 뱃지 — 포커 방송 기본 정보 |
| AT-012 | 기본 액션 버튼 | Keep | v1.0 | FOLD/CHECK/CALL/BET/RAISE/ALL-IN — 없으면 트래킹 불가 |
| AT-013 | UNDO 버튼 | Keep | v1.0 | 운영 오입력 복구 — 라이브에서 최대 5단계 필수 |
| AT-014 | 키보드 단축키 | Keep | v1.0 | 고속 방송 운영에 필수 — 마우스 의존 제거 |
| AT-015 | 베팅 금액 직접 입력 | Keep | v1.0 | 정확한 금액 입력 없으면 팟 계산 오류 |
| AT-016 | +/- 조정 버튼 | Keep | v1.0 | Min Chip 단위 조정 — 빠른 베팅 입력에 필요 |
| AT-017 | Quick Bet 버튼 | Keep | v1.0 | MIN/POT/ALL-IN 프리셋 — 운영 속도 필수 |
| AT-018 | Min/Max 범위 표시 | Keep | v1.0 | 베팅 합법성 검증 — 운영 오류 방지 |
| AT-019 | Community Cards 표시 | Keep | v1.0 | Flop/Turn/River 보드 영역 — 오버레이 핵심 |
| AT-020 | 보드 카드 업데이트 | Keep | v1.0 | RFID 자동 또는 수동 선택 — RFID 미연결 시 수동 입력 폴백으로 v1.0 구현 |
| AT-021 | HIDE GFX | Keep | v1.0 | 오버레이 일시 숨김 — 연출 제어 필수 |
| AT-022 | TAG HAND | Defer | v2.0 | Hand History 시스템 전제 — v2.0에서 HH와 함께 구현 |
| AT-023 | ADJUST STACK | Keep | v1.0 | 칩 스택 수동 조정 — 재버밍, 카운트 오류 보정 필수 |
| AT-024 | CHOP | Defer | v2.0 | 팟 분할 처리 — 기본 운영에서 드문 케이스, OBS 자막으로 임시 대체 가능 |
| AT-025 | RUN IT 2x | Defer | v2.0 | Run It Twice — 방송 운영에서 빈도 낮음, v2.0에서 확장 |
| AT-026 | MISS DEAL | Defer | v2.0 | 미스딜 처리 — 수동으로 핸드 취소 후 재시작으로 대체 가능 |

### 2. Pre-Start Setup (13개)

| ID | 기능 | 결정 | 버전 | 근거 |
|----|------|:----:|:----:|------|
| PS-001 | Event Name 입력 | Keep | v1.0 | 이벤트 이름 없으면 오버레이 표시 불완전 |
| PS-002 | Game Type 선택 | Keep | v1.0 | 게임 규칙 선택 없이 방송 시작 불가 |
| PS-003 | Min Chip 설정 | Keep | v1.0 | 베팅 단위 기준 없으면 팟 계산 오류 |
| PS-004 | 플레이어 이름 입력 | Keep | v1.0 | 오버레이에 이름 표시 — 방송 필수 |
| PS-005 | 칩 스택 입력 | Keep | v1.0 | 초기 스택 없으면 오버레이 칩카운트 불가 |
| PS-006 | 포지션 할당 | Keep | v1.0 | Dealer 버튼 위치 없으면 SB/BB 계산 불가 |
| PS-007 | RFID 카드 감지 상태 | Defer | v3.0 | RFID 하드웨어 전제 — v1.0에서는 수동 입력 폴백으로 대체 |
| PS-008 | Ante/SB/BB 설정 | Keep | v1.0 | 블라인드 금액 없으면 오버레이 표시 불가 |
| PS-009 | Straddle 추가 | Keep | v1.0 | 수동 설정 기반이면 v1.0 구현 가능 — 블라인드 구조 다양성 지원 |
| PS-010 | Dealer 위치 조정 | Keep | v1.0 | 드래그 앤 드롭 딜러 이동 — 게임 시작 필수 조작 |
| PS-011 | Board Count 선택 | Defer | v3.0 | SINGLE/DOUBLE BOARD — Run It Twice 기본 설정은 RFID 기반 다중 보드 전제 |
| PS-012 | TRACK THE ACTION 버튼 | Keep | v1.0 | 설정 완료 후 추적 시작 — 없으면 시작 불가 |
| PS-013 | AUTO 모드 토글 | Defer | v3.0 | RFID 자동 트래킹 — RFID 인프라 전제 |

### 3. Viewer Overlay (14개)

| ID | 기능 | 결정 | 버전 | 근거 |
|----|------|:----:|:----:|------|
| VO-001 | Event Logo | Keep | v1.0 | 로고 표시는 방송 브랜딩 필수 |
| VO-002 | Blinds 정보 | Keep | v1.0 | 블라인드 정보 없으면 오버레이 핵심 누락 |
| VO-003 | Chip Counts | Keep | v1.0 | 칩카운트 없으면 포커 방송 불가 |
| VO-004 | Broadcaster Logo | Defer | v2.0 | 브랜딩 요소 — 없어도 방송 가능 |
| VO-005 | Hole Cards 표시 | Keep | v1.0 | 홀카드 표시 — 포커 방송 핵심 |
| VO-006 | Player Name + Stack | Keep | v1.0 | 이름+스택 오버레이 — 방송 기본 |
| VO-007 | 마지막 액션 표시 | Keep | v1.0 | 액션 텍스트 표시 — 시청자 정보 필수 |
| VO-008 | Equity % 표시 | Defer | v2.0 | Equity 엔진 전제 — v2.0에서 함께 구현 |
| VO-009 | Board Cards | Keep | v1.0 | 보드 카드 표시 — 포커 방송 필수 |
| VO-010 | Pot Display | Keep | v1.0 | 팟 금액 없으면 방송 의미 상실 |
| VO-011 | Event Info | Defer | v2.0 | 부가 정보 바 — 없어도 방송 가능 |
| VO-012 | Street 표시 | Keep | v1.0 | PREFLOP/FLOP/TURN/RIVER — 방송 필수 |
| VO-013 | To Act 표시 | Keep | v1.0 | 현재 액션 플레이어 강조 — 방송 연출 필수 |
| VO-014 | Folded Player 스타일 | Defer | v2.0 | 반투명 처리 — 연출 향상이지만 없어도 방송 가능 |

### 4. GFX Console (25개)

| ID | 기능 | 결정 | 버전 | 근거 |
|----|------|:----:|:----:|------|
| GC-001 | VPIP 통계 | Defer | v2.0 | 통계 시스템 전제 — v2.0에서 GFX Console 완성 |
| GC-002 | PFR 통계 | Defer | v2.0 | 통계 시스템 전제 |
| GC-003 | AGR 통계 | Defer | v2.0 | 통계 시스템 전제 |
| GC-004 | WTSD 통계 | Defer | v2.0 | 통계 시스템 전제 |
| GC-005 | WIN 통계 | Defer | v2.0 | 통계 시스템 전제 |
| GC-006 | 3Bet 통계 | Defer | v2.0 | 고급 통계 |
| GC-007 | CBet 통계 | Defer | v2.0 | 고급 통계 |
| GC-008 | Fold to 3Bet | Defer | v2.0 | 고급 통계 |
| GC-009 | 순위 테이블 | Defer | v2.0 | 리더보드 — 통계 전제 |
| GC-010 | 순위 변동 그래프 | Defer | v2.0 | 그래프 시각화 — 통계 전제 |
| GC-011 | 정렬 옵션 | Defer | v2.0 | 리더보드 정렬 — 통계 전제 |
| GC-012 | 필터링 | Defer | v2.0 | 리더보드 필터 — 통계 전제 |
| GC-013 | Total Players | Keep | v1.0 | 방송 중 기본 현황 정보 — 별도 DB 없이 표시 가능 |
| GC-014 | Remaining Players | Keep | v1.0 | 남은 플레이어 수 — 방송 진행 상황 표시 |
| GC-015 | Average Stack | Keep | v1.0 | 평균 스택 — 방송 기본 통계 |
| GC-016 | Total Chips | Defer | v2.0 | 일관성 검증 — 운영 도구, 없어도 방송 가능 |
| GC-017 | LIVE Stats 토글 | Defer | v2.0 | 통계 오버레이 표시 — Stats 시스템 전제 |
| GC-018 | Export CSV | Defer | v2.0 | 통계 내보내기 — 통계 시스템 전제 |
| GC-019 | Print Report | Drop | — | 방송 운영과 무관한 오프라인 기능 — CSV Export로 충분 |
| GC-020 | Reset Stats | Defer | v2.0 | 통계 초기화 — 통계 시스템 전제 |
| GC-021 | 티커 메시지 | Defer | v3.0 | 스크롤 텍스트 — WSOP LIVE 연동 시 활용 |
| GC-022 | 시스템 상태 | Drop | — | CPU/메모리 모니터링 — 방송과 무관한 운영 도구 |
| GC-023 | Preview 창 | Defer | v2.0 | PIP 미리보기 — 방송 화질 향상 기능 |
| GC-024 | 다크/라이트 테마 | Drop | — | UI 편의 기능 — 개발 우선순위 낮음 *(N/A — UI에 사용자 대면 토글 없음, Skin 시스템 내부)* |
| GC-025 | 다국어 지원 | Defer | v3.0 | 국제화 — EBS Native 단계에서 구현 |

### 5. Security (11개)

| ID | 기능 | 결정 | 버전 | 근거 |
|----|------|:----:|:----:|------|
| SEC-001 | 30초 딜레이 버퍼링 | Keep | v1.0 | Trustless Mode 핵심 — 방송 보안 필수 |
| SEC-002 | 카운트다운 표시 | Keep | v1.0 | 딜레이 남은 시간 확인 — 운영자 필수 정보 |
| SEC-003 | DB 조회 지연 | Defer | v3.0 | WSOP LIVE DB 연동 전제 — EBS Native 단계 |
| SEC-004 | 즉시 카드 표시 | Keep | v1.0 | Realtime Mode 기본 — 방송 필수 |
| SEC-005 | 모드 표시 | Keep | v1.0 | LIVE/DELAYED 모드 상태 표시 — 운영자 필수 |
| SEC-006 | RFID 통신 암호화 | Defer | v2.0 | AES-128 암호화 — RFID 인프라 필요, 보안 강화 단계 |
| SEC-007 | Serial 암호화 | Defer | v2.0 | USB Serial 암호화 — 인프라 보안 강화 단계 |
| SEC-008 | DB 암호화 | Defer | v2.0 | 카드 매핑 암호화 — DB 인프라 전제 |
| SEC-009 | WebSocket 암호화 | Keep | v1.0 | WSS/TLS 기본 보안 — v1.0부터 필수 |
| SEC-010 | Trustless/Realtime 토글 | Keep | v1.0 | 원클릭 모드 전환 — 방송 운영 필수 |
| SEC-011 | Delay 시간 설정 | Keep | v1.0 | 딜레이 시간 조정 — Trustless Mode 운영 필수 |

### 6. Equity & Stats (19개)

| ID | 기능 | 결정 | 버전 | 근거 |
|----|------|:----:|:----:|------|
| EQ-001 | Preflop Equity | Defer | v2.0 | Equity 엔진 전제 — v2.0에서 통합 구현 |
| EQ-002 | Flop Equity | Defer | v2.0 | Equity 엔진 전제 |
| EQ-003 | Turn Equity | Defer | v2.0 | Equity 엔진 전제 |
| EQ-004 | River Equity | Defer | v2.0 | Equity 엔진 전제 |
| EQ-005 | Multi-way Equity | Defer | v2.0 | Equity 엔진 전제 |
| EQ-006 | Outs 계산 | Defer | v2.0 | Equity 엔진 전제 |
| EQ-007 | Outs 확률 표시 | Defer | v2.0 | Equity 엔진 전제 |
| EQ-008 | Win/Tie/Lose 표시 | Defer | v2.0 | Equity 엔진 전제 |
| EQ-009 | 핸드 레인지 인식 | Drop | — | 고급 AI 분석 기능 — EBS 범위 외, 복잡도 과다 |
| EQ-010 | PLO Equity | Defer | v2.0 | PLO 전용 Equity — Equity 엔진 전제 |
| EQ-011 | Short Deck Equity | Drop | — | 특수 게임타입 전용, 빈도 낮아 개발 ROI 불충분 |
| EQ-012 | All-in Equity 애니메이션 | Defer | v2.0 | 올인 Equity 애니메이션 — Equity 엔진 전제 |
| ST-001 | 세션 VPIP | Defer | v2.0 | 통계 시스템 전제 |
| ST-002 | 세션 PFR | Defer | v2.0 | 통계 시스템 전제 |
| ST-003 | 세션 AGR | Defer | v2.0 | 통계 시스템 전제 |
| ST-004 | 세션 WTSD | Defer | v2.0 | 통계 시스템 전제 |
| ST-005 | 누적 3Bet% | Drop | — | 고급 통계, 누적 집계 — P2 우선순위 최하위 |
| ST-006 | 누적 CBet% | Defer | v2.0 | 누적 C-Bet 비율 — 통계 시스템 전제 |
| ST-007 | Hands Played | Keep | v1.0 | 총 핸드 수는 방송 중 기본 현황 — 별도 엔진 없이 카운트 가능 |

### 7. Hand History (11개)

| ID | 기능 | 결정 | 버전 | 근거 |
|----|------|:----:|:----:|------|
| HH-001 | 핸드 목록 표시 | Keep | v1.0 | 최근 핸드 목록 — 방송 중 기본 참조용, 기본 저장만으로 가능 |
| HH-002 | 날짜 필터 | Defer | v2.0 | 고급 필터링 — Hand History 시스템 전제 |
| HH-003 | 플레이어 필터 | Defer | v2.0 | 플레이어별 필터 — Hand History 시스템 전제 |
| HH-004 | 팟 사이즈 필터 | Drop | — | 분석용 고급 필터 — v1.0 범위 외, 빈도 낮음 |
| HH-005 | 태그 필터 | Defer | v2.0 | TAG HAND 기능 전제 — v2.0에서 함께 구현 |
| HH-006 | 검색 | Defer | v2.0 | 텍스트 검색 — Hand History 시스템 전제 |
| HH-007 | 핸드 리플레이 | Defer | v2.0 | 리플레이 애니메이션 — Hand History 시스템 전제 |
| HH-008 | 핸드 상세 뷰 | Defer | v2.0 | 상세 뷰 — Hand History DB 전제 |
| HH-009 | Export 단일 핸드 | Defer | v2.0 | 내보내기 — Hand History 시스템 전제 |
| HH-010 | Export 전체 세션 | Defer | v2.0 | 전체 내보내기 — Hand History 시스템 전제 |
| HH-011 | 핸드 공유 | Drop | — | 공유 링크 생성 — 외부 서비스 연동 필요, EBS 범위 외 |

### 8. Server 관리 (30개)

| ID | 기능 | 결정 | 버전 | 근거 |
|----|------|:----:|:----:|------|
| SV-001 | 비디오 소스 관리 | Keep | v1.0 | 카메라/캡처 디바이스 관리 — 방송 입력 필수. 오디오 입력/싱크/레벨은 overlay Drop 확정 |
| SV-002 | Auto Camera Control | Drop | — | overlay annotation Drop 확정. 자동 카메라 전환 전체 배제 |
| SV-003 | ATEM Control | Defer | v2.0 | 외부 하드웨어 스위처 연동 — 고급 방송 장비 |
| SV-004 | Board Sync / Crossfade | Drop | — | overlay annotation Drop 확정. 보드 싱크/크로스페이드 배제 |
| SV-005 | Chroma Key | Keep | v1.0 | 크로마키 배경 — OBS 오버레이 연동 필수 |
| SV-006 | Live/Delay 이중 출력 | Keep | v1.0 | Live와 Delay 독립 출력 — 방송 필수 |
| SV-007 | Secure Delay 설정 | Drop | — | overlay annotation Drop 확정. Secure Delay 설정 UI 배제 (보안 모드 자체는 SEC에서 관리) |
| SV-008 | Video Size / Frame Rate | Keep | v1.0 | 해상도/프레임레이트 — 방송 출력 기본 설정 |
| SV-009 | Virtual Camera | Drop | — | overlay annotation Drop 확정. 가상 카메라 배제 |
| SV-010 | 9x16 Vertical | Keep | v1.0 | overlay annotation Keep 확인. 세로 모드 출력 복원 |
| SV-011 | Twitch 연동 | Drop | — | Twitch SNS 연동 — 방송 플랫폼 연동, EBS 범위 외 |
| SV-012 | Board Position | Keep | v1.0 | 보드 카드 위치 설정 — 오버레이 레이아웃 기본 |
| SV-013 | Player Layout | Keep | v1.0 | 플레이어 배치 방식 — 오버레이 레이아웃 기본 |
| SV-014 | Transition Animation | Keep | v1.0 | 등장/퇴장 애니메이션 — 방송 연출 필수 (PRD-0004 v22.0.0 복원) |
| SV-015 | Bounce Action Player | Keep | v1.0 | 바운스 시각 효과 — 방송 연출 필수 (PRD-0004 v22.0.0 복원) |
| SV-016 | 스폰서 로고 3슬롯 | Keep | v1.0 | 스폰서 로고 3슬롯 — 방송 브랜딩 필수 (PRD-0004 v22.0.0 복원) |
| SV-017 | Action Clock | Drop | — | overlay annotation Drop 확정. 액션 카운트다운 타이머 배제 |
| SV-018 | 영역별 Chipcount Precision | Keep | v1.0 | 수치 형식 설정 — 방송 표시 기본. Twitch Bot/Ticker/Strip precision은 overlay Drop 확정, Main/Board precision은 Keep 유지 |
| SV-019 | BB 표시 모드 | Keep | v1.0 | BB 배수 표시 — 시청자 이해도 향상, 방송 기본 |
| SV-020 | 통화 기호 설정 | Keep | v1.0 | 통화 기호 — 방송 지역화 기본 설정 |
| SV-021 | Commentary Mode | Drop | — | 해설자 기능 — 기존 배제 확정 (운영팀 미사용) |
| SV-022 | Picture In Picture (Commentary) | Drop | — | 해설자 PIP — 기존 배제 확정 |
| SV-023 | Register Deck | Defer | v3.0 | RFID 카드 덱 등록 — RFID 하드웨어 전제 |
| SV-024 | Calibrate | Defer | v3.0 | RFID 리더 캘리브레이션 — RFID 하드웨어 전제 |
| SV-025 | MultiGFX | Drop | — | overlay annotation Drop 확정. 다중 테이블 운영 배제 |
| SV-026 | Stream Deck 연동 | Drop | — | overlay annotation Drop 확정. Stream Deck 연동 배제 |
| SV-027 | Skin Editor | Defer | v2.0 | 방송 그래픽 편집기 — 커스터마이징 완성 단계 |
| SV-028 | Graphic Editor | Defer | v2.0 | 픽셀 단위 편집 — 커스터마이징 완성 단계 |
| SV-029 | 플레이어 사진/국기 | Keep | v1.0 | 프로필 사진 + 국기 — 방송 연출 기본 |
| SV-030 | Split Recording | Drop | — | 핸드별 분할 녹화 — 편집 워크플로우, 방송과 무관 |

## Drop 사유 상세

### 완전 배제 기능 (19개)

| ID | 기능 | 배제 사유 |
|----|------|----------|
| SV-002 | Auto Camera Control | 게임 상태 기반 자동 카메라 전환. overlay annotation Drop 확정 |
| SV-004 | Board Sync / Crossfade | 밀리초 보드 싱크/크로스페이드. overlay annotation Drop 확정 |
| SV-007 | Secure Delay 설정 | Outputs 탭 딜레이 시간 설정 UI. overlay annotation Drop 확정. 보안 모드 자체는 Security 카테고리에서 관리 |
| SV-009 | Virtual Camera | OBS 가상 카메라. overlay annotation Drop 확정 |
| SV-011 | Twitch 연동 | Twitch ChatBot, 채널 제목 설정 등 SNS 플랫폼 연동. EBS 관심사는 오버레이 생성이며, 방송 플랫폼 연동은 OBS/외부 도구에서 처리 |
| SV-017 | Action Clock | 원형 카운트다운 타이머. overlay annotation Drop 확정 |
| SV-021 | Commentary Mode | 기존 운영팀 미사용 확정. 해설자 원격 접속 기능 자체가 EBS 운영 방식과 불일치 |
| SV-022 | Picture In Picture (Commentary) | Commentary 기능 배제에 따른 연동 기능 자동 배제 |
| SV-025 | MultiGFX | 다중 테이블 운영. overlay annotation Drop 확정 |
| SV-026 | Stream Deck 연동 | Elgato Stream Deck 하드웨어 연동. overlay annotation Drop 확정 |
| SV-030 | Split Recording | 핸드별 분할 녹화는 영상 편집 워크플로우. EBS 방송 운영 관심사 외 범위 |
| GC-019 | Print Report | 방송 운영과 무관한 오프라인 기능. CSV Export로 충분 |
| GC-022 | 시스템 상태 | CPU/메모리/네트워크 사용률 모니터링. 방송 운영 관련성 낮고 OS 내장 도구로 대체 가능 |
| GC-024 | 다크/라이트 테마 | UI 편의 기능. 개발 복잡도 대비 방송 가치 없음. 단일 테마(다크)로 고정 *(N/A — Skin 시스템 내부 구현, 사용자 대면 테마 토글 UI 없음)* |
| EQ-009 | 핸드 레인지 인식 | 상대 레인지 기반 승률 계산은 AI/ML 분석 전제. EBS 범위 외 고급 기능 |
| EQ-011 | Short Deck Equity | 36장 덱 특수 게임타입 전용. 운영 빈도 낮아 개발 ROI 불충분 |
| ST-005 | 누적 3Bet% | 고급 통계 누적 집계. P2 우선순위로 개발 순위 최하위, v2.0 통계 완성 시 재검토 |
| HH-004 | 팟 사이즈 필터 | 분석용 고급 필터링. v1.0/v2.0에서 플레이어 필터, 태그 필터로 충분 |
| HH-011 | 핸드 공유 | 공유 링크 생성은 외부 서비스 연동 필요. EBS 단독 실행 범위 외 |

## v1.0 개발 대상 목록 (68개)

EBS console v1.0 Broadcast Ready에서 구현할 기능 전체 목록.

### Action Tracker (22개)

| ID | 기능 | 비고 |
|----|------|------|
| AT-001 | Network 연결 상태 | |
| AT-002 | Table 연결 상태 | |
| AT-003 | Stream 상태 | |
| AT-004 | Record 상태 | |
| AT-005 | 게임 타입 선택 | |
| AT-006 | Blinds 표시 | |
| AT-007 | Hand 번호 추적 | |
| AT-008 | 10인 좌석 레이아웃 | |
| AT-009 | 플레이어 상태 표시 | |
| AT-010 | Action-on 하이라이트 | |
| AT-011 | 포지션 표시 | |
| AT-012 | 기본 액션 버튼 | |
| AT-013 | UNDO 버튼 | |
| AT-014 | 키보드 단축키 | |
| AT-015 | 베팅 금액 직접 입력 | |
| AT-016 | +/- 조정 버튼 | |
| AT-017 | Quick Bet 버튼 | |
| AT-018 | Min/Max 범위 표시 | |
| AT-019 | Community Cards 표시 | |
| AT-020 | 보드 카드 업데이트 | RFID 미연결 시 수동 입력 폴백 구현 |
| AT-021 | HIDE GFX | |
| AT-023 | ADJUST STACK | |

### Pre-Start Setup (10개)

| ID | 기능 | 비고 |
|----|------|------|
| PS-001 | Event Name 입력 | |
| PS-002 | Game Type 선택 | |
| PS-003 | Min Chip 설정 | |
| PS-004 | 플레이어 이름 입력 | |
| PS-005 | 칩 스택 입력 | |
| PS-006 | 포지션 할당 | |
| PS-008 | Ante/SB/BB 설정 | |
| PS-009 | Straddle 추가 | |
| PS-010 | Dealer 위치 조정 | |
| PS-012 | TRACK THE ACTION 버튼 | |

### Viewer Overlay (10개)

| ID | 기능 | 비고 |
|----|------|------|
| VO-001 | Event Logo | |
| VO-002 | Blinds 정보 | |
| VO-003 | Chip Counts | |
| VO-005 | Hole Cards 표시 | |
| VO-006 | Player Name + Stack | |
| VO-007 | 마지막 액션 표시 | |
| VO-009 | Board Cards | |
| VO-010 | Pot Display | |
| VO-012 | Street 표시 | |
| VO-013 | To Act 표시 | |

### GFX Console (3개)

| ID | 기능 | 비고 |
|----|------|------|
| GC-013 | Total Players | |
| GC-014 | Remaining Players | |
| GC-015 | Average Stack | |

### Security (7개)

| ID | 기능 | 비고 |
|----|------|------|
| SEC-001 | 30초 딜레이 버퍼링 | |
| SEC-002 | 카운트다운 표시 | |
| SEC-004 | 즉시 카드 표시 | |
| SEC-005 | 모드 표시 | |
| SEC-009 | WebSocket 암호화 | |
| SEC-010 | Trustless/Realtime 토글 | |
| SEC-011 | Delay 시간 설정 | |

### Equity & Stats (1개)

| ID | 기능 | 비고 |
|----|------|------|
| ST-007 | Hands Played | 단순 카운터, 별도 엔진 불필요 |

### Hand History (1개)

| ID | 기능 | 비고 |
|----|------|------|
| HH-001 | 핸드 목록 표시 | 현재 세션 핸드 목록, 기본 저장만으로 구현 가능 |

### Server 관리 (14개)

| ID | 기능 | 비고 |
|----|------|------|
| SV-001 | 비디오 소스 관리 | 오디오 입력/싱크/레벨은 overlay Drop 확정 |
| SV-005 | Chroma Key | |
| SV-006 | Live/Delay 이중 출력 | |
| SV-008 | Video Size / Frame Rate | |
| SV-010 | 9x16 Vertical | overlay annotation Keep 복원 |
| SV-012 | Board Position | |
| SV-013 | Player Layout | |
| SV-014 | Transition Animation | PRD-0004 v22.0.0 복원 |
| SV-015 | Bounce Action Player | PRD-0004 v22.0.0 복원 |
| SV-016 | 스폰서 로고 3슬롯 | PRD-0004 v22.0.0 복원 |
| SV-018 | 영역별 Chipcount Precision | Main/Board precision만 Keep |
| SV-019 | BB 표시 모드 | |
| SV-020 | 통화 기호 설정 | |
| SV-029 | 플레이어 사진/국기 | |

### v1.0 최종 집계

| 카테고리 | v1.0 개수 |
|----------|:---------:|
| Action Tracker | 22 |
| Pre-Start Setup | 10 |
| Viewer Overlay | 10 |
| GFX Console | 3 |
| Security | 7 |
| Equity & Stats | 1 |
| Hand History | 1 |
| Server 관리 | 14 |
| **합계** | **68** |

---

## 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|----------|
| 1.0.0 | 2026-02-23 | 최초 작성 |
| 1.1.0 | 2026-02-23 | 트리아지 전면 재검토: Viewer Overlay v1.0 10개(VO-011/014 → v2.0), GFX Console v3.0 2개(GC-021/025), Equity Drop 3개(EQ-009/011/ST-005), Hand History v1.0=HH-001, Server v1.0 12개(SV-001/018/029 추가), Security SEC-011 v1.0으로 변경 |
| 1.2.0 | 2026-02-27 | GFX Console Drop 2→3 수정 (GC-019 누락 반영), N/A 6개 재분류 주석 추가 (EQ-009/011, ST-005, HH-004/011, GC-024) |
| 1.3.0 | 2026-02-27 | SV-014/015/016 v2.0 Defer → v1.0 Keep 복원 (PRD-0004 v22.0.0 동기화). Server 관리 v1.0: 12→15, 합계: 66→69 |
| 2.0.0 | 2026-03-01 | overlay annotation 기반 전면 재검토: Drop 13→19 확대 (SV-002/004/007/009/017/025/026 Drop 전환), SV-010 Keep 복원, v1.0 69→68, v2.0 59→55, v3.0 9→8 |

---
**Version**: 2.0.0 | **Updated**: 2026-03-01
