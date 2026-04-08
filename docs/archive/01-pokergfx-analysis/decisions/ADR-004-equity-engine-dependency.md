# ADR-004: Equity 엔진 의존성

## 상태
보류

## 맥락

포커 방송에서 Equity(승률) 표시는 핵심 시청자 경험 요소다. 각 플레이어의 현재 핸드 승률을 실시간으로 계산하고 GFX 오버레이에 표시하는 것은 고스테이크 방송의 표준이다. PokerGFX는 이를 Show Hand Equities(G-37), Show Outs(G-40~G-42), Ignore Split Pots(G-57) 등의 UI 요소로 제공한다.

이 기능들은 단순한 UI 요소가 아니라 백엔드 Equity 계산 엔진에 의존한다. Equity 계산은 현재 보드 카드와 플레이어 홀카드 조합에서 가능한 모든 런아웃을 Monte Carlo 시뮬레이션 또는 Enumeration 방식으로 계산하는 연산 집약적 작업이다. True Outs(G-42)는 정밀 아웃츠 계산 알고리즘을, Ignore Split Pots(G-57)는 팟 분할 시나리오 처리를 추가로 요구한다.

EBS v1.0 설계 시점에서 Equity 엔진 구현 전략이 미결정 상태다. 자체 개발과 오픈소스 라이브러리 활용 중 어느 경로를 택하든 상당한 검증이 필요하며, 이 결정이 내려지기 전까지 연관 UI 요소들의 v1.0 포함 여부를 확정할 수 없다.

## 결정

Equity 엔진 의존 UI 요소 약 15개 전체를 v2.0 Defer로 임시 결정한다. 단, 이 결정은 Equity 엔진 구현 전략이 확정되는 시점에 재검토된다. 엔진이 v1.0 일정 내에 구현 가능하다고 판단되면 해당 요소들을 v1.0으로 복귀시킬 수 있다.

현재 미결 사항: Equity 엔진 구현 방식(자체 개발 vs 오픈소스 활용)과 v1.0 포함 여부.

## 근거

| 근거 | 내용 |
|------|------|
| 엔진-UI 의존성 | Equity 계산 없이 G-37, G-40~G-42, G-57 UI를 활성화해도 실제 수치를 표시할 수 없음. 빈 UI보다 Defer가 운영상 명확 |
| 검증 비용 | Equity 계산의 정확도는 방송 품질에 직결된다. 잘못된 승률 표시는 방송 신뢰도를 훼손함. 충분한 검증 없이 배포 불가 |
| 전략 미결정 | 자체 개발 시 알고리즘 설계+테스트, 오픈소스 활용 시 라이선스 검토+통합 작업이 필요. 결정 전 구현 착수 불가 |
| 방송 운용 가능 | Equity 없이도 RFID 카드 추적과 기본 GFX(스택, 블라인드, 팟 크기) 방송이 가능함. v1.0 출시 차단 요인이 아님 |

## 영향

- **v2.0 Defer (잠정)**: G-37(Show Hand Equities), G-40(Show Outs), G-41(Outs Position), G-42(True Outs), G-57(Ignore Split Pots) — 핵심 5개
- **v2.0 Defer (연관)**: G-26~G-31(Leaderboard 옵션 6개 — Equity 데이터 시스템 전제), G-39(Hilite Nit Game), G-43~G-44b(Score Strip 3개) — 연관 약 10개
- **재검토 트리거**: Equity 엔진 구현 전략 확정 시 이 ADR을 업데이트하고 영향 요소 상태를 재결정
- **의존 역방향 없음**: Equity 엔진이 없어도 RFID, AT, 기본 GFX는 정상 동작

## 해결 경로

| 항목 | 내용 |
|------|------|
| 결정 기한 | Phase 1 개발 착수 시점 (v1.0 구현 시작 전) |
| 담당자 | 기술팀 리드 |
| 트리거 조건 | v1.0 개발 일정 확정 시 Equity 엔진 포함/배제 최종 결정 |
| 결정 기준 | (1) 오픈소스 핸드 평가기(PokerSolver 등) 성능/정확도 검증 결과 (2) v1.0 일정 내 통합 가능 여부 |
| 미결정 시 기본값 | v2.0 Defer 유지 (현재 임시 결정 확정) |

## 관련 요소

- G-37 (Show Hand Equities) — Equity 엔진 직접 의존
- G-40 (Show Outs) — Equity 엔진 직접 의존
- G-41 (Outs Position) — G-40 의존
- G-42 (True Outs) — 정밀 아웃츠 계산 알고리즘 의존
- G-57 (Ignore Split Pots) — Equity/Outs Split pot 처리 의존
- G-26~G-31 (Leaderboard 옵션 6개) — 리더보드 데이터 시스템 전제
- G-39 (Hilite Nit Game) — 닛 게임 강조, 고급 운영 기능
- G-43~G-44b (Score Strip 3개) — Strip 기능
