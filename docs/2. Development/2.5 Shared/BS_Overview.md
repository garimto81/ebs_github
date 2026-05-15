---
title: BS Overview
owner: conductor
tier: internal
last-updated: 2026-04-27
legacy-id: BS-00
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "§1 Tech Stack SSOT 3중화 해소 (SG-001 채택: Flutter 채택 + 원칙 1 예외 justify). Lobby/GE 행을 Flutter 로 정렬 완료. 2026-04-27 SG-022: §1 전면 재작성 — 단일 Desktop 바이너리 (Lobby + CC + Overlay), γ 하이브리드 폐기."
confluence-page-id: 3833856204
confluence-parent-id: 3812032646
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/~71202036ff7e0a7684471195434d342e3315ed/pages/3833856204/Overview
---

# BS-00 Definitions — 용어·상태·트리거 총괄 정의서

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | 모든 BS/BO/IMPL/API/DATA 문서의 용어 기반 확립 |
| 2026-04-10 | CCR-011 | §1 앱 아키텍처 표에 Graphic Editor(GE, Team 1 Lobby 허브) 행 추가 |
| 2026-04-10 | CCR-014 | §7.4 신설 — GE 요구사항 Prefix 재편 (GEM/GEI/GEA/GER), GEB-/GEP- reference-only 전환 |
| 2026-04-10 | CCR-016 | §1 Lobby row 기술 컬럼 Quasar(Vue 3)+TS 확정. 본 §1 표가 Tech Stack SSOT임을 명시 |
| 2026-04-13 | WSOP LIVE 정합성 수정 | seat_status 3→9상태 확장(WSOP LIVE Seat Status 코드), event_status Announce→Announced |
| 2026-04-13 | ClockFSM + BlindDetailType | §3.7 ClockFSM 추가, §3.8 BlindDetailType enum 추가. BS-06-02-clock.md 내용 흡수·삭제 |
| 2026-04-13 | WSOP LIVE Clock 정렬 | BlindDetailType: ColorUp/EndOfDay 제거, HalfBlind=3/HalfBreak=4로 WSOP LIVE 인덱스 정렬. Clock Quick Reference 추가 |
| 2026-04-20 | SG-001 Tech Stack 정렬 | §1 Lobby/GE 기술 컬럼을 Flutter 로 갱신. CCR-016 SSOT 선언 유지. 원칙 1 divergence justify (WSOP LIVE Staff Page=Web 와 의도적 차이, EBS 고유 요구). 상세: `docs/4. Operations/Conductor_Backlog/SG-001-tech-stack-ssot-3way.md` |
| 2026-04-22 | Foundation §4.4/§5.0 정렬 | §1 도입부 재작성: Foundation §4.4 2 렌즈(기능 6 ↔ 설치 4 SW+1 HW) + γ 하이브리드 반영 (Lobby Web 정규 / CC·Overlay Desktop). "단일 Flutter 앱 2개 화면 금지" → "Foundation §5.0 2 런타임 모드는 CC/Overlay Desktop 내부 선택지" 맥락 구분. CCR-016 참조를 v7 free_write + decision_owner 로 갱신. Ref: B-201, B-200-1 γ retro |
| 2026-04-22 | 회의 D3 GE 제거 반영 | §1 Graphic Editor (GE) 행 → Rive Manager 로 축소 (Import + Activate + RBAC). §7.4 GEM-* 25 Metadata 편집 요구사항 SUPERSEDED 마킹. 메타데이터는 Rive 파일 내장. Ref: B-209, `Meeting_Analysis_2026_04_22.md §3 D3` |
| 2026-04-27 | SG-022 결정 — §1 전면 재작성 (단일 Desktop 바이너리, γ 하이브리드 폐기). Lobby + Settings + Rive Manager + Command Center + Overlay 모두 단일 Flutter Desktop 바이너리로 배포. Web 빌드는 Phase 2 옵션. §1 표 "배포 형태" 컬럼 통일. 용어 구분 주의 callout 갱신. Ref: Spec_Gap_Registry SG-022, Phase_1_Decision_Queue.md (2026-04-27) |
| 2026-05-07 | v3/v4 정체성 cascade (Phase A) — §1 Lobby/CC 행 정의 보강 — Lobby = 5분 게이트웨이 + WSOP LIVE 거울 (Lobby v3.0.0 SSOT 명시). CC = 1×10 가로 그리드 + 6 키 동적 매핑 + 4 영역 위계 (CC_PRD v4.0 SSOT 명시). 타원 테이블 메타포 폐기 명시. |

---

## 개요

이 문서는 EBS의 **용어·상태값·트리거·FSM·이벤트·ID 체계를 한곳에 정의**하는 단일 출처(Single Source of Truth)다. 모든 행동 명세(BS-01~07), 백오피스 기획(BO-01~11), 기술 문서(IMPL/API/DATA)가 이 문서의 정의를 참조한다.

> **참고**: Enum 값(정수 코드), 데이터 모델 필드 상세, 게임별 파라미터는 `Behavioral_Specs/Overview.md` (legacy-id: BS-06-00)에 정의되어 있다. 이 문서는 "의미"를, BS-06-00-REF는 "값"을 정의한다.

---

## 1. Multi-Service Docker 아키텍처 (2026-04-27 저녁 SSOT)

EBS 는 **Multi-Service Docker 아키텍처** 를 채택한다. **Lobby (team1) 와 Command Center (team4) 는 단일 앱이 아니며, 각각 독립된 Flutter 프로젝트로 존재한다.** 다만 완전 독립은 아니며, Docker 격리 컨테이너로 기동되어 동일한 EBS 에코시스템 (`ebs-net` bridge 네트워크) 내에서 service-name DNS + 환경 변수 (`BO_URL` / `ENGINE_URL` / `LOBBY_URL` / `CC_URL`) 로 상호 작용한다.

> **이전 인텐트** (2026-04-27 아침 채택, 같은 날 저녁 폐기): Lobby + CC + Overlay 를 하나의 Flutter Desktop 배포 단위로 통합 — 사용자 결정으로 폐기됨. 자세히: `docs/4. Operations/Conductor_Backlog/SG-022-deprecation.md`, `docs/4. Operations/MULTI_SESSION_DOCKER_HANDOFF.md`.

### 1.1 채택 근거

- **기획-운영 정합**: LAN 멀티 클라이언트 / 핫픽스 / 운영자 분리 워크플로우 충족
- **4팀 병렬성**: 팀별 Dockerfile 라이프사이클 분리 (team1 `lobby-web`, team4 `cc-web`)
- **운영자 워크플로우**: Lobby (대시보드, 운영자) ↔ CC (액션 입력, 테이블 담당자) 분리 활용
- **2026-04-22 사건 재발 차단**: "Desktop only" 확대 해석 → `ebs-lobby-web` 컨테이너 destroy 사건 (Type C) 의 근본 원인 제거
- **사용자 결정 (2026-04-27 저녁)**: 이전 인텐트 폐기 명시 cascade

### 1.2 컨테이너 토폴로지

| 서비스 | 컨테이너 포트 | 호스트 포트 | 팀 | 역할 |
|--------|:-------------:|:-----------:|:---:|------|
| `bo` | 8000 | 8000 | team2 | Backend REST/WebSocket |
| `redis` | 6379 | 6380 | — | session / pub-sub |
| `engine` | 8080 | 8080 | team3 | Game Engine harness |
| `lobby-web` | 3000 | 3000 | team1 | 운영자 대시보드 (브라우저 접속) |
| `cc-web` | 3001 | 3001 | team4 | Command Center + Overlay (브라우저 접속) |

기동: `docker compose --profile web up -d --build`. SSOT: `docs/4. Operations/MULTI_SESSION_DOCKER_HANDOFF.md`.

### 1.3 용어 구분 주의

- **격리 + 협력**: 각 컨테이너는 독립 라이프사이클을 갖되 (코드 의존성 없음), 런타임에 BO WebSocket / REST + service-name DNS 로 협력
- **단일 사용자, 두 브라우저 탭**: 운영자는 `:3000` (Lobby) 와 `:3001` (CC) 을 동시에 띄울 수 있고, BO 가 두 탭 사이의 동기화 SSOT
- **개발자 디버깅 (배포 아님)**: `flutter run -d windows/-d chrome` 은 정규 배포가 아닌 핫리로드 도구

### 1.3 Phase 2 옵션

Web 빌드는 현재 EBS 범위 밖 (Phase 2 옵션). 향후 운영 요구가 발생하면 별도 Spec Gap 으로 재기획.

### 1.4 참조

- Foundation §5.0 (두 런타임 모드)
- Spec_Gap_Registry SG-022
- Phase_1_Decision_Queue.md (2026-04-27 결정 기록)
- 폐기된 정책: 2026-04-22 γ 하이브리드 (MEMORY `feedback_web_flutter_separation` SUPERSEDED)

### 1.5 앱 구성 표

| 용어 | 정의 | 기술 | 비고 |
|------|------|------|------|
| **Lobby** | **5분 게이트웨이 + WSOP LIVE 거울** (Lobby v3.0.0). 시프트 시작 5분 안에 룰 활성 + 좌석 + RFID 검증 → CC 위임. WSOP LIVE → BO 단방향 미러 (Series→Event→Flight→Table). | Flutter/Dart + Riverpod + Freezed + Dio + go_router + rive | 단일 Desktop 바이너리 내부 라우팅. Rive Manager 허브 포함. Tech Stack SSOT (CCR-016, SG-001 resolved 2026-04-20). 개발자 디버깅: `flutter run -d windows`. 정체성 SSOT = `docs/1. Product/Lobby.md` v3.0.0 |
| **Command Center (CC)** | **1×10 가로 그리드 + 6 키 동적 매핑** (CC_PRD v4.0). 좌석 1~10 일렬 시각화 + N·F·C·B·A·M 키 (5-Act 시퀀스 컨텍스트별 의미 변경) + 4 영역 위계 (Stat/Seat/Action/Reader Panel). 테이블당 1개 인스턴스. 타원 테이블 메타포 폐기. | Flutter/Dart + Riverpod + Dio + rive | 구 PokerGFX Action Tracker. Lobby 와 동일 바이너리 (라우팅 분리). RFID 시리얼 하드웨어 접근. 정체성 SSOT = `docs/1. Product/Command_Center.md` v4.0 |
| **Overlay** | 시청자 방송 화면 그래픽 출력 | Flutter + Rive | CC 와 동일 바이너리 / 기술 스택. SDI/NDI 직결. |
| **Rive Manager** (구 Graphic Editor) | Rive 파일 **업로드 + 검증 + 활성화** 허브. Lobby 내부 섹션 (`/lobby/rive-manager` 또는 Settings 하위). 메타데이터는 Rive 파일에 내장 (D3 2026-04-22) | Flutter + Rive (프리뷰) | Admin 전용. Lobby 내부 기능 (별도 앱 아님). GEM-* 25 Metadata 편집 요구사항 **SUPERSEDED** (회의 D3 2026-04-22). GEI (Import) + GEA (Activate) + GER (RBAC) 만 유효. |
| **Settings** | 오버레이·출력·게임 규칙·통계 설정. Lobby의 하위 다이얼로그 | Lobby 내 구현 | ~~Console~~ 독립 앱 아님 |
| **Back Office (BO)** | Lobby와 CC 사이 간접 데이터 공유 계층. REST API + WebSocket + DB | FastAPI + SQLite → PostgreSQL | 별도 서비스 프로세스. Lobby↔CC 직접 연동 없음 |
| **Game Engine** | 게임 규칙·상태 관리 순수 패키지. CC에 import됨 | 순수 Dart (Flutter 의존 없음, 단 `bin/harness.dart` 는 `dart:io` HTTP 서버 허용) | 별도 서비스 프로세스. Event Sourcing |

**관계**:
- Lobby : CC = **1 : N** (1개 Lobby에서 N개 테이블의 CC 관리, 단일 바이너리 내 라우팅)
- Lobby ↔ CC **직접 연동 없음** — Back Office DB를 통한 간접 공유
- CC 1개 = Table 1개 = Overlay 1개

> **Tech Stack SSOT**: 본 §1.5 표는 EBS 앱 기술 스택의 **단일 출처(Single Source of Truth)** 다. 팀 내부 스펙(`team*-*/CLAUDE.md`, `docs/2. Development/2.{1..4}/**`)은 본 표를 cross-reference. 변경 시 v7 `free_write_with_decision_owner` 거버넌스 따름 — decision_owner = Conductor, 변경 후 모든 팀에 notify (CCR 폐기 2026-04-17).

> **WSOP LIVE 정렬 주의 (원칙 1 §"적용 예외")**: WSOP LIVE Staff Page 는 Web 이지만, EBS 는 RFID 시리얼 + SDI/NDI 직결 + Rive 런타임 일치 + 4 팀 Flutter 공통 의존성을 이유로 **Desktop 단일 바이너리 채택**. 기술 스택은 EBS 자율 (CLAUDE.md 원칙 1). 기획·문서·용어 정렬은 유지. 자율성 근거: `docs/4. Operations/Conductor_Backlog/SG-001-tech-stack-ssot-3way.md`.

---

## 2. 엔티티 용어

### 2.1 대회 계층 (WSOP LIVE 동일)

```
Competition → Series → Event → Flight → Table → Seat → Player
```

| 엔티티 | 정의 | 예시 |
|--------|------|------|
| **Competition** | 최상위 대회 브랜드 | WSOP, WSOPC, APL |
| **Series** | 대회 시리즈 (연간) | 2026 WSOP |
| **Event** | 개별 토너먼트/이벤트 | Event #1: $10K NL Hold'em |
| **Flight** | Event의 진행 구간 | Day 1A, Day 1B, Day 2 |
| **Table** | 물리적 포커 테이블 | Table 1 (Feature Table) |
| **Seat** | 테이블 내 좌석 (0~9) | Seat 3 |
| **Player** | 좌석에 배치된 참가자 | John Doe, Seat 3 |

### 2.2 게임 엔티티

| 엔티티 | 정의 | 생명주기 |
|--------|------|----------|
| **Hand** | 게임 1판. 딜부터 승자 결정까지 | IDLE → ... → HAND_COMPLETE |
| **Round** (Street) | Hand 내 베팅 단계 | Pre-Flop, Flop, Turn, River |
| **Action** | 플레이어의 1회 결정 | Fold, Check, Bet, Call, Raise, All-In |
| **Card** | 52장 중 1장. RFID UID 매핑 가능 | suit(0~3) + rank(0~12) |
| **Deck** | 52장 카드 세트. RFID 등록 대상 | 등록/미등록/부분등록 |
| **Pot** | 현재 Hand에 베팅된 총액 | 메인 팟 + 사이드 팟 0~N개 |
| **Bet** | 1회 베팅 금액 | 최소 BB ~ 최대 All-In (NL) |
| **Stack** | 플레이어의 현재 보유 칩 | 0+ (칩 단위, 화폐 아님) |

### 2.3 설정 엔티티

| 엔티티 | 정의 |
|--------|------|
| **BlindStructure** | 블라인드 레벨 진행표 (SB/BB/Ante × 레벨) |
| **Skin** | 오버레이 그래픽 테마 (배경, 카드, 좌석, 폰트, 색상) |
| **OutputPreset** | NDI/HDMI 출력 설정 프리셋 (해상도, Security Delay, 크로마키) |
| **Config** | BO 글로벌 설정 (RFID 모드, 로그 레벨, 시스템 기본값) |

---

## 3. 상태값 정의

### 3.1 Table 상태 (TableFSM)

| 상태 (display) | 직렬화 값 (DB / API) | 의미 | 진입 조건 | 퇴장 조건 |
|------|------|------|----------|----------|
| **EMPTY** | `empty` | 미설정 — 게임 유형, 플레이어 없음 | 테이블 생성 시 | 게임 설정 완료 |
| **SETUP** | `setup` | 설정 중 — 게임·좌석 배치 진행 | 게임 설정 시작 | CC Launch 시 |
| **LIVE** | `live` | 방송 중 — CC가 활성화되어 핸드 진행 | CC Launch 완료 | Pause 또는 Close |
| **PAUSED** | `paused` | 일시 중단 — 휴식, 테이블 브레이크 | 운영자 Pause | Resume → LIVE |
| **CLOSED** | `closed` | 종료 — 해당 Flight/Event 내 테이블 폐쇄 | 운영자 Close | 재사용 시 EMPTY |

> **직렬화 규약 (2026-04-20 SG-009 정렬)**: 본 문서의 display label 은 UPPERCASE 이지만, DB column (`tables.status`) 및 REST/WebSocket payload 직렬화 값은 **lowercase** 이다. 참조 구현: `team2-backend/src/db/init.sql L328`, `team2-backend/src/services/table_service.py`. Seat 상태 (§3.3) 도 동일 규약. `tools/spec_drift_check.py --fsm` 가 이 규약 일치를 자동 검증한다.

### 3.2 Hand 상태 (HandFSM / game_phase)

| 상태 | 값 | 의미 |
|------|:--:|------|
| **IDLE** | 0 | 핸드 대기. CC에서 NEW HAND 대기 |
| **SETUP_HAND** | 1 | 핸드 준비. 블라인드 수집, 딜러 이동 |
| **PRE_FLOP** | 2 | 프리플롭 베팅. 홀카드 배분 후 |
| **FLOP** | 3 | 플롭 공개 + 베팅 |
| **TURN** | 4 | 턴 공개 + 베팅 |
| **RIVER** | 5 | 리버 공개 + 베팅 |
| **SHOWDOWN** | 6 | 카드 공개, 승패 결정 |
| **HAND_COMPLETE** | 7 | 핸드 종료, 팟 분배 완료 |
| **RUN_IT_MULTIPLE** | 17 | 런잇타임 진행 (특수) |

> 상세 enum 값: `BS-06-00-REF §1.9 game_phase`

### 3.3 Seat 상태 (SeatFSM)

| 값 | 상태 | WSOP LIVE 코드 | 설명 |
|:--:|------|:---:|------|
| 0 | **EMPTY** | E | 빈 좌석 (백색) |
| 1 | **NEW** | N | 신규 배정 (10분 카운트다운) |
| 2 | **PLAYING** | — | 플레이 중 (녹색) |
| 3 | **MOVED** | M | 이동해 온 좌석 (10분 카운트다운) |
| 4 | **BUSTED** | B | 탈락 요청 (FM/TD confirm 대기, 적색) |
| 5 | **RESERVED** | R | Auto Seating 제외 (짙은 회색) |
| 6 | **OCCUPIED** | O | Break Table 등 예약 점유 |
| 7 | **WAITING** | W | 웨이팅 플레이어 배정됨 (황색) |
| 8 | **HOLD** | H | Seat Draw in Advance 선점 (회색) |

> **직렬화 규약 (2026-04-20 SG-009 정렬)**: §3.1 과 동일. 본 표의 display label (`EMPTY`, `NEW`, `PLAYING` …) 은 UPPERCASE 이지만, DB column (`table_seats.status`) 및 REST/WebSocket payload 직렬화 값은 **lowercase** (`empty`, `new`, `playing` …). 참조: `team2-backend/src/db/enums.py::SeatFSM`, `team2-backend/src/db/init.sql L376/L384`. `tools/spec_drift_check.py --fsm` 가 이 규약을 자동 검증한다 (2026-04-21 기준 D4=23/23).

### 3.4 Player 상태 (Hand 내)

| 상태 | 값 | 의미 | 전환 조건 |
|------|:--:|------|----------|
| **active** | 0 | 활성, 액션 가능 | 핸드 시작 |
| **folded** | 1 | 폴드됨, 해당 핸드 제외 | FOLD 액션 |
| **allin** | 2 | 올인, 스택 0 | BET/CALL/RAISE로 스택 전부 소진 |
| **eliminated** | 3 | 탈락 (토너먼트) | 스택 0 + 재입금 불가 |
| **sitting_out** | 4 | 관전, 현재 핸드 불참 | 플레이어 자발적 이탈 |

> 상세: `BS-06-00-REF §1.5.2 PlayerStatus`

### 3.5 Deck 상태 (DeckFSM)

| 상태 | 의미 |
|------|------|
| **UNREGISTERED** | RFID 등록 전 — 카드-UID 매핑 없음 |
| **REGISTERING** | 등록 진행 중 — 52장 전수 스캔 진행 |
| **REGISTERED** | 등록 완료 — 52장 매핑 확인, 게임 투입 가능 |
| **PARTIAL** | 부분 등록 — 일부 카드 매핑 실패 (에러 상태) |
| **MOCK** | Mock 모드 — RFID 없이 소프트웨어 가상 매핑 |

### 3.6 Event 상태 (EventFSM)

| 상태 | 의미 |
|------|------|
| **Created** | 생성됨 — App에서 미노출 |
| **Announced** | 공지됨 — 등록 전 공지 상태 |
| **Registering** | 등록 중 — 플레이어 등록 가능 |
| **Running** | 진행 중 — 게임 진행 |
| **Completed** | 완료 |
| **Canceled** | 취소 |

> 표시 상태(Restricted, Late Reg.)는 isRegisterable 플래그와 Day 번호의 조합으로 결정된다. 상세: DATA-03 §5

### 3.7 Clock 상태 (ClockFSM) — BO 소유

Tournament Clock 타이머 상태. **소유: Backend(Team 2)**. 상세 트리거: `Triggers.md §2.4 Clock` (legacy-id: `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: BS-06-00-triggers))).

| 상태 | 의미 | 진입 조건 | 퇴장 조건 |
|------|------|----------|----------|
| **STOPPED** | 대회 시작 전 / 종료 후 | 초기, CompleteTournament | StartClock |
| **RUNNING** | 블라인드 타이머 카운트다운 중 | StartClock, ResumeClock, Break 종료 | 레벨 종료, PauseClock |
| **PAUSED** | TD 수동 일시정지 | PauseClock (Operator/Admin) | ResumeClock |
| **BREAK** | 자동 휴식 | `breakPerLevel` 도달 시 자동 | Break 시간 종료 → RUNNING |
| **DINNER_BREAK** | 식사 휴식 | `DinnerBreakTime` 도달 시 자동 | DinnerBreak 종료 → RUNNING |

**Pause 우선순위**: ManualPause > DinnerBreak > Break > AutoPause (WSOP LIVE Staff App Live 준거)

**대회 현지 시각 표시 (venue local time):**  
Lobby 대시보드 상단(`ClockHeader`)에 대회 개최지 기준 현지 시각을 표시한다.  
- 구현 방식: `series.time_zone` (IANA 포맷, DATA-04)을 읽어 **클라이언트가 직접 현재 시각 변환** (WSOP LIVE `SeriesLocalClock.vue` 패턴)  
- `clock_tick` payload와 **무관** — 서버가 timezone을 이벤트로 보내지 않는다  
- WSOP Europe: `series.time_zone = "Europe/Paris"` → CET/CEST 자동 전환  
- WSOP Vegas: `series.time_zone = "America/Los_Angeles"` → PST/PDT 자동 전환

> **Clock 관련 문서 위치**:
> - FSM 상태: 본 문서 §3.7 | BlindDetailType enum: 본 문서 §3.8
> - 트리거/Auto Blind-Up: `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: BS-06-00-triggers))) §2.5
> - WebSocket 이벤트: API-05 §4.2.2~4.2.3
> - REST API: API-01 §5.6.1
> - DB 필드: DATA-04 (BlindStructureLevel.detail_type)
> - Clock display theming (WSOP LIVE `ClockThemeType`): Skin 엔티티(DATA-04)로 대체. Phase 2+ 고려.

### 3.8 BlindDetailType — 블라인드 레벨 유형 enum

`clock_tick` / `clock_level_changed` 이벤트에서 현재 레벨의 유형을 나타낸다. WSOP LIVE `ClockStore.currentType` 준거.

| 값 | 이름 | 설명 |
|:--:|------|------|
| 0 | **Blind** | 일반 블라인드 레벨 |
| 1 | **Break** | 자동 휴식 (전체 참가자) |
| 2 | **DinnerBreak** | 식사 휴식 (전체 참가자) |
| 3 | **HalfBlind** | 하프 디너 블라인드 레벨 (A/B 그룹 교대) |
| 4 | **HalfBreak** | 하프 디너 휴식 (A/B 그룹 교대) |

> WSOP LIVE `BlindDetailType` enum 준거 (5값, 인덱스 동일).  
> `HalfBlind`/`HalfBreak`는 Half Dinner Break 시나리오에서 그룹별 교대 블라인드를 지원한다.  
> API-05 §4.2.2 `clock_tick.blind_detail_type`, API-01 §5.6.1 Clock API에서 사용.

---

## 4. 트리거 3소스

모든 행동 명세에서 트리거는 반드시 **발동 주체**를 명시한다.

| 소스 | 주체 | 설명 | 예시 |
|------|------|------|------|
| **CC** | 운영자 (수동) | Command Center에서 운영자가 버튼/키보드로 입력 | NEW HAND, DEAL, FOLD, BET, RAISE |
| **RFID** | 시스템 (자동) | RFID 리더가 카드를 감지/제거 | CardDetected, CardRemoved, DeckRegistered |
| **Engine** | 시스템 (자동) | Game Engine이 규칙에 따라 자동 실행 | 블라인드 수집, 팟 계산, 승자 결정 |
| **BO** | 시스템 (자동) | Back Office에서 데이터 변경 통지 | ConfigChanged, PlayerUpdated, TableAssigned |

> **우선순위**: CC와 RFID가 동시 발생 시 경계 규칙은 `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: BS-06-00-triggers))))에서 정의한다.

### Mock 모드에서의 트리거 변환

| 실제 모드 트리거 | Mock 모드 대체 | 변환 주체 |
|----------------|--------------|----------|
| RFID CardDetected | CC 수동 카드 입력 → `CardDetected` 이벤트 합성 | Mock HAL |
| RFID DeckRegistered | CC "자동 등록" 버튼 → `DeckRegistered` 이벤트 합성 | Mock HAL |
| RFID CardRemoved | 없음 (Mock에서 미지원) | — |

> **핵심 원칙**: Mock HAL은 Real HAL과 동일한 이벤트 스트림을 생성한다. 상위 계층(CC, Engine)은 Real/Mock을 구분하지 않는다.

---

## 5. FSM 이름 규약

| FSM | 관리 대상 | 정의 위치 |
|-----|----------|----------|
| **TableFSM** | Table 상태 (EMPTY → ... → CLOSED) | 이 문서 §3.1 |
| **HandFSM** | Hand 상태 (IDLE → ... → HAND_COMPLETE) | 이 문서 §3.2, BS-06-01 상세 |
| **SeatFSM** | Seat 상태 (EMPTY/NEW/PLAYING/MOVED/BUSTED/RESERVED/OCCUPIED/WAITING/HOLD) | 이 문서 §3.3 |
| **DeckFSM** | Deck 상태 (UNREGISTERED → ... → REGISTERED) | 이 문서 §3.5, BS-04-01 상세 |
| **EventFSM** | Event 진행 상태 (Created → Announced → Registering → Running → Completed / Canceled) | 이 문서 §3.6 |
| **ClockFSM** | Tournament Clock 상태 (STOPPED/RUNNING/PAUSED/BREAK/DINNER_BREAK). **소유: BO** | 이 문서 §3.7, 트리거: `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: BS-06-00-triggers))) §2.4 |

---

## 6. 이벤트 명명 규약

모든 시스템 이벤트는 **PascalCase** + **동사 과거분사** 패턴을 따른다.

| 패턴 | 예시 | 발행 주체 |
|------|------|----------|
| `{Entity}{Action}` | `HandStarted`, `HandCompleted` | Engine |
| `{Entity}{Action}` | `CardDetected`, `CardRemoved`, `DeckRegistered` | RFID HAL |
| `{Entity}{Action}` | `ActionSubmitted`, `SeatAssigned` | CC |
| `{Entity}{Action}` | `ConfigChanged`, `PlayerUpdated`, `TableAssigned` | BO |
| `{Entity}{Action}` | `OperatorConnected`, `OperatorDisconnected` | BO (WebSocket) |

> **WebSocket 이벤트 상세**: `WebSocket_Events.md` (legacy-id: API-05)

---

## 7. ID 체계

### 7.1 Feature Catalog ID (144개)

`docs/01-strategy/EBS-Feature-Catalog.md`에서 정의된 캐노니컬 ID를 모든 BS 문서에서 참조한다.

| Prefix | 범주 | 개수 |
|--------|------|:----:|
| **MW-** | Main Window (Lobby + CC 공통) | 10 |
| **SRC-** | Sources (OBS/vMix 위임, EBS 범위 외) | 10 |
| **OUT-** | Outputs (NDI/HDMI 출력) | 12 |
| **G1-** | GFX1 게임 제어 (CC 오버레이 핵심) | 24 |
| **G2-** | GFX2 통계 (플레이어 통계) | 13 |
| **G3-** | GFX3 방송 연출 (자막, 타이머 등) | 13 |
| **SYS-** | System (RFID, 네트워크, 보안, 백업) | 16 |
| **SK-** | Skin Editor | 16 |
| **GEB-** | Graphic Editor Board (PokerGFX 역설계 참고 자산, reference-only) | 15 |
| **GEP-** | Graphic Editor Player (PokerGFX 역설계 참고 자산, reference-only) | 15 |

> **GEB-/GEP- 상태 변경 (CCR-014)**: 두 prefix는 PokerGFX 역설계 기반의 Transform/Animation 편집 요구사항이었으나, `ge-ownership-move` (CCR-011)로 편집 scope가 "메타데이터 + Import + Activate"로 축소되면서 **reference-only**로 전환되었다. 실제 편집 UI 대상이 아니며, 디자이너는 Rive 공식 에디터로 `.riv`를 완성한다. 신규 GE 요구사항 prefix는 §7.4 참조.

### 7.2 BS 문서 번호

| ID | 영역 | 문서 위치 |
|----|------|----------|
| BS-00 | 정의서 (이 문서) | `02-behavioral/BS-00-definitions.md` |
| BS-01 | Auth (로그인·세션·RBAC) | `02-behavioral/BS-01-auth/` |
| BS-02 | Lobby (테이블 관리) | `02-behavioral/BS-02-lobby/` |
| BS-03 | Settings (출력·오버레이·게임·통계) | `02-behavioral/BS-03-settings/` |
| BS-04 | RFID (카드 인식·수동 폴백) | `02-behavioral/BS-04-rfid/` |
| BS-05 | Command Center (게임 진행) | `02-behavioral/BS-05-command-center/` |
| BS-06 | Game Engine (내부 처리) | `04-rules-games/games/engine-spec/` |
| BS-07 | Overlay (시청자 화면 출력) | `02-behavioral/BS-07-overlay/` |

### 7.3 BO 문서 번호

| ID | 영역 | 문서 위치 |
|----|------|----------|
| BO-01~11 | Back Office 기획 | `back-office/` |

### 7.4 Rive Manager Requirements Prefix (D3 2026-04-22 축소 후)

> **회의 D3 결정 (2026-04-22)**: 별도 Graphic Editor 앱 제거. 편집 범위 "Import + **Metadata** + Activate" → "Import + Activate" 로 축소. **메타데이터는 Rive 파일에 내장** (아트 디자이너가 외부 Rive Editor 에서 처리). 상세: `docs/4. Operations/Critic_Reports/Meeting_Analysis_2026_04_22.md §3 D3` + `Conductor_Backlog/B-209-*.md`.

| Prefix | 범위 | 개수 | 상태 | 소유 |
|--------|------|:----:|------|------|
| **GEM-** | Metadata 편집 (`skin.json` 필드) | 25 | **SUPERSEDED (D3 2026-04-22)** — Rive 파일 내장으로 대체 | — |
| **GEI-** | Import Flow (Rive 파일 업로드, 검증, 프리뷰) | 8 | active | team1 |
| **GEA-** | Activate + Broadcast (`PUT /skins/{id}/activate` + 멀티 CC 동기화) | 6 | active | team1 + team2 |
| **GER-** | RBAC guards (Admin/Operator/Viewer gate, UI + API 이중) | 5 | active | team1 + team2 |
| **GEB-** | Board 편집 (PokerGFX 역설계 참고) | 15 | reference-only | — |
| **GEP-** | Player 편집 (PokerGFX 역설계 참고) | 15 | reference-only | — |

#### GEM-* Metadata Editing Requirements (25) — **SUPERSEDED (D3 2026-04-22)**

> **⚠ 이 섹션 전체는 회의 D3 결정으로 폐기됨**. 메타데이터 편집 UI 대신 아트 디자이너가 외부 Rive Editor 에서 메타데이터를 Rive 파일에 내장한다. 아래 25 항목은 **참조 이력** 으로만 보존. 구현 대상 아님.

| ID | 설명 | `skin.json` path | UI | 검증 |
|----|------|---------------|-----|------|
| GEM-01 | Skin 이름 편집 | `skin_name` | text input (1~40) | non-empty |
| GEM-02 | 버전 편집 | `version` | text input | semver regex `^\d+\.\d+\.\d+$` |
| GEM-03 | 작성자 편집 | `author` | text input (0~80) | — |
| GEM-04 | 해상도 선택 | `resolution.width`/`.height` | dropdown (1080p/1440p/2160p) | enum |
| GEM-05 | 배경 설정 | `background.type` + `.color`/`.chromakey_color` | dropdown + color picker | enum + `#hex` |
| GEM-06 | 배경 색상 | `colors.background` | color picker | `#hex` |
| GEM-07 | Text primary 색상 | `colors.text_primary` | color picker | `#hex` |
| GEM-08 | Text secondary 색상 | `colors.text_secondary` | color picker | `#hex` |
| GEM-09 | Badge check 색상 | `colors.badge_check` | color picker | `#hex` |
| GEM-10 | Badge fold 색상 | `colors.badge_fold` | color picker | `#hex` |
| GEM-11 | Badge bet 색상 | `colors.badge_bet` | color picker | `#hex` |
| GEM-12 | Badge call 색상 | `colors.badge_call` | color picker | `#hex` |
| GEM-13 | Badge allin 색상 | `colors.badge_allin` | color picker | `#hex` |
| GEM-14 | Pot text 색상 | `colors.pot_text` | color picker | `#hex` |
| GEM-15 | Player name 폰트 | `fonts.player_name` | family + size + weight | — |
| GEM-16 | Chip stack 폰트 | `fonts.chip_stack` | family + size + weight | — |
| GEM-17 | Pot 폰트 | `fonts.pot` | family + size + weight | — |
| GEM-18 | Action badge 폰트 | `fonts.action_badge` | family + size + weight | — |
| GEM-19 | Equity 폰트 | `fonts.equity` | family + size + weight | — |
| GEM-20 | Hand rank 폰트 | `fonts.hand_rank` | family + size + weight | — |
| GEM-21 | Card fade duration | `animations.card_fade_duration_ms` | slider (0~5000) | integer |
| GEM-22 | Board slide duration | `animations.board_slide_duration_ms` | slider (0~5000) | integer |
| GEM-23 | Board stagger delay | `animations.board_stagger_delay_ms` | slider (0~1000) | integer |
| GEM-24 | Glint sequence duration | `animations.glint_sequence_duration_ms` | slider (0~5000) | integer |
| GEM-25 | Reset duration | `animations.reset_duration_ms` | slider (0~5000) | integer |

#### GEI-* Import Flow Requirements (8)

| ID | 설명 |
|----|------|
| GEI-01 | `.gfskin` ZIP 파일 선택 UI (파일 다이얼로그 또는 드래그앤드롭) |
| GEI-02 | ZIP 구조 검증 (`skin.json` + `skin.riv` 필수) |
| GEI-03 | `skin.json` JSON 파싱 |
| GEI-04 | DATA-07 JSON Schema 클라이언트 검증 (ajv-js) |
| GEI-05 | `skin.riv` Rive 파싱 가능성 확인 |
| GEI-06 | Rive 프리뷰 렌더링 (rive-js `@rive-app/canvas`) |
| GEI-07 | `POST /api/v1/skins` multipart 업로드 |
| GEI-08 | 업로드 실패 시 에러 메시지 UI |

#### GEA-* Activate + Broadcast Requirements (6)

| ID | 설명 |
|----|------|
| GEA-01 | Activate 버튼 클릭 → ETag 포함 `PUT` 요청 |
| GEA-02 | GameState==RUNNING 감지 시 경고 다이얼로그 표시 |
| GEA-03 | 412 ETag 충돌 시 최신 상태 refetch 후 재시도 옵션 |
| GEA-04 | 성공 응답 후 UI에 "Activated" 토스트 |
| GEA-05 | 서버 `skin_updated` WebSocket broadcast (seq 단조증가, CCR-015 준수) |
| GEA-06 | 다중 CC 인스턴스 동시 리로드 (500ms 이내) |

#### GER-* RBAC Requirements (5)

| ID | 설명 |
|----|------|
| GER-01 | Admin 역할만 Upload / PATCH / Activate / Delete 버튼 표시 |
| GER-02 | Operator는 읽기 전용 (리스트 / 프리뷰 / 메타데이터 조회) |
| GER-03 | Viewer는 GE 탭 자체 접근 차단 |
| GER-04 | 서버 API gate (UI gate 우회 방지) |
| GER-05 | 403 응답 시 UI 안내 메시지 |

> **연관 문서**: `BS-08-graphic-editor/` 5파일, `Graphic_Editor_API.md` (legacy-id: API-07), `DATA-07-gfskin-schema.md`.

---

## 8. 시간·수치·단위

| 값 | 단위 | 설명 |
|----|------|------|
| 칩 수량 | **칩** (정수) | 화폐 아닌 게임 내 칩 단위. `chips` 단어 사용 시 반도체 칩과 혼동 주의 → **베팅 토큰** 권장 |
| 확률 | **0.0 ~ 1.0** (float) | Equity 표시 시 × 100 = % 변환 |
| 시간 | **ms** (밀리초) | 애니메이션, 지연, 타임아웃 |
| 해상도 | **px** (1080p = 1920×1080, 4K = 3840×2160) | 출력 해상도 |
| RFID UID | **16자 16진 문자열** | 예: `"04A3B2C1D5E6F7A8"` |
| 카드 표시 | **랭크+수트 2자** | 예: `"As"` (Ace of Spades), `"Th"` (Ten of Hearts) |

---

## 9. Mock 모드 정의

Mock 모드는 RFID 하드웨어 없이 EBS 전체 기능을 사용하기 위한 **개발·테스트·데모 모드**다.

### 무엇이 Real과 다른가

| 계층 | Real 모드 | Mock 모드 |
|------|----------|----------|
| **RFID HAL** | ST25R3911B + ESP32 Serial UART | `MockRfidReader` — 소프트웨어 에뮬레이션 |
| **카드 감지** | 안테나가 물리적으로 카드 UID를 읽음 | CC에서 수동 카드 입력 → `CardDetected` 이벤트 합성 |
| **덱 등록** | 52장 실물 카드를 리더에 스캔 | "자동 등록" 1클릭 → 52장 가상 매핑 |
| **카드 제거** | 안테나 신호 소실 | Mock에서 미지원 (필요 시 수동 이벤트 주입) |
| **에러** | 하드웨어 장애 (안테나 오류, UID 중복 등) | 에러 주입 API로 테스트 가능 |

### 무엇이 동일한가

| 계층 | 동작 |
|------|------|
| **CC UI** | 동일 — Real/Mock 구분 없이 같은 화면 |
| **Game Engine** | 동일 — 이벤트 소스와 무관하게 같은 규칙 적용 |
| **Overlay** | 동일 — 같은 그래픽 출력 |
| **BO** | 동일 — 같은 API, 같은 DB 스키마 |
| **이벤트 스트림** | 동일 — `IRfidReader.events` 스트림의 이벤트 타입/페이로드가 같음 |

> **핵심 원칙**: Mock 모드에서 바뀌는 것은 **RFID HAL 구현체 1개**뿐이다. 나머지 모든 계층은 Real 모드와 100% 동일하다.

> **인터페이스 계약 상세**: `contracts/api/API-03-rfid-hal-interface.md`

---

## 10. 문서 참조 규약

### 이 문서를 참조하는 방법

모든 BS/BO/IMPL/API/DATA 문서에서 용어를 처음 사용할 때:

```markdown
> 참조: BS-00 §3.1 Table 상태
```

### 이 문서에서 참조하는 문서

| 참조 대상 | 경로 |
|----------|------|
| Enum 값 상세 | `Behavioral_Specs/Overview.md` (legacy-id: BS-06-00) |
| Feature Catalog 144 ID | `docs/01-strategy/EBS-Feature-Catalog.md` |
| 트리거 경계 상세 | `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: `Triggers.md` (legacy-id: BS-06-00-triggers))) |
| RFID HAL 인터페이스 | `contracts/api/API-03-rfid-hal-interface.md` |
| WebSocket 이벤트 상세 | `WebSocket_Events.md` (legacy-id: API-05) |
