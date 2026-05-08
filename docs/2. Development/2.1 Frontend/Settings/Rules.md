---
title: Rules
owner: team1
tier: internal
legacy-id: BS-03-04
last-updated: 2026-04-21
reimplementability: PASS
reimplementability_checked: 2026-04-21
reimplementability_notes: "2026-04-21 교차검증 완료: rules_screen.dart 에 game_variant/blind_structure_id/ante_schedule_id/time_bank_seconds/straddle_* 필드 구현 확인 (grep). WSOP Rule 95 (under-raise) / Rule 96 (incomplete all-in) — Betting_and_Pots.md §3+§4 (IT-15 IncompleteAllInNoReopen / IT-16 UnderRaiseAdjust) 참조 (구 BS-06-02 R95/R96). SG-003 §Tab 4 스키마 충족."
sg_reference: SG-003
scope: event
confluence-page-id: 3818947177
confluence-parent-id: 3811606750
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818947177/EBS+Rules
---

# BS-03-04 Rules — 게임 규칙 설정

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | Console PRD v9.7 §2.9 기반 — Game Rules/Player Display 2서브그룹, 11 컨트롤 |
| 2026-04-10 | CCR-017 | §5 Blind 구조 — `BlindDetailType` 5-타입 enum 추가 (WSOP LIVE parity) |

---

## 개요

Rules 섹션은 Settings의 네 번째 탭으로, **게임 규칙이 오버레이 표시에 영향을 미치는 설정**을 관리한다. 2-Column 구조: Game Rules(Bomb Pot/Straddle/Raise 제한) → Player Display(좌석 번호/탈락 표시/액션 초기화/정렬/승자 강조). 방송 시작 전 세팅하고 핸드 진행 중에는 변경하지 않는 것이 원칙이다.

> 참조: Console PRD v9.7 §2.9 Rules 탭

---

## 1. 컨트롤 목록

### 1.1 Game Rules 서브그룹 (ID 1~5)

| ID | 이름 | 타입 (shadcn/ui) | 기본값 | 설명 | 오버레이 영향 |
|:--:|------|-----------------|--------|------|-------------|
| 1 | Game Rules (col) | — | — | 서브그룹 헤더 | — |
| 2 | Move Button Bomb Pot | Switch | ON | Bomb Pot 후 딜러 버튼 이동 여부 | 버튼 위치 → 블라인드/액션 순서 |
| 3 | Limit Raises | Switch | OFF | 유효 스택 기반 레이즈 제한 | AT RAISE 버튼 비활성화 |
| 4 | Straddle Sleeper | Select | UTG Only | 스트래들 위치 규칙 | 블라인드 구조 변경 |
| 5 | Sleeper Final Action | Select | BB Rule | 슬리퍼 스트래들 최종 액션 여부 | Pre-Flop 액션 순서 |

**동작**:

- **Move Button Bomb Pot**: ON 시 Bomb Pot 후 딜러 버튼 다음 좌석 이동. OFF 시 Bomb Pot 전 위치 유지. 버튼 위치는 블라인드 포지션과 액션 순서를 결정하므로 게임 공정성에 직결.
- **Limit Raises**: 활성 시 잔여 스택이 현재 베팅의 특정 배수 이하이면 RAISE 불가 (CALL 또는 ALL-IN만 허용). 주로 Fixed Limit 게임용. AT에서 RAISE 버튼 회색 비활성화로 전환.
- **Straddle Sleeper**: UTG Only(UTG 좌석만 스트래들) / Any Position(모든 좌석) / With Sleeper(슬리퍼 추가 블라인드 허용). "With Sleeper" 선택 시 Sleeper Final Action(5) 활성화.
- **Sleeper Final Action**: BB Rule(Big Blind처럼 체크 가능) / Normal(일반 플레이어처럼 콜 필요). Straddle Sleeper가 "With Sleeper"일 때만 활성.

### 1.2 Player Display 서브그룹 (ID 6~11)

| ID | 이름 | 타입 (shadcn/ui) | 기본값 | 설명 | 오버레이 영향 |
|:--:|------|-----------------|--------|------|-------------|
| 6 | Player Display (col) | — | — | 서브그룹 헤더 | — |
| 7 | Add Seat # | Switch | OFF | 플레이어 이름에 좌석 번호 추가 | Player Graphic 이름 형식 |
| 8 | Show as Eliminated | Switch | ON | 스택 소진 시 탈락 표시 | 빨간 테두리 + "ELIMINATED" |
| 9 | Clear Previous Action | Select | On Street Change | 이전 액션 초기화 시점 | 액션 텍스트 리셋 타이밍 |
| 10 | Order Players | Select | Seat Order | 플레이어 정렬 순서 | 화면 표시 순서 |
| 11 | Hilite Winning Hand | Select | Immediately | 위닝 핸드 강조 시점 | 금색 하이라이트 + Glint |

**동작**:

- **Clear Previous Action**: "On Street Change"(기본값) — 스트리트 전이 시 모든 액션 텍스트 리셋. "On Action" — 해당 플레이어 다음 액션 시 리셋. "Never" — 수동 초기화만.
- **Order Players**: Seat Order(좌석 순서) / Stack Size(칩량 내림차순) / Alphabetical(이름 알파벳순). GFX 탭 Player Layout(2) 배치 형태 내에서 순서만 변경.
- **Hilite Winning Hand**: "Immediately" — 쇼다운 즉시 금색 하이라이트(border + pip highlighted + Glint 애니메이션). "After Delay" — 설정 지연 후 하이라이트 시작 (방송 긴장감 유지). "Never" — 강조 없음.
- **Show as Eliminated**: 활성 시 스택 0 플레이어에 빨간 테두리 + "ELIMINATED" 텍스트 자동 표시.

---

## 2. 트리거

| 트리거 | 발동 주체 | 설명 |
|--------|:--------:|------|
| Settings 변경 | Admin 수동 | 방송 시작 전 세팅 |
| `ConfigChanged` | 시스템 자동 | BO DB 갱신 후 WebSocket 이벤트 발행 |
| 스트리트 전이 | 게임 엔진 자동 | Clear Previous Action 트리거 |
| 쇼다운 | 게임 엔진 자동 | Hilite Winning Hand 트리거 |
| 스택 소진 | 게임 엔진 자동 | Show as Eliminated 트리거 |

---

## 3. 경우의 수 매트릭스

| 조건 | Game Rules 변경 | Player Display 변경 |
|------|:--------------:|:------------------:|
| CC IDLE | 즉시 적용 | 즉시 적용 |
| CC 핸드 진행 중 | 다음 핸드 (CONFIRM) | 즉시 적용 (FREE) |
| BO 서버 미실행 | 변경 불가 | 변경 불가 |
| Straddle ≠ With Sleeper | Sleeper Final Action 비활성 | — |
| Fixed Limit 게임 | Limit Raises 기본 ON 권장 | — |

---

## 4. 유저 스토리

| # | As a | When | Then | Edge Case |
|:-:|------|------|------|-----------|
| R-1 | Admin | Move Button Bomb Pot OFF | Bomb Pot 후 버튼 위치 유지 | ON: 다음 좌석 이동 |
| R-2 | Admin | Limit Raises ON (Fixed Limit) | 잔여 스택 부족 시 AT RAISE 비활성 | No Limit: 비활성 권장 |
| R-3 | Admin | Straddle를 "With Sleeper"로 변경 | Sleeper Final Action 활성화 | UTG Only: Sleeper 비활성 |
| R-4 | Admin | Add Seat # ON | 플레이어 이름에 좌석 번호 추가 (예: "[3] John") | — |
| R-5 | Admin | Order Players를 Stack Size로 변경 | 칩량 내림차순 정렬 | 동점: 좌석 번호순 |
| R-6 | Admin | Hilite Winning Hand를 After Delay로 변경 | 지연 후 금색 하이라이트 | — |
| R-7 | Admin | Clear Previous Action을 Never로 변경 | 액션 텍스트 수동 초기화만 | 화면 지저분해질 수 있음 |

---

## 비활성 조건

| 조건 | 영향 |
|------|------|
| Admin이 아닌 역할 | Rules 탭 접근 불가 |
| CC LIVE + 핸드 진행 중 | Game Rules: CONFIRM 분류 |
| BO 서버 미실행 | 읽기 전용 |

---

## 5. Blind 구조 — `BlindDetailType` enum (CCR-017)

WSOP LIVE 블라인드 구조(Blind Structure)는 레벨별 타입을 가지는 `BlindDetail` 배열로 표현된다. 본 섹션은 Settings의 블라인드 구조 관리에 사용되는 **타입 enum**을 정의한다.

```
BlindDetailType {
  Blind       // 일반 블라인드 레벨 (SB/BB/Ante + duration)
  Break       // 일반 휴식
  DinnerBreak // 저녁 식사 휴식 (보통 60~75분)
  HalfBlind   // 기존 레벨의 절반 길이 (Late Reg 경계 조정)
  HalfBreak   // 기존 break의 절반 길이
}
```

### 5.1 Late Registration 남은 시간 계산

Late Reg는 Event 설정에서 지정한 `late_reg_end_level_idx` 까지의 블라인드 구조 duration 합으로 계산한다:

```
late_reg_remaining =
    sum(level.duration
        for level in blindStructure
        if current_idx <= level.idx <= late_reg_end_idx)
    - elapsed_in_current_level
```

**규칙**:
- `Blind`, `Break`, `DinnerBreak`는 duration을 **그대로 합산**.
- `HalfBlind`, `HalfBreak`는 직전 `Blind`/`Break`의 **절반 길이**로 계산.
- Flight의 `is_pause == true` (DATA-04 Flight 참조)일 때는 `elapsed_in_current_level` 증가가 **중단**된다.

### 5.2 Oveerlay 영향

- Blind Structure 표시(`G1 Blind Level` 오버레이)는 타입별로 다른 스타일을 사용한다:
  - `Blind`: 기본 레벨 표시
  - `Break` / `DinnerBreak`: "BREAK" 배지 + 남은 시간 카운트다운
  - `HalfBlind` / `HalfBreak`: `½` 표시로 구분

### 5.3 연관 문서

- `contracts/data/DATA-04-db-schema.md` — Flight/Blind 구조 필드
- `../BS-02-lobby/BS-02-02-event-flight.md` — Flight 상태 및 Late Reg 로직

---

## 6. Bomb Pot 서브그룹 (2026-04-20 추가 — SG-008-b13 D3→기획 보강)

Bomb Pot 은 §1.1 Game Rules Move Button Bomb Pot (ID 2) 를 통해 시각적 동작만 제어되고 있었다. team1 settings provider 에 이미 존재하는 code-only 필드 `bombPotEnabled` / `bombPotFrequency` 를 기획에 편입한다.

| ID | 이름 | 타입 (shadcn/ui) | 기본값 | 설명 | 오버레이 영향 |
|:--:|------|-----------------|--------|------|-------------|
| 12 | Bomb Pot Enabled | Switch | OFF | Bomb Pot 발생 가능 여부 | Bomb Pot 배너 활성 조건 |
| 13 | Bomb Pot Frequency | Select | Every 10 Hands | Bomb Pot 발동 빈도 (Off / Every 5 / 10 / 20 / Custom) | 자동 트리거 주기 |

**상호작용**: `bombPotEnabled == false` 일 때 Bomb Pot Frequency (13) 와 Move Button Bomb Pot (2) 는 회색 비활성.

**적용 시점**: CC IDLE 또는 핸드 사이에만 변경 가능 (CONFIRM 분류).

**코드 연동**: `team1-frontend/src/stores/settings_provider.ts` `draft['bombPotEnabled']`, `draft['bombPotFrequency']`.

---

## 7. Straddle 세부 서브그룹 (2026-04-20 추가 — SG-008-b13 D3→기획 보강)

§1.1 Straddle Sleeper (ID 4) 의 확장 옵션. team1 settings provider 에 존재하는 `straddleEnabled` / `straddleType` 를 기획에 편입.

| ID | 이름 | 타입 | 기본값 | 설명 |
|:--:|------|------|--------|------|
| 14 | Straddle Enabled | Switch | OFF | Straddle 기능 전체 토글 (OFF 시 ID 4/5 비활성) |
| 15 | Straddle Type | Select | Classic | Classic / Mississippi / Sleeper — 스트래들 종류 |
| 15a | Sleeper Enabled (`sleeperEnabled`) | Switch | OFF | Sleeper 변형 활성화 (Type=Sleeper 선택 시 동작 토글). 2026-04-26 IMPL-004 추가 |

> `straddleEnabled == false` 이면 Straddle Sleeper (ID 4), Sleeper Final Action (ID 5), `sleeperEnabled` 모두 회색 비활성.

**적용 시점**: 방송 시작 전 CC IDLE 시 변경 권장 (CONFIRM 분류). 핸드 진행 중 변경 금지.

## 8. House Rules 서브그룹 (2026-04-26 추가 — IMPL-004 / SG-008-b13 D3→기획 보강)

`team1-frontend/lib/features/settings/screens/rules_screen.dart §House Rules` 에 이미 SegmentedButton 으로 구현된 4개 키 (`showdown_order`, `under_raise_rule`, `short_all_in_rule`, `dead_button_rule`) 를 기획에 편입한다. 모두 핸드 진행 시 게임 엔진 의사결정에 영향.

| ID | 이름 | 타입 | 기본값 | 옵션 | 설명 |
|:--:|------|------|--------|------|------|
| 16 | Showdown Order | SegmentedButton | `last-aggressor` | `clockwise` / `last-aggressor` | 쇼다운 시 카드 공개 순서. clockwise = 시계 방향 / last-aggressor = 최종 베팅자 우선 |
| 17 | Under-Raise Rule | SegmentedButton | `no-reopen` | `reopen` / `no-reopen` | 풀 레이즈 미만의 올인 시 베팅 라운드 재개 여부 |
| 18 | Short All-In Rule | SegmentedButton | `full-reopen` | `full-reopen` / `partial` | 짧은 올인 처리. full-reopen = 풀 레이즈처럼 처리 / partial = 부분 인정 |
| 19 | Dead Button Rule | SegmentedButton | `dead-button` | `dead-button` / `moving-button` | SB 위치 플레이어 탈락 시 처리. dead-button = 빈 SB / moving-button = 버튼 이동 |

**적용 시점**: 방송 시작 전 CC IDLE 시 (CONFIRM 분류). 핸드 진행 중 변경 시 게임 엔진 일관성 위반 가능 → 차단 권장.

**오버레이 영향**: 쇼다운 카드 공개 애니메이션 순서 (Showdown Order), 베팅 라운드 종료 판정 (Under-Raise / Short All-In), 다음 핸드 SB/BB 표시 (Dead Button).

**WSOP LIVE 정렬 (원칙 1)**: WSOP 토너먼트 룰북의 House Rules 매핑. 각 옵션 라벨은 WSOP 룰북 표기와 일치.

**코드 연동**: `team1-frontend/lib/features/settings/screens/rules_screen.dart` line 250-309 (`House Rules` SettingSection).

## Changelog

| 날짜 | 버전 | 변경 내용 | 변경 유형 |
|------|------|-----------|----------|
| 2026-04-26 | v1.2 | §8 House Rules 서브그룹 추가 (4 키: showdown_order/under_raise_rule/short_all_in_rule/dead_button_rule). IMPL-004 / SG-008-b13 D3→기획 보강 | PRODUCT |
| 2026-04-20 | v1.1 | §6 Bomb Pot 서브그룹 + §7 Straddle 세부 서브그룹 추가 (SG-008-b13 D3 필드 기획 보강) | PRODUCT |
| 2026-04-10 | v1.0 | CCR-017 BlindDetailType 5-타입 enum | - |
