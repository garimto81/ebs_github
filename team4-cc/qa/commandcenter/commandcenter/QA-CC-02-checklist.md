# QA-CC-02: Command Center QA 체크리스트 (BS-05 기반)

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | BS-05 행동 명세 기반 QA 체크리스트 + 구현 대조 |

---

## 개요

BS-05 행동 명세(7파일)에서 추출한 요구사항을 구현 코드와 대조한 결과.

> 레포: `/ebs_app/` | 프레임워크: Flutter Desktop | 행동 명세: BS-05-00~06

---

## 구현 대조 요약

| 영역 | 전체 | ✅ | ⚠️ | ❌ |
|------|:----:|:--:|:--:|:--:|
| BS-05-00 Overview | 4 | 0 | 0 | 4 |
| BS-05-01 Hand Lifecycle | 8 | 0 | 3 | 5 |
| BS-05-02 Action Buttons | 8 | 0 | 8 | 0 |
| BS-05-03 Seat Management | 5 | 0 | 1 | 4 |
| BS-05-04 Manual Card Input | 4 | 0 | 2 | 2 |
| BS-05-05 Undo | 3 | 0 | 0 | 3 |
| BS-05-06 Keyboard | 4 | 0 | 0 | 4 |
| **합계** | **36** | **0** | **14** | **22** |

---

## BS-05-00 Overview

| # | 요구사항 | 구현 | 근거 | Playwright |
|---|----------|:----:|------|:----------:|
| CC-00-12 | Top bar 항목 (connection, RFID, game type, hand#, FSM state, blind level) | ⚠️ | AppBar에 table/hand#/street만 있음. connection/RFID/blind level 없음 | — |
| CC-00-16 | 전체 액션 키보드 입력 가능 | ❌ | KeyboardListener 없음 | — |
| CC-00-17 | action_on 좌석 펄스 애니메이션 | ❌ | 애니메이션 프레임워크 없음 | — |
| CC-00-19 | UNDO 최대 5단계 | ❌ | undo 로직 없음, placeholder 버튼만 | — |

---

## BS-05-01 Hand Lifecycle

| # | 요구사항 | 구현 | 근거 | Playwright |
|---|----------|:----:|------|:----------:|
| CC-01-01~04 | IDLE 상태 표시 (이름/스택만, 버튼 비활성) | ❌ | IDLE 상태 없음. loading/deckReg/live 3상태만 | — |
| CC-01-05~10 | SETUP_HAND (블라인드 수집, DEAL 버튼) | ❌ | SETUP_HAND 상태 없음. DEAL 버튼 stub | — |
| CC-01-16~19 | PRE_FLOP (홀카드, action_on 펄스, 팟) | ⚠️ | Street enum 존재하나 홀카드 표시/팟 추적 없음 | — |
| CC-01-20~22 | FLOP 커뮤니티 3장 표시 | ⚠️ | 커뮤니티 카드 표시되나 UI 제한적 | — |
| CC-01-26~28 | SHOWDOWN (홀카드 리빌, 위너, 핸드랭크) | ❌ | 위너/핸드랭크 없음 | — |
| CC-01-29~31 | CHOP/RUN IT 버튼 | ❌ | 미구현 | — |
| CC-01-34~35 | Bomb Pot 모드 | ❌ | 미구현 | — |
| CC-01-40~43 | HAND_COMPLETE 자동 전환 | ⚠️ | showdown→preflop 전환 있으나 명시적 HAND_COMPLETE 상태 없음 | — |

---

## BS-05-02 Action Buttons

| # | 요구사항 | 구현 | 근거 | Playwright |
|---|----------|:----:|------|:----------:|
| CC-02-01~08 | NEW HAND 버튼 + 사전조건 | ⚠️ | "Advance street" 버튼만 존재. NEW HAND 없음 | — |
| CC-02-11~16 | DEAL 버튼 | ⚠️ | placeholder: onPressed: () {} | — |
| CC-02-17~26 | FOLD 버튼 + 특수 케이스 | ⚠️ | placeholder | — |
| CC-02-27~36 | CHECK 버튼 + BB 옵션 | ⚠️ | placeholder | — |
| CC-02-37~58 | BET 버튼 + 금액 입력 + 퀵 프리셋 | ⚠️ | placeholder, 금액 입력 UI 없음 | — |
| CC-02-59~71 | CALL 버튼 + short call | ⚠️ | placeholder | — |
| CC-02-72~94 | RAISE 버튼 + 금액 범위 | ⚠️ | placeholder | — |
| CC-02-95~107 | ALL-IN 버튼 + 특수 케이스 | ⚠️ | placeholder | — |

---

## BS-05-03 Seat Management

| # | 요구사항 | 구현 | 근거 | Playwright |
|---|----------|:----:|------|:----------:|
| CC-03-01~08 | 10좌석 Oval 레이아웃 | ⚠️ | ListTile 세로 목록만. Oval 레이아웃 없음 | — |
| CC-03-09~15 | 좌석 시각 상태 (active/folded/allIn/sittingOut) | ❌ | 상태별 시각 구분 없음 | — |
| CC-03-16~22 | 플레이어 배정 다이얼로그 | ❌ | 미구현 | — |
| CC-03-24~31 | 드래그&드롭 좌석 관리 | ❌ | 미구현 | — |
| CC-03-35~43 | Sit Out/Sit In | ❌ | 미구현 | — |

---

## BS-05-04 Manual Card Input

| # | 요구사항 | 구현 | 근거 | Playwright |
|---|----------|:----:|------|:----------:|
| CC-04-01~09 | 4x13 카드 그리드 | ⚠️ | 덱 등록용 그리드 있으나 게임 입력용은 아님 | — |
| CC-04-14~21 | 홀카드 입력 플로우 | ❌ | 미구현 | — |
| CC-04-26~36 | 보드 카드 입력 | ⚠️ | RFID inject만. 수동 선택 UI 없음 | — |
| CC-04-49~61 | RFID fallback | ❌ | 수동 inject 패널 있으나 타임아웃 기반 fallback 아님 | — |

---

## BS-05-05 Undo & Recovery

| # | 요구사항 | 구현 | 근거 | Playwright |
|---|----------|:----:|------|:----------:|
| CC-05-01~06 | Undo 메커니즘 (Event Sourcing) | ❌ | 히스토리 스택 없음, placeholder 버튼만 | — |
| CC-05-07~23 | Undoable 이벤트 (FOLD/CHECK/BET/CALL/RAISE/ALLIN undo) | ❌ | 미구현 | — |
| CC-05-49~55 | MISS DEAL | ❌ | 미구현 | — |

---

## BS-05-06 Keyboard Shortcuts

| # | 요구사항 | 구현 | 근거 | Playwright |
|---|----------|:----:|------|:----------:|
| CC-06-01~07 | 액션 단축키 (N/D/F/C/B/R/A) | ❌ | KeyboardListener 없음 | — |
| CC-06-11~20 | 카드 입력 키 (suit+rank) | ❌ | 드롭다운만 | — |
| CC-06-24~33 | 내비게이션 키 (Tab/Esc/Enter) | ❌ | 미구현 | — |
| CC-06-34~37 | 시스템 단축키 (Ctrl+Z/F11) | ❌ | 미구현 | — |

---

## Gap Analysis 요약

| 심각도 | 항목 | 설명 |
|:------:|------|------|
| CRITICAL | 액션 버튼 8개 | 전부 placeholder (onPressed: () {}). 게임 진행 불가 |
| CRITICAL | HandFSM | IDLE/SETUP_HAND/HAND_COMPLETE 상태 없음. Street 5개만 |
| CRITICAL | 키보드 단축키 | 0% 구현. KeyboardListener 부재 |
| HIGH | Undo/Recovery | 메커니즘 전무. Event Sourcing 미연결 |
| HIGH | 좌석 시각화 | Oval 레이아웃 없음. 세로 리스트만 |
| HIGH | 수동 카드 입력 | 4x13 그리드 게임용 없음 |
| MEDIUM | Top bar 정보 | connection/RFID/blind level 표시 없음 |
| MEDIUM | Sit Out/In | 미구현 |

---

## 현재 상태 판정

CC는 **Phase 1 POC** 수준. RFID 카드 읽기 + 기본 street 전환만 구현.
BS-05 명세 기준 **구현율 약 10~15%**.

---

## 참조

- 행동 명세: contracts/specs/BS-05-command-center/ (7파일)
- 감사 결과: docs/qa/commandcenter/QA-CC-00-audit.md
