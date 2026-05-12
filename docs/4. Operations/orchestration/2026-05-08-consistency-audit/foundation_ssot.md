---
title: Foundation v4.5 — SSOT 사실표 (정합성 감사 기준점)
owner: conductor
tier: internal
source: "docs/1. Product/Foundation.md v4.5.0"
audit_basis: "모든 Stream 이 본 사실표 기준으로 자기 영역 검증"
last-updated: 2026-05-08
confluence-page-id: 3818881648
confluence-parent-id: 3811573898
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818881648/EBS+Foundation+v4.5+SSOT
---

# Foundation v4.5 — SSOT 사실표

> 본 파일은 `docs/1. Product/Foundation.md` v4.5 의 **검증 가능한 사실** 만 추출.
> 모든 Stream 은 자기 영역에서 본 표와의 drift 를 탐지/정정.
> 충돌 시 `Foundation.md` 가 정점 (if-conflict: derivative-of takes precedence).

---

## §1. 정체성 (Identity)

| 사실 | 값 |
|------|-----|
| EBS Core 정의 | **WSOP LIVE 대회정보 + RFID 카드 + Command Center 액션 → Game Engine → 실시간 Overlay Graphics** |
| 시간축 | 라이브 (즉시 합성) |
| 경쟁 | PokerGFX (벤치마크 only, 구매 X — 자체 구축) |
| 핵심 가치 | 정확성 > 속도 (1~2시간 후편집 앞에서 0.1초 빠름은 무의미) |
| 5 가치 | 정확한 인식 / 장비 안정성 / 명확한 연결 / 단단한 HW / 오류 없는 흐름 |

## §2. 입력 데이터 (3 Trinity)

| # | 데이터 | 출처 | 변동성 | 입력 채널 |
|:-:|-------|-----|-------|----------|
| 1 | 홀카드 | RFID 센서 | 매 카드마다 | YES |
| 2 | 커뮤니티 카드 | RFID 센서 | 매 카드마다 | YES |
| 3 | 베팅 액션 | CC 오퍼레이터 6 키 | 매 액션마다 | YES |
| 4 | 게임 룰 | Engine 코드 내장 | 불변 상수 | NO (재배포 필요) |

## §3. CC 6 키 매핑 (Bet Act 컨텍스트)

| 키 | 1차 의미 | 컨텍스트 |
|:--:|---------|---------|
| **N** | NewHand | Hand Start Act |
| **F** | Fold | Bet Act |
| **C** | Call / Check | Bet Act (베팅 무→Check, 유→Call) |
| **B** | Bet (사이즈 모달) | Bet Act |
| **A** | All-in | Bet Act |
| **M** | More | Deal/Showdown/HandEnd Act |

> **5-Act 시퀀스**: Hand Start → Deal → Bet → Showdown → Hand End

## §4. 8 핵심 그래픽

| # | 그래픽 | 트리거 |
|:-:|-------|-------|
| 1 | 홀카드 표시 | RFID 카드 감지 즉시 |
| 2 | 커뮤니티 카드 | 보드 카드 인식 |
| 3 | 액션 배지 | CC 콜/레이즈/폴드 입력 |
| 4 | 팟 카운터 | 누적 베팅 자동 계산 |
| 5 | 승률 바 | 카드 공개마다 실시간 |
| 6 | 아웃츠 | 유리한 카드 잔여 수 |
| 7 | 플레이어 정보 | 대회 공식 API (이름·칩·사진) |
| 8 | 플레이어 위치 | 좌석별 딜러 버튼 위치 |

> EBS 가 **만들지 않는 것**: 리더보드 / 프로필 카드 (서울 후편집팀) / 자막 틀 (디자인팀 사전 제작)

## §5. EBS 책임 영역의 3 절대 조건

| 조건 | 질문 |
|------|------|
| 시간 | 1초의 지연도 없는 실시간인가? |
| 장소 | 네트워크를 거치지 않고 현장에서 처리되는가? |
| 데이터 소스 | 센서나 현장 조작반에서 발생한 데이터인가? |

## §6. 4 단계 송출 파이프라인

| 구간 | 위치 | 역할 |
|------|------|------|
| **A 구간** | 라스베가스 / 유럽 | 카메라 + 실시간 그래픽 합성 — **EBS 가 설치/운영되는 유일한 공간** |
| **B 구간** | 클라우드 | 무선 송출 → 분배 |
| **C 구간** | 서울 스튜디오 | 1시간 단위 편집 + 후편집 그래픽 |
| **최종** | YouTube / WSOP TV | 무료 / 유료 송출 |

> **EBS 는 A 구간 단 한 곳에서만 운영**. 시청자 도달까지 ~1~2시간 지연.

## §7. 3 그룹 6 기능

| 그룹 | 기능 | 담당 팀 | 스택 |
|------|------|:-------:|-----|
| **조작** | Lobby (5분 게이트웨이) | team1 | Flutter Web + Rive |
| **조작** | Command Center (1×10 + 6 키) | team4 | Flutter Desktop + Rive |
| **두뇌** | Game Engine (22 룰 + 21 OutputEvent) | team3 | Pure Dart |
| **두뇌** | Backend (BO) | team2 | FastAPI + SQLite/PostgreSQL |
| **출력** | Overlay View | team4 | Rive + SDI/NDI |
| **입력** | RFID Hardware (12 안테나) | 외부 HW | ST25R3911B + ESP32 |

> Settings, Rive Manager 는 Lobby 의 일부. 별도 기능 X.

## §8. Lobby 정체성 (v3.0.0 cascade)

| 항목 | 내용 |
|------|------|
| 정체성 | 5분 게이트웨이 + WSOP LIVE 거울 |
| 구조 | Series → Event → Flight → Table 4 단계 |
| 4 진입 시점 | (a) 첫 진입 (b) 비상 진입 (c) 변경 진입 (d) 종료 진입 |
| 배포 | Flutter Web (Docker nginx, LAN 다중 클라이언트) |
| 비율 | Lobby : CC = 1 : N |

## §9. CC Hole Card Visibility 4단 방어 (v4.0 cascade)

| Layer | 메커니즘 |
|:-----:|----------|
| 1 RBAC | 권한 분리 — 일반 운영자 = 홀카드 비공개, 시니어만 검수 권한 |
| 2 2 인 승인 | 시니어 view = 두 명 동시 승인 후에만 활성 |
| 3 60 분 Timer | 권한 자동 만료. 갱신 시 재승인 |
| 4 물리 영역 | CC 모니터 = 시청자 / 딜러 시야 차단 부스 |

## §10. 22 게임 룰 = 3 계열

| 계열 | 종 |
|:----:|:--:|
| 공유 카드 | 12 |
| 카드 교환 | 7 |
| 부분 공개 | 3 |

### Mixed Game (자동 룰 전환)

| 모드 | 순환 게임 | 베팅 구조 |
|------|----------|----------|
| **HORSE** | Hold'em / Omaha / Razz / Stud / Stud Hi-Lo (5종) | FL (모두 고정) |
| **8-Game** | NLHE / PLO / Razz / Stud / Stud Hi-Lo / 2-7 Triple Draw / Limit Hold'em / Omaha 8/B (8종) | NL / PL / FL 혼재 |

## §11. 통신 매트릭스

| From → To | 방식 | 용도 |
|-----------|------|------|
| Lobby → BO | REST | 동기 CRUD |
| Lobby ← BO | WS ws/lobby | 모니터 전용 |
| CC ↔ BO | WS ws/cc | 양방향 명령 + 이벤트 |
| CC → Engine | REST | stateless query |
| Lobby ↔ CC | — | **직접 연결 금지** (BO DB 경유) |

> **CC = Orchestrator**. CC → BO + Engine 병행 dispatch. **Engine 응답 = 게임 상태 SSOT**, BO ack = audit.

## §12. NFR 운영 메트릭 (핵심 가치 아님)

| 채널 | 용도 | 운영 메트릭 |
|------|------|:----------:|
| DB polling | 복구 baseline | 1~5초 |
| WS push | 실시간 알림 | 100ms 미만 (NFR) |

> **표기 주의**: NFR 수치는 운영 안정성 측정값이며 EBS 핵심 가치가 아니다. EBS 미션 = §1 의 5 가치.

## §13. RFID 하드웨어

| 항목 | 값 |
|------|-----|
| 안테나 | 12 (좌석 + 보드 중앙) |
| 칩셋 | ST25R3911B + ESP32 |
| 통신 | USB |
| Mock HAL | **실제 테이블 없어도 전체 기능 완벽 구동** (가장 강력한 특징) |

## §14. 1단계 → 2단계 진화

| 단계 | 입력 모델 | 상태 |
|:----:|----------|------|
| 1단계 | RFID + CC 오퍼레이터 6 키 | **현재 (이 프로젝트 범위)** |
| 2단계 | RFID + Vision Layer (CV 카메라) | **별도 거대 프로젝트** (3단계 파이프라인) |

> 1단계 완전 안정화 후 순차 전환. 병행 운영 X.

## §15. RBAC

| Role | 권한 |
|------|------|
| Admin | 전체 |
| Operator | 할당 테이블 CC만 |
| Viewer | 읽기 전용 |

## §16. 외부 인계 PRD ↔ 정본 cascade

| External PRD | 정본 (Source of Truth) |
|--------------|-----------------------|
| `Lobby.md` | `2.1 Frontend/Lobby/Overview.md` |
| `Command_Center.md` | `2.4 Command Center/Command_Center_UI/Overview.md` |
| `Back_Office.md` | `2.2 Backend/Back_Office/Overview.md` |
| `RIVE_Standards.md` | self (정본) |
| `Game_Rules/*.md` | self (Engine 22 룰 외부측 명세) |

> **Frontmatter 규칙**: `derivative-of: <정본 path>` + `if-conflict: derivative-of takes precedence` + `last-synced: <정본 last-updated 와 동일>`.

---

## 사용 방법 (각 Stream)

```
1. 본 사실표를 워크트리에서 read-only 로 참조
2. 자기 scope_owns 의 각 .md 파일 읽기
3. 본 사실표와의 drift 탐지:
   - 숫자 (8 그래픽, 6 키, 12 안테나, 22 룰, 4 진입시점, 5 Act)
   - 명칭 (Lobby/CC/Engine/BO/Overlay/RFID, HORSE/8-Game)
   - 정의 (5분 게이트웨이, WSOP LIVE 거울, 1×10 + 6키, 1단계 입력)
   - 정체성 (Engine = 22 룰 코드 내장, Lobby:CC = 1:N)
4. drift 발견 시 정정 (단일 commit per file)
5. 본 사실표 자체에 오류 발견 시 → S1 escalate (S1 만 Foundation 수정 가능)
```
