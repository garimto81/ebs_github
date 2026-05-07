---
title: "S3 Command Center Cascade Plan — Command_Center_PRD v4.0 → 정본/feature 전면 정합"
owner: stream:S3 (Command Center)
tier: internal
status: ACTIVE
last_updated: 2026-05-07
trigger: 사용자 인텐트 "S2/S3 기준 문서 토대로 인과 관련 문서 전면 정합"
worktree: C:/claude/ebs-cc-stream
branch: work/s3/2026-05-07-work-2026-05-07
---

# S3 CC Cascade — 정본 + Feature 전면 정합

## 기준 문서 (SSOT, 변경 금지)

`docs/1. Product/Command_Center_PRD.md` v4.0 — Reader Panel 16 fix cascade + 1×10 그리드 + 6 키 + 5-Act 시퀀스.

**핵심 변경 (v3.0 → v4.0)**:

```
+-----------------------------------------------+
|  StatusBar (52px)         |   상단 상태바     |
+-----------------------------------------------+
|  TopStrip  (158px)        |   테이블 정보     |
+-----------------------------------------------+
|  PlayerGrid (가변, 1×10)  |   ★ 핵심 변경    |
|  - 선수 10명 가로 한 줄                        |
|  - 타원형 테이블 폐기                          |
+-----------------------------------------------+
|  ActionPanel (124px)      |  6 키 동적 버튼   |
|  - N · F · C · B · A · M                       |
+-----------------------------------------------+
```

**6 키 의미**: N(Next/Fold) · F(Fold) · C(Call/Check) · B(Bet/Raise) · A(All-in) · M(Menu/Manual)

**5-Act 시퀀스** (12 시간 본방송 내 한 핸드 흐름):
1. Act 1: IDLE — 운영자 자리 직전
2. Act 2: PreFlop — 카드 분배 시작
3. Act 3: Flop/Turn/River — 진행
4. Act 4: Showdown — 승부
5. Act 5: Settlement — 정산

**Reader Panel 16 fix** (C 4 + H 4 + M 5 + L 3): 숫자 fact-check / 5 vs 6 키 모순 / R3 보안 보강 / G1 runtime 가드 / 약어 풀이 / AT 8 화면 / D7 정본 인용.

---

## Cascade 영향 매트릭스

### Tier A — Command_Center_UI (정본 + 13 feature)

| 우선순위 | 대상 | 변경 유형 |
|:--:|------|----------|
| **P0** | `Command_Center_UI/Overview.md` (정본, D7 §5.1) | 1×10 그리드 + 6 키 + 4 영역 위계 명시 |
| **P0** | `Command_Center_UI/UI.md` | layout/structure 정합 (PRD 색상은 무시, 톤은 B&W refined minimal) |
| **P1** | `Command_Center_UI/Action_Buttons.md` | 6 키 (N·F·C·B·A·M) 동적 매핑 명시 |
| **P1** | `Command_Center_UI/Hand_Lifecycle.md` | 5-Act 시퀀스 명시 (IDLE → PreFlop → Flop/Turn/River → Showdown → Settlement) |
| **P1** | `Command_Center_UI/Multi_Table_Operations.md` | 1×10 그리드 multi-table 적용 |
| **P1** | `Command_Center_UI/Seat_Management.md` | 1×10 가로 그리드 좌석 관리 |
| **P2** | `Command_Center_UI/Player_Edit_Modal.md` | 1×10 그리드에서 선수 편집 흐름 |
| **P2** | `Command_Center_UI/Game_Settings_Modal.md` | 4 영역 위계 컨텍스트 |
| **P2** | `Command_Center_UI/Keyboard_Shortcuts.md` | 6 키 단축키 표준 정합 |
| **P2** | `Command_Center_UI/Manual_Card_Input.md` | M 키 (Menu/Manual) 진입 |
| **P2** | `Command_Center_UI/Undo_Recovery.md` | 5-Act 내 undo 컨텍스트 |
| **P2** | `Command_Center_UI/Statistics.md` | derive framing |
| **P2** | `Command_Center_UI/Demo_Test_Mode.md` | derive framing |

### Tier B — RFID_Cards (Reader Panel 영향)

| 우선순위 | 대상 | 변경 유형 |
|:--:|------|----------|
| **P1** | `RFID_Cards/Overview.md` | Reader Panel 정체성 명시 |
| **P1** | `RFID_Cards/Register_Screen.md` | Reader Panel UI 정합 |
| **P2** | `RFID_Cards/Card_Detection.md` | Reader Panel 진입 흐름 |
| **P2** | `RFID_Cards/Deck_Registration.md` | Reader Panel 등록 흐름 |
| **P2** | `RFID_Cards/Manual_Fallback.md` | M 키 (Manual) 폴백 |

### Tier C — Overlay (5-Act 영향)

| 우선순위 | 대상 | 변경 유형 |
|:--:|------|----------|
| **P2** | `Overlay/Overview.md` | 5-Act 시퀀스 컨텍스트 |
| **P2** | `Overlay/Sequences.md` | 5-Act → Overlay 시퀀스 매핑 |
| **P3** | `Overlay/Animations.md` | 5-Act 전환 애니메이션 |
| **P3** | `Overlay/Audio.md` | derive framing |
| **P3** | `Overlay/Elements.md` | derive framing |
| **P3** | `Overlay/Skin_Loading.md` | derive framing |
| **P3** | `Overlay/Scene_Schema.md` | derive framing |
| **P3** | `Overlay/Layer_Boundary.md` | derive framing |
| **P3** | `Overlay/Security_Delay.md` | derive framing |
| **P3** | `Overlay/Engine_Dependency_Contract.md` | derive framing |

### Tier D — APIs / Settings / Landing

| 우선순위 | 대상 | 변경 유형 |
|:--:|------|----------|
| **P1** | `APIs/RFID_HAL.md` | Reader Panel HAL 인터페이스 정합 |
| **P2** | `APIs/RFID_HAL_Interface.md` | derive 정합 |
| **P3** | `Settings.md` | 4 영역 위계 컨텍스트 |
| **P3** | `2.4 Command Center.md` (landing) | v4.0 변경 요약 추가 |

### Tier E — Cross-Cutting (Notify)

| 우선순위 | 대상 | 변경 유형 |
|:--:|------|----------|
| **P4** | Foundation §Ch.5.4 (CC 위치) | NOTIFY-S1 (S1 위임) |

---

## 작업 순서 (Map-Reduce)

### Phase 1 — 정본 정합 (Tier A P0)

`Command_Center_UI/Overview.md` + `UI.md` 에 PRD v4.0 핵심 변경 반영.

**필수 추가**:
- 4 영역 위계 (StatusBar 52px → TopStrip 158px → PlayerGrid → ActionPanel 124px) ASCII 다이어그램
- 1×10 그리드 정의 (타원형 테이블 폐기 명시)
- 6 키 (N · F · C · B · A · M) 의미 카탈로그
- 5-Act 시퀀스 카탈로그 (IDLE → PreFlop → Flop/Turn/River → Showdown → Settlement)
- changelog: `2026-05-07 | v4 정체성 정합 | CC_PRD v4.0 cascade — 1×10 그리드 + 6 키 + 5-Act 반영`

### Phase 2 — Tier A P1/P2 (Command_Center_UI 13 feature)

각 feature 도입부에 v4.0 컨텍스트 1~2줄 추가. P1 5 문서는 직접 매핑 (구체 변경), P2 8 문서는 framing.

### Phase 3 — Tier B (RFID_Cards 5 문서)

Reader Panel 정체성을 RFID 5 문서에 cascade. PRD v4.0의 Reader Panel 16 fix 결과를 반영.

### Phase 4 — Tier C (Overlay 10 문서)

5-Act 시퀀스를 Overlay 흐름과 매핑. P2 2 문서 (Overview, Sequences) 는 직접 매핑, P3 8 문서는 framing.

### Phase 5 — Tier D (APIs + Settings + Landing)

RFID_HAL 인터페이스 + 4 영역 위계 컨텍스트 정합.

### Phase 6 — Cross-Cutting Notify

Foundation §Ch.5.4 영향 시 `Backlog/NOTIFY-S1-cc-identity-cascade.md` 신설.

### Phase 7 — Verify + PR

- `python tools/doc_discovery.py --impact-of "docs/1. Product/Command_Center_PRD.md"` 실행
- 정본/feature 모든 변경 commit
- `python tools/orchestrator/team_session_end.py --message="S3 CC cascade — CC_PRD v4.0 → Tier A/B/C/D 30+ feature 전면 정합"` 실행

---

## 검증 체크리스트 (PR 머지 전)

- [ ] Command_Center_PRD v4.0 변경 0 (기준 문서 보존)
- [ ] `Command_Center_UI/Overview.md` §UI 에 1×10 그리드 + 6 키 명시
- [ ] `Command_Center_UI/Action_Buttons.md` 에 6 키 동적 매핑 명시
- [ ] `Command_Center_UI/Hand_Lifecycle.md` 에 5-Act 시퀀스 명시
- [ ] RFID 5 문서에 Reader Panel 컨텍스트 명시
- [ ] Overlay 2 문서 (Overview, Sequences) 에 5-Act 매핑
- [ ] frontmatter `derivative-of` / `legacy-id` 변경 0 (구조 보존)
- [ ] `tools/doc_discovery.py` 0 error
- [ ] PR 단일 (모든 cascade가 한 PR에)

---

## 자율 권한 (Mode A — Conductor 위임)

S3 sub-agent 는 다음 영역에 자율 결정 권한:
- `docs/2. Development/2.4 Command Center/**` 모든 문서 편집
- Command_Center_PRD 변경은 금지 (기준 문서)
- Foundation / Architecture / 다른 팀 영역 편집 금지 (NOTIFY 만)

**판단 모호 시**: SSOT 우선. PRD v4.0 narrative 톤 따라 caption 추가. 사용자 질문 금지.

**중요 — 색상 vs 구조**: PRD v4.0 스크린샷은 다크 broadcast 톤이지만, EBS 최종은 Lobby B&W refined minimal. cascade 시 *layout / structure / interaction* 만 참조하고 색상은 무시.
