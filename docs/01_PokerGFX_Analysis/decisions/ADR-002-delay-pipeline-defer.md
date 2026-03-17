# ADR-002: Delay Pipeline v2.0 Defer

## 상태
확정

## 맥락

PokerGFX의 Outputs 탭은 Live 파이프라인과 Delay 파이프라인을 병렬로 운영하는 이중 출력 구조를 지원한다. Delay 파이프라인은 보안 딜레이(일반적으로 수 분)를 적용한 별도 스트림을 출력하며, 고스테이크 현금 게임에서 핸드 중 카드 정보 노출을 방지하기 위한 용도로 사용된다.

PokerGFX 원본의 Delay 관련 요소는 두 계층으로 나뉜다. 첫째, Delay 파이프라인 자체(O-06: Delay Video/Audio/Device, O-07: Delay Key & Fill)는 Live와 독립된 별도 출력 채널이다. 둘째, 보안 딜레이 제어 UI(O-08~O-12: Secure Delay Time, Dynamic Delay, Auto Stream, Show Countdown, Countdown Video+BG)는 딜레이 시간 설정 및 카운트다운 연출 기능이다. Main Window의 M-04(Secure Delay+Preview 체크박스)도 이 파이프라인의 진입점이다.

EBS v1.0 설계 단계에서 이중 출력 구조를 포함할지 여부를 결정해야 했다. 두 계층의 기술적 복잡도와 운영 우선순위가 달라 분리된 결정이 필요했다.

## 결정

- **O-06~O-07 (Delay 파이프라인)**: v2.0 Defer. v1.0은 Live 단일 출력 구조로 운영한다.
- **O-08~O-12 (보안 딜레이 제어 UI)**: Drop 확정. 파이프라인 자체가 없으므로 제어 UI도 불필요하다.
- **M-08 (Secure Delay+Preview 체크박스)**: v1.0에서 Drop(PokerGFX 원본 #4). EBS 신규 M-08은 별도 기능으로 재정의.

## 근거

| 근거 | 내용 |
|------|------|
| 기술적 복잡도 | Delay 파이프라인은 비디오 버퍼링(수 분 분량), 오디오-비디오 동기화, DeckLink 이중 채널 관리가 필요하다. v1.0 로드맵에 적합하지 않은 구현 비용 |
| v1.0 목표 집중 | v1.0 핵심 목표는 RFID+AT+기본 GFX다. Live 단일 출력으로 방송 운영이 가능하며, 보안 딜레이는 선택적 고급 기능 |
| 보안 딜레이 운영 현황 | 현재 운영 환경에서 보안 딜레이가 필수 요건으로 요청되지 않음. 필요 시 외부 스위처(ATEM 등)에서 딜레이 처리 가능 |
| Drop vs Defer 분리 | O-06~O-07은 추후 방송 규모 확대 시 필요할 수 있으므로 Defer. O-08~O-12는 파이프라인 없이 단독 의미가 없으므로 Drop |

## 영향

- **Defer (v2.0)**: O-06(Delay Video/Audio/Device), O-07(Delay Key & Fill)
- **Drop 확정**: O-08(Secure Delay Time), O-09(Dynamic Delay), O-10(Auto Stream), O-11(Show Countdown), O-12(Countdown Video+BG)
- **Drop 확정**: PokerGFX 원본 Main Window #4 (Secure Delay+Preview 체크박스) → EBS M-04에 미반영
- **비활성**: feature-interactions의 M-08(Secure Delay) 섹션은 PokerGFX 원본 #4와 다른 EBS 신규 기능을 기술함 — 혼동 주의
- **v1.0 아키텍처**: I/O 탭은 Live 파이프라인(O-01~O-05)만 활성화됨

## 관련 요소

- O-06 (Delay Video/Audio/Device) — v2.0 Defer
- O-07 (Delay Key & Fill) — v2.0 Defer
- O-08 (Secure Delay Time) — Drop
- O-09 (Dynamic Delay) — Drop
- O-10 (Auto Stream) — Drop
- O-11 (Show Countdown) — Drop
- O-12 (Countdown Video + BG) — Drop
- PokerGFX 원본 Main Window #4 (Secure Delay + Preview 체크박스) — EBS Drop
