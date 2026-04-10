# EBS 용어 사전

> EBS PRD 및 설계 문서에서 사용되는 주요 용어 해설

---

## 포커 기본 용어

| 용어 | 설명 |
|------|------|
| **Hole Card** | 플레이어에게 비공개로 배분되는 카드. Hold'em은 2장, Omaha는 4~6장 |
| **Community Card** | 테이블 중앙에 공개되는 공유 카드. 전체 플레이어가 공통으로 사용 |
| **Flop** | 커뮤니티 카드 3장을 동시에 공개하는 첫 번째 단계 |
| **Turn** | 4번째 커뮤니티 카드. Flop 이후 한 장 추가 공개 |
| **River** | 5번째 커뮤니티 카드. 마지막으로 공개되는 카드 |
| **Showdown** | 남은 플레이어들이 카드를 공개하여 승자를 결정하는 단계 |
| **Fold** | 패를 포기하고 핸드에서 이탈. 베팅 금액을 잃고 다음 핸드까지 대기 |
| **Call** | 현재 베팅 금액과 동일한 금액을 베팅하여 핸드에 계속 참여 |
| **Raise** | 현재 베팅 금액보다 높은 금액을 베팅 |
| **All-in** | 보유한 전체 칩을 베팅. 이후 추가 베팅 불가 |
| **Check** | 베팅하지 않고 다음 플레이어에게 차례를 넘김. 베팅이 없을 때만 가능 |
| **Blind** | 매 핸드마다 특정 위치 플레이어가 의무적으로 납부하는 베팅 (SB/BB) |
| **Ante** | 매 핸드 시작 전 전원 또는 일부가 의무적으로 납부하는 소액 베팅 |
| **Pot** | 해당 핸드에서 누적된 총 베팅 금액. 승자가 가져감 |
| **Side Pot** | All-in 플레이어와 나머지 플레이어 간의 별도 팟. 복수 All-in 시 다중 Side Pot 생성 |
| **Button** | 딜러 위치를 표시하는 마커. 매 핸드마다 시계 방향으로 이동 |
| **Muck** | 카드를 공개하지 않고 포기하거나 버리는 행위. Showdown에서 패배 확정 시 자주 사용 |
| **Outs** | 현재 핸드를 완성시킬 수 있는 남은 카드의 수. Equity 계산의 기초 |

---

## 베팅 용어

| 용어 | 설명 |
|------|------|
| **No Limit** | 레이즈 금액에 상한이 없는 베팅 구조. All-in까지 가능 |
| **Fixed Limit** | 정해진 단위로만 베팅/레이즈가 가능한 구조. 보통 Cap(4 Bet 제한) 적용 |
| **Pot Limit** | 현재 팟 크기 이하로만 레이즈 가능. PLO(Pot Limit Omaha)가 대표적 |
| **Straddle** | 자발적으로 추가하는 3번째 블라인드. 보통 Big Blind의 2배 금액 |
| **Bomb Pot** | 전원이 합의된 금액을 납부한 뒤 Pre-Flop 베팅을 건너뛰고 바로 Flop부터 시작 |
| **Run It Twice** | All-in 후 남은 보드 카드를 2회 전개하여 팟을 절반씩 분할. 분산(Variance) 감소 효과 |
| **7-2 Side Bet** | 7-2 오프슈트(최약 핸드)로 이겼을 때 사이드벳을 수취하는 특수 규칙 |

---

## Ante 유형

| Ante 유형 | 납부자 | 설명 |
|-----------|--------|------|
| **Standard** | 전원 | 전체 플레이어가 동일 금액을 납부하는 기본 방식 |
| **Button** | 딜러만 | 딜러 버튼 위치의 플레이어만 Ante를 납부 |
| **BB Ante** | Big Blind만 | Big Blind 플레이어가 전원의 Ante를 대납. 2018년 이후 대부분의 메인 토너먼트에서 채택 |
| **BB Ante (BB 1st)** | Big Blind만 | BB Ante 방식 + Big Blind가 Pre-Flop에서 먼저 행동 |
| **Live Ante** | 전원 | Ante가 "라이브 머니"로 취급되어 첫 베팅 라운드에서 해당 플레이어의 베팅으로 인정됨. 앤티를 낸 플레이어는 Check 대신 Raise 옵션을 가지며, 콜 시 앤티 금액 차감 가능. 주로 캐시 게임에서 사용 |
| **TB Ante** | SB + BB | Small Blind와 Big Blind가 합산하여 Ante 납부 |
| **TB Ante (TB 1st)** | SB + BB | TB Ante 방식 + SB/BB가 먼저 행동 |

> **참고**: BB Ante는 게임 진행 속도를 높이고 수납 실수를 줄이기 위해 도입되었다. 하지만 일부 토너먼트는 Standard Ante를 유지하기도 한다.

---

## 통계 용어

| 용어 | 설명 |
|------|------|
| **VPIP** | Voluntarily Put money In Pot — 자발적으로 팟에 참여한 비율. 높을수록 루즈(Loose) 플레이어 |
| **PFR** | Pre-Flop Raise — 프리플롭에서 레이즈한 비율. VPIP와 함께 플레이어 스타일 분류의 핵심 지표 |
| **AF** (AGR) | Aggression Factor — 공격적 플레이 비율. (Bet + Raise) / Call로 계산 |
| **WTSD** | Went To ShowDown — 쇼다운까지 간 비율. 높을수록 끈질긴 플레이어 |
| **3Bet%** | Three-Bet Percentage — 상대의 레이즈에 대해 리레이즈한 빈도 |
| **CBet%** | Continuation Bet Percentage — Flop에서 Pre-Flop 어그레서가 지속 베팅한 빈도 |
| **WIN%** | Win Rate — 핸드 승률. 전체 플레이한 핸드 중 승리한 비율 |
| **AFq** | Aggression Frequency — 공격 빈도. Bet/Raise 액션의 빈도를 측정 |
| **ICM** | Independent Chip Model — 칩을 기반으로 토너먼트 내 가치를 계산하는 수학적 모델 |
| **Equity** | 현재 핸드 상태에서 팟을 획득할 수 있는 기댓값 비율. Monte Carlo 시뮬레이션으로 계산 |

> 이 통계들은 플레이어의 플레이 스타일을 정량화하며, GTO(Game Theory Optimal) 전략 수립의 기초 데이터로 활용된다.

---

## 카드 상태

52장 카드는 사전 등록(REGISTER_DECK) 후 핸드 진행 중 5가지 상태를 순환한다:

| 상태 | 설명 |
|------|------|
| **DECK** | 미감지 상태. 덱에 남아 있는 카드 |
| **DETECTED** | RFID로 감지되었으나 아직 게임 엔진에 등록되지 않은 카드. 안테나 번호(0~9)로 좌석이 하드웨어적으로 확정됨 |
| **DEALT** | 게임 엔진에 핸드 카드로 등록된 상태. PLAYER_CARDS 명령 발행 후 전환 |
| **REVEALED** | Showdown에서 공개된 카드. 방송 화면에 표시 |
| **MUCKED** | 공개되지 않고 포기된 카드. Fold 또는 Showdown에서 패배 확정 시 |

> **전체 52장 추적 예시** (10인 Hold'em): 홀카드 20장(DEALT) + 보드 0~5장(DETECTED→DEALT) + Muck 가변(MUCKED) + 나머지(DECK) = **항상 52장**

---

## 시스템 용어

| 용어 | 설명 |
|------|------|
| **Dual Canvas** | Venue Canvas와 Broadcast Canvas 두 개의 독립적인 렌더링 화면을 동시에 제공하는 핵심 아키텍처 |
| **Venue Canvas** | 실시간 현장 모니터용 화면. 홀카드는 숨김 처리되어 플레이어 간 공정성 보장 |
| **Broadcast Canvas** | 실시간 방송 송출용 화면. 홀카드를 공개하여 시청자에게 정보 제공 |
| **Security Delay Buffer** | Broadcast Canvas에 적용하는 보안 딜레이 (0~30분). Dual Canvas와 별개의 보안 기능으로, 시청자가 실시간 정보를 보면서 부정 행위를 할 가능성 차단 |
| **Trustless Mode** | Venue Canvas에서 홀카드를 절대 표시하지 않는 보안 모드. Showdown 이후에만 공개 |
| **NDI** | Network Device Interface — 네트워크 기반 비디오 전송 프로토콜. 낮은 지연시간으로 고품질 영상 전송 |
| **RFID** | Radio Frequency Identification — 무선 주파수 식별 기술. 카드에 내장된 태그를 감지하여 실시간 추적 |
| **NTAG215** | NFC Forum Type 2 태그 규격. 카드 내장용 RFID 태그로 사용 |
| **Skin** | 방송 그래픽의 시각적 테마 패키지. `.vpt` 또는 `.skn` 확장자로 저장 |
| **ConfigurationPreset** | Skin의 99+ 설정 필드 데이터 구조. 레이아웃, 색상, 폰트, 애니메이션 등 모든 시각 요소 정의 |
| **Master-Slave** | 다중 서버 구성. Master는 원본 소스, Slave는 동기화된 복제 서버. 백업 및 다중 출력용 |
| **Action Tracker** | GFX 운영자용 터치스크린 게임 진행 앱. 베팅 액션, 팟 관리, 핸드 제어 등을 실시간 입력 |
| **Monte Carlo** | 무작위 시뮬레이션 기반 확률 계산 방법. 수만~수십만 회 시뮬레이션으로 Equity 계산 |
| **PocketHand169** | Pre-Flop 2장 조합의 169개 전략적 분류. Suited/Unsuited, Pair 등으로 그룹화 |
| **Lookup Table** | 사전 계산된 O(1) 조회 테이블. 핸드 랭크, Equity 등을 즉시 조회하여 성능 최적화 |
| **ATEM** | Blackmagic Design 비디오 스위처. PokerGFX의 주요 방송 장비 연동 대상 |
| **ToggleTrust** | Trustless Mode를 활성화/비활성화하는 명령어. 활성화 시 Venue Canvas에서 어떤 상황에서도 홀카드가 표시되지 않음 |
| **SetTicker** | 뉴스 티커 설정 명령어. 방송 화면 하단에 수평으로 스크롤되는 텍스트(속보, 이벤트 정보, 스폰서 메시지 등) 표시 |
| **Master-Secondary** | 출력 분산 구성. Master 서버가 게임 상태를 관리하고, Secondary(벤치마크 원본 용어: Slave) 서버가 추가 캔버스 출력만 담당. PRD v2에서 Master-Secondary로 표기, 역공학 문서에서는 원본 용어 Master-Slave 유지 |

---

## 그래픽 요소

모든 방송 그래픽은 4가지 기본 요소의 조합으로 구성된다:

| 요소 | 필드 수 | 용도 |
|------|:-------:|------|
| **Image** | 41 | 카드 이미지, 로고, 배경 등. x, y, width, height, alpha, source, crop, rotation, z_order, animation 포함 |
| **Text** | 52 | 플레이어 이름, 칩 카운트, 승률, 팟 정보 등. font, size, color, alignment, shadow, auto_fit, animation 포함 |
| **Pip** | 12 | PIP(Picture-in-Picture) — 카메라 입력을 캔버스의 임의 위치에 배치하는 요소. 소스 영역(src_rect)에서 캡처한 비디오를 대상 영역(dst_rect)에 렌더링. src_rect, dst_rect, opacity, z_pos, dev_index, scale, crop 포함 |
| **Border** | 8 | 테두리, 구분선, 강조 표시 등. color, thickness, radius 포함 |

---

## 애니메이션

16개 Animation State와 11개 Animation Class를 조합하여 동적 효과 구현:

| Animation Class | 설명 |
|----------------|------|
| **FadeIn/FadeOut** | 투명도 전환. 요소의 등장/퇴장 연출 |
| **SlideLeft/Right** | 수평 슬라이드. 좌우 이동 효과 |
| **SlideUp/Down** | 수직 슬라이드. 상하 이동 효과 |
| **ScaleIn/Out** | 크기 전환. 확대/축소 효과 |
| **FlipHorizontal/Vertical** | 수평/수직 뒤집기. 카드 공개 시 주로 사용 |
| **Pulse** | 반복 강조. 주기적인 크기 변화로 주의 환기 |
| **Flash** | 깜빡임. 빠른 투명도 전환 반복 |
| **Bounce** | 탄성 효과. 바운스 모션으로 생동감 부여 |
| **Rotate** | 회전. 360도 회전 효과 |
| **Custom** | 커스텀 키프레임. 사용자 정의 애니메이션 곡선 |

---

## 핸드 등급

포커 핸드는 9등급으로 분류된다. 낮은 등급일수록 강한 핸드:

| 등급 | 이름 | 확률 |
|:----:|------|-----:|
| 9 | Royal Flush | 0.0002% |
| 8 | Straight Flush | 0.0013% |
| 7 | Four of a Kind | 0.024% |
| 6 | Full House | 0.14% |
| 5 | Flush | 0.20% |
| 4 | Straight | 0.39% |
| 3 | Three of a Kind | 2.11% |
| 2 | Two Pair | 4.75% |
| 1 | One Pair | 42.26% |
| 0 | High Card | 50.12% |

---

> **Version**: 2.0.0
> **Source**: pokergfx-prd-v2.md v28.0.0
> **Last Updated**: 2026-02-19
