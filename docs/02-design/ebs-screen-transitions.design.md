---
doc_type: "design"
doc_id: "DESIGN-SCR-v3"
version: "1.0.0"
status: "draft"
owner: "BRACELET STUDIO"
created: "2026-03-11"
last_updated: "2026-03-11"
prd_ref: "EBS-UI-Design-v3 v9.0.0 §5"
---

# 화면 전환과 상태 흐름

기존 수동 전환에서 **게임 상태 연동 자동 전환**으로 진화한다.

## 5.1 게임 상태별 오버레이 변화

| 상태 | 표시 오버레이 | 정보 밀도 | 자동 동작 |
|------|-------------|:---------:|----------|
| IDLE | Blinds, Strip | 최소 | 이전 핸드 정리, 스택 갱신 |
| SETUP_HAND | Blinds, Strip, 액티브 Player만 (이름+스택) | 낮음 | 좌석 배치, 포지션 뱃지 표시 |
| PRE_FLOP | 액티브 Player만 (카드 슬롯 활성), Blinds | 기본 | 홀카드 슬롯 활성화, 액션 대기 |
| FLOP | 액티브 Player만, Board (3장), Blinds, Field | 중간 | 보드 3장 순차 등장 애니메이션 |
| TURN | 액티브 Player만, Board (4장), Blinds, Field | 높음 | Turn 카드 등장, 팟 갱신 |
| RIVER | 액티브 Player만, Board (5장), Blinds, Field | 높음 | River 카드 등장, 최종 팟 |
| SHOWDOWN | 액티브 Player만 (카드 공개), Board, Blinds | 최대 | 카드 공개 + 위너 하이라이트 + 핸드명 |
| HAND_COMPLETE | 결과 요약 → IDLE 전환 | 감소 | 3초 결과 표시 후 자동 정리 |

**액티브 플레이어 배치 자동 재정렬**: 폴드로 인해 액티브 플레이어 수가 변동하면, 남은 Player Graphic이 현재 배치 옵션(하단 집중형/좌우 분산형/L자형)에 맞춰 자동 재배치된다. 간격은 균등 분배하며, 트랜지션은 400ms ease-out으로 적용한다.

## 5.2 이벤트 기반 강조 (BM-2 GGPoker 패턴)

특정 이벤트 발생 시 일반 렌더링 위에 **특수 연출**을 오버레이한다.

| 이벤트 | 연출 | 지속 시간 |
|--------|------|:---------:|
| **All-in** | 네온 글로우 테두리 + 에퀴티 바 슬라이드인 + 스택 Bold 강조 | 지속 (해소 시까지) |
| **Big Pot** (>50BB) | 팟 숫자 스케일업 + 글로우 펄스 | 2초 |
| **Bad Beat** | 위너 카드 빨간 하이라이트 + 카메라 전환 신호 | 3초 |
| **Showdown Winner** | 위닝 핸드 카드 블링크 + 핸드명 팝업 | 3초 |
| **Fold** | 폴드 플레이어 Graphic 즉시 페이드아웃 제거 (300ms) + 남은 Player 자동 재배치 | 0.3초 |
| **Fold (단독 승리)** | 마지막 생존자 스택에 팟 합산 애니메이션 | 1.5초 |
| **Side Pot 생성** | 사이드팟 텍스트 슬라이드인 | 1초 |

## 5.3 Live vs Delayed 모드 — 2차 개발 범위

> v1.0은 **Live 모드 전용**으로 운영한다. 홀카드, 에퀴티, 팟 금액 등 모든 정보를 실시간으로 오버레이에 반영한다.
>
> **딜레이 버퍼**는 외부 송출 장비(AJA Ki Pro, Blackmagic HyperDeck 등)에서 처리한다. EBS 자체 딜레이 버퍼는 구현하지 않는다.
>
> **정보 공개 딜레이**(홀카드/에퀴티를 시청자에게 지연 공개)는 2차 개발에서 EBS 내부 로직으로 구현한다. 이를 위해 데이터 모델에 `delay_buffer_ms`, `reveal_policy` 필드를 예약한다.

---

## Changelog

| 날짜 | 버전 | 변경 내용 | 결정 근거 |
|------|------|-----------|----------|
| 2026-03-11 | v1.0.0 | EBS-UI-Design-v3.prd.md §5에서 분리 | 설계 내용 방대, 개발 시 별도 진행하기에 분리 |

---

**Version**: 1.0.0 | **Updated**: 2026-03-11
