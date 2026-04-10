# EBS Behavioral Specs — 행동 명세 가이드

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-02 | 신규 작성 | 행동 명세 체계 정의, 폴더 구조 설계 |
| 2026-04-08 | 전체 완성 | BS-00~07 모든 문서 작성 완료. 진행률 표 추가 |

---

## 개요

이 디렉토리는 EBS의 **기능별 행동 명세**를 관리한다. 각 문서는 기능의 모든 경우의 수를 열거하고, 페르소나(운영자) 관점의 유저 스토리로 기술한다.

**문서 순서 = 운영자의 방송 하루 순서:**

```
① 로그인 → ② 테이블 설정 → ③ 출력/오버레이 준비 → ④ 덱 등록
→ ⑤ 게임 진행 → ⑥ 시스템 내부 처리 → ⑦ 시청자 화면 출력
```

---

## 폴더 구조

```
02-behavioral/
├── README.md                    이 문서 (체계 정의)
├── BS-00-definitions.md         용어/상태/트리거 총괄 정의서
├── BS-01-auth/                  ① "로그인한다"
├── BS-02-lobby/                 ② "테이블을 설정한다"
├── BS-03-settings/              ③ "방송을 준비한다" (구 Console → Settings 흡수)
├── BS-04-rfid/                  ④ "덱을 등록한다"
├── BS-05-command-center/        ⑤ "게임을 진행한다"
├── BS-06-game-engine/           ⑥ "시스템이 내부 처리한다"
└── BS-07-overlay/               ⑦ "시청자가 화면을 본다"
```

---

## Confluence 매핑

| 로컬 | Confluence | Page ID |
|------|-----------|---------|
| `02-behavioral/` | `02_Behavioral Specs` | 3726147739 |
| `BS-00` | `BS-00 Definitions` | 3726901277 |
| `BS-01-auth/` | `BS-01 Auth` | 3726868546 |
| `BS-02-lobby/` | `BS-02 Lobby` | 3726901296 |
| `BS-03-settings/` | `BS-03 Settings` | 3724443935 |
| `BS-04-rfid/` | `BS-04 RFID` | 3726901315 |
| `BS-05-command-center/` | `BS-05 Command Center` | 3724280058 |
| `BS-06-game-engine/` | `BS-06 Game Engine` | 3726901334 |
| `BS-07-overlay/` | `BS-07 Overlay` | 3725197552 |

---

## 문서 작성 표준

**WSOP LIVE Confluence 문서 표준을 정확히 따른다.** 상세: `CLAUDE.md > 문서 작성 표준` 참조.

### 각 문서 필수 구조

```markdown
# [기능명]

| 날짜 | 항목 | 내용 |
|------|------|------|
| YYYY-MM-DD | 신규 작성 | ... |

---

## 개요
> 1~3줄 목적 요약

## 정의
> 이 기능이 정확히 무엇인지 1문장

## 트리거
| 트리거 유형 | 조건 | 발동 주체 |
|-----------|------|---------|
| CC 버튼 클릭 | [상태 조건] | 운영자 (수동) |
| RFID 카드 인식 | [하드웨어 조건] | 시스템 (자동) |
| 게임 상태 전환 | [FSM 조건] | 게임 엔진 (자동) |

## 전제조건
- [이 기능이 작동하려면 반드시 참이어야 하는 조건]

## 유저 스토리
| # | As a | When | Then | Edge Case |
|:-:|------|------|------|-----------|
| 1 | 운영자 | [트리거 상황] | [시스템 반응] | — |

## 경우의 수 매트릭스
| 조건 A | 조건 B | 조건 C | 시스템 반응 |
|:------:|:------:|:------:|-----------|
| ✅ | ✅ | ✅ | [반응 1] |
| ✅ | ✅ | ❌ | [반응 2] |

## 비활성 조건
- [이 기능을 사용할 수 없는 조건]

## 영향 받는 요소
- [연동되는 다른 기능/화면]
```

---

## 트리거 3가지 소스 (BS-06-00에서 총괄 정의)

모든 행동 명세에서 트리거는 반드시 **발동 주체**를 명시한다:

| 소스 | 주체 | 예시 |
|------|------|------|
| **CC 버튼** | 운영자 (수동) | NEW HAND, DEAL, FOLD, CHECK, BET, CALL, RAISE, ALL-IN |
| **RFID 감지** | 시스템 (자동) | 홀카드 감지, 보드 카드 감지, 덱 등록 |
| **게임 엔진** | 시스템 (자동) | 베팅 완료 → Flop 공개, Showdown → 팟 분배 |

> **경계 규칙**: CC 버튼과 RFID 감지가 동시에 발생할 수 있는 경우, 우선순위를 BS-06-00에서 정의한다.

---

## 도메인별 범위

### BS-01 Auth
- 로그인 시나리오, 역할별 접근 매트릭스
- 세션 관리, 로그아웃, 재인증

### BS-02 Lobby
- 테이블 CRUD, 상태 전환 (Empty/Setup/Live)
- 게임 설정 플로우, 플레이어 등록/좌석 배치
- RBAC (Admin: 전체, Operator: 할당 테이블, Viewer: 읽기)

### BS-03 Settings (구 Console → 흡수)

**변경**: Foundation "3화면(Lobby/CC/Console)" → "2화면(Lobby/CC) + Settings(메뉴)"

Console은 독립 화면에서 **Settings 다이얼로그**로 흡수된다.
- Admin은 Lobby/CC 어디서든 Settings 접근 가능
- OBS/vMix도 Settings = 메뉴 다이얼로그 (독립 화면 아님)

**4섹션 구조** (기존 5탭에서 재편):

| 섹션 | 내용 | 기존 탭 |
|------|------|---------|
| **Output** | NDI/HDMI 송출 설정, 해상도 | Outputs |
| **Overlay** | 스킨 선택, 레이아웃, 배치, 해상도 대응 | GFX + Display 병합 |
| **Game** | 게임 규칙, 베팅 구조, 플레이어 표시 | Rules |
| **Statistics** | 통계 표시, Equity, Leaderboard | Stats |

### BS-04 RFID
- 덱 등록 프로세스 (52장 전수 스캔)
- 카드 감지 시나리오 (정상/미인식/중복/장애)
- 에러 복구 (수동 입력 폴백)

### BS-05 Command Center
- 운영자 핸드 진행 워크플로우
- 8개 액션 버튼별 모든 경우의 수 (게임 상태 × BiggestBet × 스택)
- 좌석 관리, 수동 카드 입력, 키보드 단축키
- Undo 5단계 + 에러 복구

### BS-06 Game Engine
- **트리거 정의 총괄** (BS-06-00) — 가장 중요한 문서
- 핸드 라이프사이클 (IDLE → ... → HAND_COMPLETE)
- 베팅 액션 모든 경우의 수 (NL/PL/FL × 7 Ante × 4 특수)
- RFID vs 수동 카드 인식 경계 정의
- 핸드 평가 (Hi/Lo/Badugi/Short Deck)
- 승률 계산 트리거/조건
- 특수 상황 완전 열거 (Bomb Pot, Run It Twice, Miss Deal, All Fold)
- 22종 게임별 차이 정의

### BS-07 Overlay
- 10개 오버레이 요소별 트리거/갱신 조건
- 애니메이션 발동 조건 (카드 등장, 승률 업데이트, 액션 배지)
- 스킨 로드/전환 시나리오

---

## 작성 진행률 (2026-04-08 완료)

| BS | 영역 | 파일 수 | 상태 |
|----|------|:------:|:----:|
| **BS-00** | 정의서 | 1 | ✅ 완성 |
| **BS-01** | Auth | 1 | ✅ 완성 |
| **BS-02** | Lobby | 1 | ✅ 완성 (기존) |
| **BS-03** | Settings | 5 | ✅ 완성 |
| **BS-04** | RFID | 5 | ✅ 완성 |
| **BS-05** | Command Center | 7 | ✅ 완성 |
| **BS-06** | Game Engine | 2 + 17(engine-spec) | ✅ 완성 |
| **BS-07** | Overlay | 5 | ✅ 완성 |

---

## 기존 자산 활용

| 신규 행동 명세 | 활용 가능한 기존 자산 | 위치 |
|-------------|-------------------|------|
| BS-05 CC | AT Design Rationale + 44기능 + 8화면 목업 | `C:\claude\ebs_ui\ebs-action-tracker\` |
| BS-03 Settings | Console v9.7.0 (99+ 설정 필드) | `C:\claude\ebs_ui\ebs-console\` |
| BS-06 Engine | game-state-machine (35K) + AT 프로토콜 (68개) | `docs/07-archive/01-pokergfx-analysis/` |
| BS-07 Overlay | element-catalog (88 Keep) + feature-interactions (148K) | `docs/07-archive/01-pokergfx-analysis/` |
