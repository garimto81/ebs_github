---
id: B-LOBBY-ALERTS-001
title: "Alerts 화면 — 디자인 풀 스펙 → SSOT 보강 + Flutter 구현"
status: PENDING
priority: P3
source: docs/4. Operations/Lobby_Modification_Plan_2026-05-04.md §F2
related:
  - docs/2. Development/2.1 Frontend/Lobby/References/EBS_Lobby_Design/screens-extra.jsx (lines 171-270)
  - docs/2. Development/2.1 Frontend/Lobby/References/EBS_Lobby_Design/screenshots/alerts-check.png
note: "사용자 의사결정 2026-05-04 §F2 — P3 후순위 결정. production launch 전 재평가 필요 (모니터링 visibility)."
---

# B-LOBBY-ALERTS-001 — Lobby Alerts 화면

## 배경

design SSOT (`screens-extra.jsx:171-270` + `alerts-check.png`) 가 Alerts 화면 풀 스펙을 정의:
- 5 KPI (Open / Errors / Warnings / Info / MTTR)
- 4 severity × 7 source seg-control 필터
- 알림 행: severity 색 막대 + 시간 + source + 제목 + 본문 + CTA
- Mute 15m / Mark all read 액션
- severity: err / warn / info, source: RFID / Seat / CC / Level / Stream / System

그러나 SSOT (`docs/2.1 Frontend/Lobby/`) 어떤 .md 도 Alerts 화면 정의 없음. Flutter 구현도 0건. = **Type B (기획 공백)**.

사용자 의사결정 (2026-05-04 §F2): **P3 후순위**. 본 Backlog 는 _identified_ 단계로 등재. production launch 전 재평가 권고.

## 수락 기준 (P3 진입 시)

### Phase 1 — SSOT 보강
- [ ] `docs/2. Development/2.1 Frontend/Lobby/Alerts.md` 신규 작성 (Type B 보강)
  - 화면 spec (KPI / 필터 / 행 레이아웃 / 액션)
  - severity × source 분류 정의
  - Backend WS 토픽 계약 (team2 협의)
  - RBAC (Admin/Operator/Viewer 별 가시성)
  - Mute/Mark-as-read 영속 (테이블 단위? 사용자 단위?)
- [ ] Lobby/Overview.md §데이터 공유 표에 "alerts" 행 추가
- [ ] `team1-frontend/Backlog/B-LOBBY-ALERTS-001.md` (이 파일) 의 Phase 2 unblocking

### Phase 2 — 구현
- [ ] `team1-frontend/lib/features/alerts/` 신규
  - `screens/alerts_screen.dart`
  - `providers/alerts_provider.dart` (WS subscribe)
  - `widgets/{alert_kpi_strip, alert_filter_bar, alert_row}.dart`
- [ ] router 추가 (`/lobby/alerts`)
- [ ] sidebar Tools 섹션에 항목 추가
- [ ] 위젯/통합 테스트

## 우선순위 / 추정

- P3 (사용자 결정. production launch 전 재평가)
- 추정 (참고용): SSOT 2h + 구현 1~2일 + team2 WS 협의 2~3일
- production launch 시 모니터링 visibility 미흡 위험 — re-prioritize 권고 시점: B-201 production launch 직전

## Trigger 재평가

본 항목을 P3 → P1 으로 승격할 트리거 (관리감독 시야):
- BO/Engine/CC 운영 중 RFID 오류 빈도 > 1회/시간
- 사용자가 production 테스트 중 "alert visibility 부족" 명시
- B-201 launch checklist 에서 monitoring 항목으로 등재
