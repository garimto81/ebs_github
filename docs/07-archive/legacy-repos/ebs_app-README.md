# ebs_app — EBS POC (Phase 1 vertical slice)

`C:\claude\ebs_app\` 는 EBS(Live Poker Broadcast System)의 **Phase 1 POC 수직 슬라이스**다. 기획 레포(`C:\claude\ebs`, `garimto81/ebs`)의 실행 짝(sibling)이며, RFID 하드웨어 없이 5단계 데모 시나리오를 끝까지 돌릴 수 있도록 만들었다.

> **목표**: PRD `docs/01-strategy/PRD-EBS_Foundation.md` v41.0.0 §"Phase 1 POC 데모 시나리오" (line 1002-1011) 5단계를 한 번에 완주.

## POC 5단계와 화면 매핑

| # | 시나리오 (PRD §21) | 화면 | 비고 |
|:-:|---|---|---|
| 1 | 로그인 (Mock) | `LoginScreen` | 운영자 이름만 입력. 실제 RBAC는 BS-01-auth 작성 후 연결 |
| 2 | 카드덱 등록 (Real RFID — POC에선 Mock) | `LobbyScreen` → `DeckRegistrationScreen` | 52장 자동 시나리오 + 수동 주입 모두 지원 |
| 3 | 게임 초기 설정 (Mock) | `LobbyScreen`에서 6명 mock player 자동 시팅 | 단일 테이블 / 홀덤 / 6 seats 하드코딩 |
| 4 | RFID 입력 (Real → Mock) | `CommandCenterScreen` 우측 Manual injector + FakeReader | `RfidReader` 추상 인터페이스로 격리 |
| 5 | 오버레이 출력 (Real) | `OverlayScreen` (녹색 펠트 + 5장 커뮤니티) | Phase 2에서 Rive 합성으로 교체 |

## 디렉터리 구조

```
ebs_app/
├── lib/
│   ├── main.dart                          # ProviderScope + EbsApp 루트
│   ├── models/
│   │   ├── card.dart                      # Suit, Rank, PlayingCard, CardSlot
│   │   ├── player.dart                    # Player (seat/name/stack/holeCards)
│   │   └── game_session.dart              # SessionPhase, Street, GameSession 상태
│   ├── services/
│   │   └── rfid/
│   │       ├── rfid_reader.dart           # 추상 인터페이스 — 실하드웨어 교체 지점
│   │       └── fake_rfid_reader.dart      # 시나리오 재생 + 수동 inject
│   ├── providers/
│   │   └── game_session_provider.dart     # Riverpod StateNotifier + RFID 라우팅
│   └── screens/
│       ├── login_screen.dart              # POC step 1
│       ├── lobby_screen.dart              # POC step 2 (테이블 선택)
│       ├── deck_registration_screen.dart  # POC step 2 (계속 — 52장 등록)
│       ├── command_center_screen.dart     # POC step 3+4 (액션 + 수동 inject)
│       └── overlay_screen.dart            # POC step 5 (방송 출력)
└── test/
    ├── fake_rfid_reader_test.dart         # 3 tests
    ├── game_session_test.dart             # 5 tests
    └── widget_test.dart                   # 2 tests
```

## 실행

```bash
cd C:/claude/ebs_app
flutter pub get
flutter run -d windows
```

### 데모 흐름

1. **로그인 화면**: "Aiden" (또는 임의 이름) → `로그인`
2. **Lobby**: `Feature Table 1` 카드 탭
3. **Deck Registration**: `자동 시나리오 재생 (FakeReader)` 버튼 → 진행률 바가 0/52에서 52/52로 채워짐. 또는 수동으로 카드를 한 장씩 inject 가능
4. **Live 진입** 버튼 활성화 → 클릭
5. **Command Center**:
   - 우측 Manual injector 패널에서 Suit/Rank 선택 → `Inject card`로 커뮤니티 카드 1장씩 추가
   - `Advance street`로 Preflop → Flop → Turn → River → Showdown 진행
   - 우상단 TV 아이콘으로 **Overlay 화면** 새 창 (Navigator push)
6. **Overlay 화면**: 녹색 펠트 위에 커뮤니티 카드 5장이 실시간으로 표시됨

## 테스트

```bash
flutter test       # 10 tests, 모두 green
flutter analyze    # 0 issues
```

테스트 분포:
- `fake_rfid_reader_test.dart` — 3건: manual inject, 52장 deck, scenario playback
- `game_session_test.dart` — 5건: 초기상태, login→lobby→deck, RFID 누적 및 중복 무시, deckComplete 게이트, 스트리트 전이
- `widget_test.dart` — 2건: 로그인 화면 렌더, 로그인 → Lobby 네비게이션

## RFID 하드웨어 교체 지점

```
GameSessionController
        ▲
        │ depends on
        │
   RfidReader (abstract)        ← 이 인터페이스만 의존
        ▲
        ├── FakeRfidReader      ← 현재 (POC)
        └── St25R3911bReader    ← 미래 (ebs(HW)/ebs(FW) sibling repo가 채움)
```

`lib/providers/game_session_provider.dart`의 `rfidReaderProvider` 한 줄만 교체하면 실하드웨어로 전환된다. 화면/상태 어디도 `FakeRfidReader`를 직접 import 하지 않는다.

## 기획 레포와의 관계

- **기획 (PRD/디자인/행동명세)**: `C:\claude\ebs` (`garimto81/ebs`) — `docs/01-strategy/`, `docs/02-behavioral/`, `docs/08-rules/`. `CLAUDE.md` 명시: 기획 레포에는 src/ 금지.
- **실행 (이 레포)**: `C:\claude\ebs_app` — Flutter 앱 코드 + 단위 테스트.
- **참조 brigde 문서**: `C:\claude\ebs\docs\01-plan\ebs-implementation-roadmap.plan.md` — 어떤 캐노니컬 feature ID(MW-/G1-/SYS-/...)가 어느 sibling 레포로 가는지 매핑.

## POC 범위 밖 (Phase 2 이후)

| 항목 | Phase | 예정 위치 |
|---|:---:|---|
| 베팅 액션 풀 구현 (NL/PL/FL × Ante × Straddle) | 2 | `lib/game_engine/` |
| 사이드팟/올인 처리 | 2 | 동상 |
| Hand history JSON export | 2 | 동상 |
| Rive `.riv` 오버레이 | 2 | `assets/overlays/` + `ui_overlay` sibling |
| 실제 RFID 드라이버 (ST25R3911B) | 1 (HW) | `ebs(HW)` + `ebs(FW)` sibling repos |
| RBAC (Admin/Operator/Viewer) | 2 | `lib/services/auth/` |
| Settings 4섹션 (Output/Overlay/Game/Stats) | 2 | `lib/screens/settings/` |
| 22종 게임 확장 | 3 | `lib/game_engine/games/` |
