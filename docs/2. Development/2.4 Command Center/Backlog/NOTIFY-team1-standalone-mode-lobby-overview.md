---
id: NOTIFY-team1-standalone
title: Lobby Overview — CC Launch Modes 2-분류 반영 요청
target_team: team1
status: OPEN
source: docs/2. Development/2.4 Command Center/Backlog.md
---

# NOTIFY — team1: Lobby Overview 에 CC Launch Modes 2-분류 반영 요청

- **요청일**: 2026-04-21
- **요청 세션**: team4 (`/team` Standalone Mode 기획 정리)
- **관련**: `Command_Center_UI/Standalone_Mode.md`, `Command_Center_UI/Overview.md §2.0`

## 배경

team4 가 CC Launch Modes 를 2-분류로 확정:
- **Linked** (Lobby 경유) — 기존 default
- **Standalone** (Lobby 우회, 개발·QA 전용) — 신규 공식화

**Demo Scenario 는 scope 제외** (사용자 2026-04-21 결정).

기획 SSOT: `docs/2. Development/2.4 Command Center/Command_Center_UI/Standalone_Mode.md`

## 요청 작업 (team1 decision_owner)

`docs/2. Development/2.1 Frontend/Lobby/Overview.md §Lobby-Command Center 관계` 에 다음을 additive 보강:

1. **2-Mode 존재 명시** — Lobby 가 CC 의 유일한 진입 경로가 아님을 표기:

   ```
   > **CC Launch Modes**: CC 는 두 경로로 기동된다.
   > - Linked (Lobby [Launch]) — 본 섹션의 SSOT, 실방송 운영
   > - Standalone (CLI `--standalone`) — 개발·QA 전용, 본 문서 범위 외
   >
   > Standalone 상세: `docs/2. Development/2.4 Command Center/Command_Center_UI/Standalone_Mode.md`
   ```

2. **[Launch] 버튼 동작 명세 정합성** — Lobby 가 전달하는 CLI args 가 Standalone 의 fallback 규칙과 충돌하지 않음을 확인:
   - Lobby 는 반드시 `--table_id --token --cc_instance_id --ws_url` **4 종 전부** 전달
   - 4 종 중 1 개라도 누락되면 CC 가 Standalone 으로 fallback → 실방송 사고 방지 위해 Lobby 쪽 validation 필요

3. **monitoring 영향** — Lobby 가 활성 CC 모니터링 시 Standalone 인스턴스는 집계 대상 제외:
   - Standalone CC 는 `operator_connected` WS 이벤트 발행하지 않음 (Lobby 관제 대상 아님)
   - 현 모니터링 로직이 "connected CC == Linked CC" 가정에 의존하는지 확인 필요

## 완료 기준

- Lobby Overview.md 에 §Launch Modes 링크 섹션 추가
- Lobby [Launch] 구현 시 4 args 누락 시 에러 표시 (Standalone fallback 을 실수로 트리거하지 않음)
- 활성 CC 모니터링 로직이 Standalone 세션을 집계 제외하는지 확인

## 비고

- team4 는 이 문서에 직접 손대지 않음 (team1 ownership)
- 원칙 1 (WSOP LIVE 정렬): WSOP LIVE 는 Standalone 개념 없음 — EBS 고유 divergence. Lobby Overview 에 이 justification 포함 권장.
