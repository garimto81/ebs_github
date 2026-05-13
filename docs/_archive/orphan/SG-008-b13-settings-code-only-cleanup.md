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

---

## v2.0 — P8 잔류 8건 Triage (2026-04-20, Agent G)

Agent G 의 scanner 정규화 (P6) + Backend_HTTP §5.17 편입 (P7) 후 재실행:

```
settings 결과 (2026-04-20 P6 fix 적용):
  D2=97, D3=17, D4=39  (이전: D2=23, D3=30, D4=0)
```

D4 39건 확보 (이전 0). D3 잔류 17건 중 **본 triage 대상은 아래 8건**:

### 잔류 8건 분류 + default 제안

| # | 코드 키 | 분류 | 편입 탭 / SG | Default 제안 | 근거 |
|:-:|---------|:--:|--------------|--------------|------|
| 1 | `diagnosticsEnabled` | **(a)** | Preferences 탭 §"개발자 옵션" (신규 서브그룹) | default: `false`. Admin only 토글. 진단 로그 + 성능 오버레이 활성. | Admin 진단 모드. SG-003 Preferences 탭 지원 범위로 편입 안전 (dev/ops 공용) |
| 2 | `twoFactorEnabled` | **(b)** | 별도 SG 승격 — Auth 2FA 정책 결정 (SG-008-b14 후보) | default: `false` (Phase 1 미지원). Phase 2 GGPass 통합 시 재검토. | 2FA 는 Auth_and_Session 과 중복 검토 필요. Settings 단독 결정 불가. Conductor 에스컬레이션 필수 |
| 3 | `layoutPreset` | **(a)** | Graphics 탭 §1.4 "Layout Preset" (신규 서브그룹) | default: `"default"`. enum: `default`/`feature-table`/`final-table`/`heads-up`/`tight`. 5 프리셋. | 기존 §1.1 Layout 서브그룹 (보드/플레이어 배치 개별 조정) 위의 프리셋 선택. WSOP Tournament Director 패턴 정렬 |
| 4 | `outputProtocol` | **(a)** | Outputs 탭 §1.2 Live Pipeline (기존 서브그룹 확장) | default: `"NDI"`. enum: `NDI`/`RTMP`/`SRT`/`DIRECT`. 이미 Outputs.md 본문에 언급된 4종 파이프라인 선택 필드. | Outputs §1.2 Live Pipeline 서브그룹 이미 존재 — protocol 선택 컨트롤 누락 보강 |
| 5 | `precisionDigits` | **(a)** | Display 탭 §1.2 Precision (기존 서브그룹 확장) | default: `0` (정수). int 0~4. 전역 소수 자릿수 기본값. 각 항목 (lb/stack/action/blinds/pot) 이 unset 이면 이 값 사용. | Display.md §1.2 Precision 서브그룹에 개별 precision 필드 5종 이미 존재 — 전역 default 누락 보강 |
| 6 | `sleeperEnabled` | **(a)** | Rules 탭 §1.1 Game Rules — Straddle 확장 | default: `false`. Sleeper straddle (blind 이전 옵션) 허용. `straddleEnabled`/`straddleType` 와 묶음. | Rules.md §1.1 에 straddle 이미 명시. Sleeper 변형 누락 — 추가 보강. SG-008-b13 v1 (c) 분류에서 (a) 로 상향 |
| 7 | `fillKeyRouting` | **(b)** | 별도 SG 승격 — NDI Fill/Key 라우팅 정책 (SG-008-b15 후보) | Phase 1 미지원 default. Phase 2 방송 파이프라인 결정. | Outputs Fill/Key 라우팅은 방송 디바이스 토폴로지 결정이 필요 — Conductor + 외부 방송 팀 합의 필요. Settings 단독 결정 불가 |
| 8 | `blindsFormat` | **(a)** | Display 탭 §1.1 Blinds 서브그룹 | default: `"SB/BB"`. enum: `SB/BB`/`SB/BB/Ante`/`BB-only`/`Compact`. Blinds 표시 포맷. | Display.md §1.1 Blinds 서브그룹 이미 존재 (show_blinds/show_hand_num/currency 등) — format 옵션 누락 보강 |

### 분류 집계

| 분류 | 수 | 처리 |
|------|:--:|------|
| (a) 기획 추가 | **6** | Settings/*.md 보강 섹션 PR — Display/Outputs/Graphics/Preferences/Rules 5 파일 영향 |
| (b) SG 승격 | **2** | SG-008-b14 (twoFactorEnabled / Auth 2FA 정책), SG-008-b15 (fillKeyRouting / NDI Fill&Key 라우팅) |
| (c) 코드 삭제 | **0** | 잔류 8건 전부 기능상 의미 있음 |

### Settings/*.md 보강 위치 제안 (actual edit 은 본 triage 범위 밖)

| 대상 키 | 파일 | 섹션 위치 |
|---------|------|----------|
| `diagnosticsEnabled` | Preferences.md | 신규 §"개발자 옵션 (Admin only)" 서브그룹 |
| `layoutPreset` | Graphics.md | 신규 §1.4 "Layout Preset" 서브그룹 (기존 §1.1~1.3 뒤) |
| `outputProtocol` | Outputs.md | 기존 §1.2 Live Pipeline 서브그룹 내 protocol 필드 추가 |
| `precisionDigits` | Display.md | 기존 §1.2 Precision 서브그룹 상단 "전역 기본값" 필드 추가 |
| `sleeperEnabled` | Rules.md | 기존 §1.1 Game Rules straddle 컬럼 확장 (straddle_type 에 `sleeper` enum 추가) |
| `blindsFormat` | Display.md | 기존 §1.1 Blinds 서브그룹 내 format 필드 추가 |

### (b) 2건 SG 승격 예고

| 후속 SG | 제목 | decision_owner | 예상 scope |
|---------|------|---------------|-----------|
| **SG-008-b14** | Auth 2FA 정책 (twoFactorEnabled) | Conductor | Phase 1 미지원 / Phase 2 GGPass 통합 시 재검토. Auth_and_Session.md + Preferences.md 영향 |
| **SG-008-b15** | NDI Fill/Key 라우팅 정책 (fillKeyRouting) | Conductor + 외부 방송 합의 | 방송 파이프라인 디바이스 토폴로지 의존. Outputs.md §Output Mode 영향 |

### team1 후속 지시 (backlog 등재 제안)

1. **(a) 6건 편입 PR** — `docs/2. Development/2.1 Frontend/Settings/*.md` 5 파일 보강 (Conductor 소유지만 team1 소비자 review 필요)
2. **D2 97건 구현 백로그** — `team1-frontend/Backlog.md` 에 settings 미구현 필드 대량 등재 (SG-003 PARTIAL 후속)
3. **(b) SG-008-b14/b15 추적** — 결정 대기 상태로 Conductor_Backlog 에 파일 생성 (본 SG 종결 조건)

### Backend_HTTP 연계

잔류 8건 중 (a) 6건은 **team1 frontend-only settings field** — Backend API 영향 없음. (`/api/v1/settings/resolved` 응답에 포함되므로 Settings 스키마 확장 시 SG-003 본문 보강 필요). Backend_HTTP.md §5.17.15 의 settings resolved endpoint 참조.

## Links

- scanner: `C:/claude/ebs/tools/spec_drift_check.py --settings`
- parent: `SG-008-api-d3-bulk-documentation.md`
- scanner 정밀화: `SG-010-spec-drift-scanner-precision.md` (P6 에서 camelCase/snake_case/dotted namespace 정규화 적용 완료 — 2026-04-20)
- settings 마스터 스키마: `SG-003-settings-6tabs-schema.md`
- Backend_HTTP settings endpoint: `Backend_HTTP.md §5.17.15`

## Changelog

| 날짜 | 버전 | 변경 내용 | 변경 유형 | 결정 근거 |
|------|------|-----------|----------|----------|
| 2026-04-20 | v1.0 | 최초 작성 (F5 Agent C 판정) — 53건 drift (D2=23 + D3=30) 중 D3=30 3분류 | TECH | 기획이 진실 default 원칙, SG-008 패턴 settings 적용 |
| 2026-04-20 | **v2.0** | P8 잔류 8건 triage 추가 (Agent G). scanner P6 fix 후 D3=30→17 로 감소. (a) 6 / (b) 2 / (c) 0 분류 + Settings/*.md 보강 위치 제안 + SG-008-b14/b15 승격 예고 | TECH | scanner 정규화 (P6) 로 false positive 감소, 실제 판정 필요 잔류 도출 |
