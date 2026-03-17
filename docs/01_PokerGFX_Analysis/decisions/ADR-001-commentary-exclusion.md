# ADR-001: Commentary 탭 배제

## 상태
확정

## 맥락

PokerGFX의 Commentary 탭은 해설자 오버레이를 실시간으로 방송 출력에 합성하는 기능이다. 해설자 이름, PIP(Picture-in-Picture) 창, 해설자 표시 모드 전환 등 8개 요소로 구성되어 있으며, 해설자가 원격으로 방송 화면에 자신의 정보를 표시할 수 있게 한다.

EBS console v1.0은 PokerGFX 289개 원본 요소를 180개로 감축하는 변환 과정에서 Commentary 탭 전체를 검토 대상으로 올렸다. 기존 포커 방송 프로덕션 운영 이력을 검토한 결과, Commentary 기능의 실제 사용 여부와 EBS 운영 방식과의 정합성을 판단하는 것이 필요했다.

PokerGFX Commentary 탭 원본 구성(8개): Commentary ON/OFF 토글(SV-021), Commentator Name 1, Commentator Name 2, Commentary Display Mode, Show Commentator Names, Commentary PIP(SV-022), PIP Size, PIP Position.

## 결정

Commentary 탭 8개 요소 전체를 EBS v1.0에서 완전 배제한다. 이 기능은 EBS 설계 범위에서 제외되며, v2.0 이후 재검토 대상으로도 등록하지 않는다.

## 근거

| 근거 | 내용 |
|------|------|
| 운영팀 미사용 확정 | 기존 포커 방송 프로덕션에서 Commentary 기능을 실제로 사용한 이력이 없음. 해설자 정보는 별도 그래픽 소스(OBS Scene 또는 외부 타이틀 그래픽)로 처리하는 것이 현장 표준 |
| 운영 방식 불일치 | Commentary 탭은 해설자가 원격으로 방송 화면에 개입하는 방식을 전제한다. EBS의 현장 운영 방식(운영자 1인이 콘솔에서 직접 제어)과 구조적으로 맞지 않음 |
| 개발 리소스 집중 | v1.0 핵심 목표는 RFID 실시간 카드 추적, Action Tracker 연동, GFX 오버레이 방송이다. Commentary 복제는 이 목표에 기여하지 않으며, 개발 비용 대비 운영 효과가 없음 |

## 영향

- **제거**: SV-021(Commentary ON/OFF), SV-022(Commentary PIP) 포함 8개 요소 전체 제거
- **감축 기여**: 289→180 감축 중 -8 기여 (2.9% 감축)
- **의존성**: Commentary 탭은 다른 탭 요소와 상호작용이 없으므로 연쇄 영향 없음
- **오버레이**: `02_Annotated_ngd/07-commentary-tab.png`에 빨간 X 8개로 시각 표시됨

## 관련 요소

- SV-021 (Commentary ON/OFF 토글)
- SV-022 (Commentary PIP)
- Commentator Name 1, Commentator Name 2
- Commentary Display Mode
- Show Commentator Names
- PIP Size
- PIP Position
