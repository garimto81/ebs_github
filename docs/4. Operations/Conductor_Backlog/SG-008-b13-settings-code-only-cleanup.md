---
id: SG-008-b13
title: "Settings Drift: 30 code-only provider fields — scanner 정규화 + 3분류 (doc-add / doc-expand / code-remove)"
type: spec_gap
sub_type: spec_drift
status: PENDING
owner: conductor  # 1차 분류. 코드 삭제는 team1 세션 집행
conductor_escalation: false  # SG-008 과 동일 패턴 (settings 도메인)
parent: SG-008
created: 2026-04-20
affects_chapter:
  - docs/2. Development/2.1 Frontend/Settings/*.md
protocol: Spec_Gap_Triage §7 (Type D3) — SG-008 3분류 패턴 settings 적용
reimplementability: UNKNOWN
reimplementability_checked: 2026-04-20
reimplementability_notes: "status=PENDING, 30 settings code-only fields 3분류 + scanner 정규화 (F5 Agent C 판정)"
---

# SG-008-b13 — Settings D3: 30 code-only provider fields 3분류

## 공백 서술

`tools/spec_drift_check.py --settings` 2026-04-20 실행 결과:

| 구분 | 수 | 비고 |
|------|---:|------|
| D2 (doc 有 / code 無) | 23 | SG-003 PARTIAL 범위 — 탭별 필드 상세 구현 대기 |
| D3 (code 有 / doc 無) | 30 | 본 SG 의 대상 |
| **D4 (pass)** | 0 | — |

D3 30건 중 Agent C (2026-04-20) 1차 검토 결과 **2분류**:

| 세분 | 수 | 의미 |
|------|---:|------|
| D3a — scanner noise (실제 D4) | 9 | 기획 문서에 필드 존재하나 camelCase vs snake_case 정규화 실패. scanner 버그 |
| D3b — 실제 code-only | 21 | 기획서에 누락된 필드 |

## D3a — scanner 정규화 필요 (9건)

Settings/*.md 에 대소문자/언더스코어 변형으로 **이미 문서화되어 있음**. scanner 가 놓친 것.

| 코드 키 | 문서 위치 | 실제 기획 표기 (추정) |
|---------|-----------|------------------------|
| `animationSpeed` | Graphics.md | `animation_speed` (Animation 서브그룹 ID 10~13) |
| `displayMode` | Statistics.md | `display_mode` |
| `exportFolder` | UI.md | export folder (산문 언급) |
| `frameRate` | UI.md | frame rate / fps |
| `language` | Graphics.md, Preferences.md | language / 로케일 |
| `resolution` | Outputs.md, UI.md | resolution (ID 2~4) |
| `showLeaderboard` | UI.md | leaderboard toggle |
| `showOuts` | UI.md | Outs 표시 |
| `tablePassword` | UI.md | table password |

**조치**: SG-010 (spec_drift_check 정밀화) 에 camelCase ↔ snake_case 정규화 추가. 본 9건은 tool 수정 후 자동 D4 전환 예정.

## D3b — 실제 code-only (21건)

기획서에 언급 없음. SG-008 3분류 패턴으로 처리:

### (a) 기획 추가 — 명세 명백 누락 (11건 추정)

기획 의도상 포함되어야 하는데 누락:

| 코드 키 | 추정 탭 | 판정 근거 |
|---------|---------|----------|
| `blindsFormat` | Display.md | Display §1.1 Blinds 서브그룹 (ID 1~6) 에 format 옵션 포함 누락 |
| `bombPotEnabled` / `bombPotFrequency` | Rules.md | Rules §1.1 Game Rules (ID 1~5) 에 Bomb Pot 항목 누락 |
| `cardStyle` | Graphics.md | §1.2 Card & Player 서브그룹 (ID 6~9) 에 카드 스타일 선택 누락 |
| `highlightActivePlayer` | Graphics.md | §1.2 Card & Player 활성 플레이어 하이라이트 누락 |
| `showPlayerFlag` / `showPlayerOrder` / `showPlayerPhoto` | Graphics.md | §1.2 Card & Player 플레이어 표시 옵션 누락 |
| `showSeatNumber` / `showScoreStrip` / `showChipCount` | Graphics.md / Statistics.md | 플레이어/통계 표시 옵션 누락 |

### (b) 판정 필요 — 설계 결정 대기 (6건 추정)

| 코드 키 | 판정 질문 |
|---------|----------|
| `diagnosticsEnabled` | Admin 진단 모드 노출 범위 (운영 vs dev-only) |
| `fillKeyRouting` | NDI fill/key 라우팅 옵션 (Outputs 에 추가 여부) |
| `layoutPreset` | 프리셋 제공 여부 (5개 Player Layout 이상 확장) |
| `outputProtocol` | Outputs §1.2 Live Pipeline 에 protocol 선택 추가 여부 |
| `precisionDigits` | Display §1.2 Precision 서브그룹 확장 여부 |
| `twoFactorEnabled` | Preferences 2FA 지원 여부 (Auth 와 중복 검토) |

### (c) 코드 삭제 후보 — 모호·legacy (4건 추정)

| 코드 키 | 근거 |
|---------|------|
| `sleeperEnabled` / `straddleEnabled` / `straddleType` | Rules.md §1.1 Game Rules (ID 1~5) 에 straddle 이미 명시. 중복 구현 또는 drift 추정 |
| `showEquity` | Statistics.md §1.1 Equity & Statistics 에 이미 명시. 중복 |

> **판정 주의**: 위 분류는 **1차 추정**. 각 항목은 team1 세션에서 코드 실제 사용처 확인 후 확정.

## 처리 절차

1. **SG-010 (scanner 정밀화)** 에 camelCase ↔ snake_case 정규화 TODO 추가 → D3a 9건 해소
2. **본 SG-008-b13** 에서 D3b 21건 확정 분류 (Conductor + team1 협의)
3. (a) 11건 → Settings/*.md 즉시 보강 PR (Conductor 소유 문서)
4. (b) 6건 → 개별 판정 커밋 (Rules/Outputs/Display/Preferences 별로 section 추가)
5. (c) 4건 → team1 Backlog 등재 (`team1-frontend/backlog.md`) + 코드 삭제 PR

## Links

- scanner: `C:/claude/ebs/tools/spec_drift_check.py --settings`
- parent: `SG-008-api-d3-bulk-documentation.md`
- scanner 정밀화: `SG-010-spec-drift-scanner-precision.md`
- settings 마스터 스키마: `SG-003-settings-6tabs-schema.md`

## Changelog

| 날짜 | 버전 | 변경 내용 | 변경 유형 | 결정 근거 |
|------|------|-----------|----------|----------|
| 2026-04-20 | v1.0 | 최초 작성 (F5 Agent C 판정) — 53건 drift (D2=23 + D3=30) 중 D3=30 3분류 | TECH | 기획이 진실 default 원칙, SG-008 패턴 settings 적용 |
