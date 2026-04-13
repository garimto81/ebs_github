# PRD-EBS_BackOffice — Back Office PRD

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | WSOP LIVE Staff Page BO 벤치마크 기반, 채택/제거 매트릭스, EBS 전용 추가, Phase별 로드맵 |
| 2026-04-09 | BO 문서 축소 | 12개→3개 축소 (BS/API/DATA SSOT 중복 제거), §5 하위 문서 참조 갱신 |
| 2026-04-10 | Chip Master Phase 경계 명시 | §1.2 Cashier 항목에 Phase 2+ 백로그 라벨 추가, WSOP LIVE 3종 실시간 이벤트 CCR 예정 명시 |

---

## 개요

Back Office(BO)는 EBS의 **중앙 데이터 계층**이다. Lobby(웹)와 Command Center(Flutter)는 직접 연동되지 않으며, BO의 REST API + WebSocket + DB를 통해 간접으로 데이터를 공유한다.

**설계 원칙**: WSOP LIVE Staff Page의 BO 기능 중 **방송 테이블 운영에 필요한 것만 채택**하고, 토너먼트 운영/금융/KYC 등 EBS 범위 외 기능은 제거한다. RFID, 덱 등록, 출력 장비 등 **EBS 전용 기능을 추가**한다.

> 상세 아키텍처: BO-01 Overview / API 계약: API-01~06 / 데이터 모델: DATA-01~06

---

## 1. WSOP LIVE BO 벤치마크

### 1.1 WSOP LIVE Staff Page BO 기능 전체 목록

WSOP LIVE Staff Page는 아래 BO 기능을 제공한다 (Confluence Staff App API 기준):

| 영역 | API 문서 (Confluence) | 기능 |
|------|----------------------|------|
| **Auth** | [Auth.md](https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/1701380121) | 로그인/로그아웃, 토큰 갱신, 권한 조회 |
| **Competition/Series** | [Competition.md](https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/1600061448), Series.md | 대회/시리즈 CRUD |
| **Tournament** | Series Staff.md | Event/Flight 관리, Day/Blind 수정, Buy-In 수정 |
| **Tables** | [Tables API/](https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/1638793787) (16파일) | 테이블 CRUD, 좌석 배치, 이동, 해체, Complete |
| **Seat Draw** | [Seat API.md](https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/1653932041) | 자동/수동 좌석 배치 |
| **Player** | [Player Management/](https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/1654095882) | 플레이어 검색, 프로필, 밴, Credit/Debit |
| **Role/Permission** | Role 설정.md | 역할별 권한 관리 |
| **Sysop Config** | Sysop Series Setting.md | 시리즈 설정, 통화, 시간대 |
| **Audit** | [Action History.md](https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/1679556614) | 운영자 액션 이력 |
| **Report** | Report API.md | 재정 리포트, 캐셔 세션, 티켓 요약 |
| **Registration** | — | 플레이어 등록, 리엔트리, Late Registration |
| **Cashier** | [Chip Master.md](https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/2123727029) | 칩 매매, 바운티 지급, 출금 관리 |
| **Payment** | Payment API.md | 결제, Payout, Prize Pool 분배 |
| **Bounty** | [Bounty Transaction.md](https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3633283221) | 바운티 트랜잭션 |
| **Wallet** | [Player Management.md](https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/1654095882) | 플레이어 잔액, Credit/Debit |
| **KYC** | — | 본인 확인, 연령 제한, Agreement |
| **Promotion** | Promotion.md | 프로모션, Staff Mystery Bounty |
| **Subscription** | WSOP Plus Backoffice.md | WSOP+ 구독 관리 |
| **HallOfFame** | HallOfFame (Staff).md | 명예의 전당 콘텐츠 |
| **Dealer** | [Dealer.md](https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/1682178139) | 딜러 인력 관리, 배정 |
| **ExtraGame** | [ExtraGame.md](https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3633479882) | 추가 게임 (사이드 이벤트) |
| **Halo** | Halo.md | Halo 서비스 연동 |

### 1.2 EBS 채택/제거 매트릭스

| # | WSOP LIVE BO 기능 | EBS 채택 | 이유 | EBS 문서 |
|:-:|------------------|:--------:|------|----------|
| 1 | Auth (로그인/토큰) | ✅ 그대로 | 인증 필수 | BS-01, BO-02 |
| 2 | Competition/Series 관리 | ✅ 수동 생성 추가 | 대회 계층 구조 동일. API 연동 전 수동 폴백 | BO-03 |
| 3 | Tournament (Event/Flight) | ✅ 간소화 | 방송 테이블 운영에 필요한 범위만. Buy-In 읽기 전용 | BO-03 |
| 4 | Table 관리 | ✅ 핵심 | 테이블 CRUD + 상태 FSM. Feature Table 강조 | BO-04 |
| 5 | Seat Draw | ✅ 그대로 | 자동/수동 좌석 배치. 드래그 앤 드롭 | BO-04 |
| 6 | Player 관리 | ✅ 간소화 | 오버레이 표시용 정보만 (KYC/Wallet 제거) | BO-05 |
| 7 | Role/Permission | ✅ 간소화 | 3역할만 (Admin/Operator/Viewer) | BO-02 |
| 8 | Sysop Config | ✅ 글로벌 | 모든 CC에 동일 적용. 테이블별 Settings 없음 | BO-07, BS-03 |
| 9 | Audit Log | ✅ 그대로 | 운영 추적 필수 | BO-08 |
| 10 | ~~Registration~~ | ❌ 제거 | 토너먼트 운영 (플레이어 등록/리엔트리) — EBS 범위 외 |
| 11 | ~~Cashier~~ (Chip Master) | ❌ 제거 / **Phase 2+** | 금융 (칩 매매/환불) — EBS 범위 외. 단, WSOP LIVE의 InitialChipSet / RequireChips / CheckChipsQuantity 3종 실시간 이벤트 및 칩 물류 데이터 모델(chipDetailList: chipName, chipColor, value, quantity)은 **Phase 2에서 CCR 제출 예정** (방송 오버레이 칩 카운트 표시 등 연동 가능성 검토) |
| 12 | ~~Payment~~ | ❌ 제거 | 금융 (결제/Payout/Prize Pool) — EBS 범위 외 |
| 13 | ~~Bounty~~ | ❌ 제거 | 금융 (바운티 트랜잭션) — EBS 범위 외 |
| 14 | ~~Report (재정)~~ | ❌ 제거 | 금융 리포팅 (캐셔/티켓/수수료) — EBS 범위 외 |
| 15 | ~~Wallet/Credit~~ | ❌ 제거 | 금융 (플레이어 잔액) — EBS 범위 외 |
| 16 | ~~KYC~~ | ❌ 제거 | 규정 (본인 확인/연령 제한) — EBS 범위 외 |
| 17 | ~~Promotion~~ | ❌ 제거 | 마케팅 — EBS 범위 외 |
| 18 | ~~Subscription~~ | ❌ 제거 | 구독 서비스 — EBS 범위 외 |
| 19 | ~~HallOfFame~~ | ❌ 제거 | 콘텐츠 — EBS 범위 외 |
| 20 | ~~Dealer~~ | ❌ 제거 | 인력 관리 — EBS 범위 외 |
| 21 | ~~ExtraGame~~ | ❌ 제거 | 사이드 이벤트 — EBS 범위 외 |
| 22 | ~~Halo~~ | ❌ 제거 | 외부 서비스 연동 — EBS 범위 외 |

**요약**: 22개 중 **9개 채택**, **13개 제거**. 제거 기준 = 토너먼트 운영/금융/KYC/마케팅/콘텐츠/인력 관리.

### 1.3 EBS 전용 추가 기능 (WSOP LIVE에 없는 것)

| # | EBS 추가 기능 | 용도 | 채택 이유 | EBS 문서 |
|:-:|-------------|------|----------|----------|
| 1 | **RFID 디바이스 관리** | 리더 등록, 상태 추적, Mock 모드 전환 | RFID 카드 인식이 EBS Core 핵심 | BO-04 |
| 2 | **덱 등록 관리** | RFID 카드 52장 매핑, 덱 교체 이력 | Feature Table 방송에 덱 등록 필수 | BO-04 |
| 3 | **출력 장비 관리** | NDI/SDI/RTMP 출력 상태 추적 | 방송 출력 모니터링 | BO-07 |
| 4 | **오버레이 프리셋** | 스킨/레이아웃/애니메이션 관리 | 방송별 오버레이 커스터마이징 | BO-07 |
| 5 | **CC 인스턴스 추적** | 테이블당 CC 연결 상태 모니터링 | 1:N Lobby↔CC 관계에서 실시간 관제 | BO-04 |
| 6 | **핸드 기록 (Event Sourcing)** | 핸드별 카드/액션/결과 영구 저장 | RFID 기반 자동 핸드 기록 (WSOP LIVE는 별도 시스템) | BO-06 |
| 7 | **통계 계산 엔진** | VPIP/PFR/AGR 자동 계산 | 방송 오버레이 실시간 통계 표시 | BO-06, BO-11 |
| 8 | **WSOP LIVE 동기화** | API 폴링, 데이터 캐싱, Mock 데이터 | WSOP LIVE 데이터를 EBS에서 사용 | BO-10 |

---

## 2. 아키텍처

### 2.1 3-앱 관계

```
 ┌──────────────┐     ┌──────────────────┐     ┌──────────────┐
 │ Lobby (웹)   │     │  Back Office (BO) │     │ Command Center│
 │              │     │                  │     │ (Flutter)     │
 │ • 관리/설정  │REST │ • FastAPI 서버   │ WS  │ • 게임 진행   │
 │ • 1개        │◄───►│ • SQLite → PgSQL │◄───►│ • 테이블당 1개│
 │ • Admin/Op   │     │ • WebSocket Hub  │     │ • Operator    │
 └──────────────┘     │ • 66개 엔드포인트 │     └──────────────┘
                      └────────┬─────────┘
                               │ 폴링
                      ┌────────▼─────────┐
                      │ WSOP LIVE API    │
                      │ (외부, 읽기 전용) │
                      └──────────────────┘
```

- Lobby ↔ CC **직접 연동 없음** — 모든 데이터는 BO DB 경유
- Mock 모드: RFID HAL만 교체, BO는 Real/Mock 100% 동일 동작

### 2.2 기술 스택

FastAPI + SQLite(Phase 1~2) → PostgreSQL(Phase 3+), JWT → OAuth 인증, Docker 배포.

> 상세: BO-01 Overview §4 기술 스택, §4.1 Phase별 기술 진화

---

## 3. 기능 범위

각 기능의 WSOP LIVE 참조 + EBS 수정 사항을 정리한다. 상세 명세는 하위 문서 참조.

### 3.1 사용자 관리 (Auth + RBAC)

| 항목 | WSOP LIVE | EBS |
|------|----------|-----|
| 인증 방식 | Email + Password | 동일 + TOTP 2FA (Phase 1), OAuth (Phase 2+) |
| 역할 | 다수 (Admin, Staff, Floor, Cashier 등) | **3역할만**: Admin / Operator / Viewer |
| 테이블 할당 | Floor Staff에게 Section 배정 | Operator에게 테이블 직접 할당 |
| CC 접근 | — | Lobby에서 Launch만 가능 (CC 독립 로그인 없음) |

> 상세: BS-01 Auth, API-06 Auth & Session

### 3.2 대회 관리 (Series/Event/Flight)

| 항목 | WSOP LIVE | EBS |
|------|----------|-----|
| 데이터 소스 | 자체 시스템 | WSOP LIVE API 폴링 + **수동 생성 폴백** |
| Event 관리 | Registration, Buy-In, Day Close 포함 | 방송 필요 정보만 (Buy-In 읽기 전용) |
| Mix 게임 | — | **17종 이벤트 지원** (HORSE/8-Game/PPC/Dealer's Choice) |
| BlindStructure | Event 인라인 | 동일 (Event 생성 시 인라인 설정) |

> 상세: BS-02 Lobby §화면 1~3, API-01 §Competition~Flight

### 3.3 테이블 관리 (CRUD + FSM + RFID)

| 항목 | WSOP LIVE | EBS |
|------|----------|-----|
| 테이블 CRUD | 생성/수정/삭제/이동/해체 | 동일 + **Feature Table 구분** |
| 상태 FSM | Open → Live → Complete | EMPTY → SETUP → LIVE → COMPLETED |
| 좌석 배치 | Seat Draw (자동/수동) | 동일 (드래그 앤 드롭) |
| RFID 리더 | — | **Feature Table에 RFID 리더 할당 필수** |
| 덱 등록 | — | **52장 RFID 카드 매핑** |
| 출력 상태 | — | **NDI/SDI 출력 장비 추적** |
| CC 연결 | — | **테이블당 CC 인스턴스 상태 모니터링** |

> 상세: BS-02 Lobby §화면 4, API-01 §Tables, BS-04 RFID

### 3.4 플레이어 DB (캐싱 + 검색)

| 항목 | WSOP LIVE | EBS |
|------|----------|-----|
| 데이터 소스 | 자체 DB + GGPass | WSOP LIVE API 캐싱 + 수동 등록 |
| 프로필 | 이름, 국적, 사진, KYC, Wallet | 이름, 국적, 사진만 (KYC/Wallet 제거) |
| 통계 | — | **VPIP/PFR/AGR 자동 계산** (Hand History 기반) |

> 상세: BS-02 Lobby §화면 5, API-01 §Players

### 3.5 핸드 기록 (Event Sourcing + 통계)

| 항목 | WSOP LIVE | EBS |
|------|----------|-----|
| 핸드 기록 | 별도 시스템 (PokerGFX) | **BO에서 직접 Event Sourcing 저장** |
| 데이터 | — | 카드, 액션, 팟, 승자, 보드, 타이밍 |
| 통계 | — | VPIP, PFR, AGR, Win%, Cumulative P&L |
| JSON Export | — | 핸드 기록 JSON 내보내기 (후편집용) |

> 상세: BS-02 Lobby §Hand History, API-01 §Hands, DATA-02 §hands

### 3.6 시스템 설정 (글로벌 Config)

| 항목 | WSOP LIVE | EBS |
|------|----------|-----|
| 설정 범위 | Series/Event 단위 | **글로벌** (모든 CC 동일 적용, 테이블별 없음) |
| 6탭 | — | Outputs / GFX / Display / Rules / Stats / Preferences |
| 적용 시점 | — | IDLE → 즉시, 핸드 진행 중 → 다음 핸드 |
| RFID 모드 | — | Real / Mock 전환 (IDLE 상태에서만) |

> 상세: BS-03 Settings, API-01 §Configs

### 3.7 감사 로그

| 항목 | WSOP LIVE | EBS |
|------|----------|-----|
| 기록 대상 | Action History | 동일 + CC Launch/종료, RFID 상태 변경, 설정 변경 |
| 보존 | — | 영구 보존 (soft delete 없음) |

> 상세: BO-03 Operations §감사 로그

### 3.8 데이터 동기화 (Lobby↔BO↔CC)

| 항목 | WSOP LIVE | EBS |
|------|----------|-----|
| 통신 | 자체 프로토콜 | REST API + WebSocket |
| 오프라인 | — | CC 로컬 캐시 모드 (게임 계속 진행, 복구 시 동기화) |
| 충돌 해결 | — | Last-Write-Wins, 409 Conflict → 리프레시 |

> 상세: BO-02 Sync Protocol, API-05 WebSocket Events

### 3.9 WSOP LIVE 동기화 (API 폴링)

| 항목 | WSOP LIVE | EBS |
|------|----------|-----|
| 방향 | — | WSOP LIVE → BO (단방향, 읽기 전용) |
| 폴링 주기 | — | Series 1시간, Event/Flight 5분, Player 10분 |
| `source` 필드 | — | `api` (동기화) / `manual` (수동 생성) 구분 |
| Mock 데이터 | — | API 미연결 시 시드 데이터로 독립 운영 |

> 상세: BO-02 Sync Protocol §WSOP LIVE, API-02 WSOP LIVE Integration

### 3.10 리포팅 (통계/내보내기)

| 항목 | WSOP LIVE | EBS |
|------|----------|-----|
| 재정 리포트 | 캐셔/수수료/Payout | **제거** (금융 범위 외) |
| 방송 통계 | — | 플레이어별 VPIP/PFR/AGR, 핸드당 팟/시간/액션 |
| 내보내기 | — | Hand History JSON, 플레이어 통계 CSV |

> 상세: BO-03 Operations §리포팅

---

## 4. Phase별 도입 로드맵

| Phase | 기간 | BO 기능 범위 | DB | 인증 |
|:-----:|------|------------|:--:|:----:|
| **1** | 2026 상반기 | Auth + Config + Mock RFID 모드 | SQLite | Email + 2FA |
| **2** | 2026 하반기 | + Table CRUD, Seat, Player, Hand History (Hold'em 1종) | SQLite | + Google OAuth |
| **3** | 2027 상반기 | + 9종 게임, WSOP LIVE Sync, 통계 엔진 | PostgreSQL | + Entra ID |
| **4** | 2027 하반기 | **전격 운영** — 13종 추가, 스킨 에디터, Audit, Reporting | PostgreSQL | Hybrid |
| **5** | 2028 상반기 | AI 무인화 (자동 카메라/자동 게임 진행) | PostgreSQL | Hybrid |

---

## 5. 하위 문서 참조

### BO 상세 명세 (docs/back-office/)

| ID | 제목 | 역할 |
|----|------|------|
| BO-01 | Architecture | 3-앱 아키텍처, 기술 스택, Phase별 진화, 성능 요구사항 |
| BO-02 | Sync Protocol | Lobby↔BO↔CC 동기화 정책, 오프라인 대응, 충돌 해결, WSOP LIVE 폴링 |
| BO-03 | Operations | 감사 로그 기록 대상/보존 정책, 리포트 카탈로그, 내보내기 |

> CRUD/데이터 모델/유저 스토리는 BS(행동 명세) + API + DATA 문서가 SSOT

### API 계약 (contracts/api/)

| ID | 제목 | 역할 |
|----|------|------|
| API-01 | Backend Endpoints | REST API 전체 카탈로그 (66개) |
| API-02 | WSOP LIVE Integration | WSOP LIVE → BO 연동 계약 |
| API-03 | RFID HAL Interface | RFID 리더 추상 인터페이스 |
| API-04 | Overlay Output | CC→Overlay 데이터 흐름 |
| API-05 | WebSocket Events | 실시간 이벤트 프로토콜 |
| API-06 | Auth & Session | JWT 인증 계약 |

### 데이터 모델 (contracts/data/)

| ID | 제목 | 역할 |
|----|------|------|
| DATA-01 | ER Diagram | 엔티티 관계도 |
| DATA-02 | Entities | 필드 정의 (124개) |
| DATA-03 | State Machines | FSM 상태 전이 |
| DATA-04 | DB Schema | SQLAlchemy 스키마 |
| DATA-05 | Migrations | Alembic 마이그레이션 |
| DATA-06 | Seed Data | 개발/테스트 시드 |
