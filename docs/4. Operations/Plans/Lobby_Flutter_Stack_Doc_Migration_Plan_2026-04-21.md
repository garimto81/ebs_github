---
title: Plan — Lobby Flutter Desktop 결정에 따른 기획 문서 전수 수정
owner: conductor
tier: internal
last-updated: 2026-04-21
reimplementability: PASS
reimplementability_checked: 2026-04-21
reimplementability_notes: "Migration plan — 48 파일 Tier 분류 + 팀별 PR 분해 + Quasar↔Flutter 컴포넌트 매핑표"
related:
  - docs/1. Product/Foundation.md §5.1 (Lobby Flutter Desktop 스택 결정, 2026-04-21)
  - docs/4. Operations/Reports/2026-04-21-quasar-to-flutter-migration-audit.md (코드 drift 감사, 별개 관점)
  - docs/2. Development/2.1 Frontend/Engineering.md §2.1/§4.3/§5.2 (코드 실측 재작성 완료, 2026-04-21)
---

# Plan — Lobby Flutter Desktop 결정 기획 문서 전수 수정

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-21 | 신규 작성 | Foundation §5.1 Lobby Flutter Desktop 전환 결정에 따른 기획 문서 drift 전수 조사 + 수정 계획 |

## 1. 배경

### 1.1 결정 근거

Foundation.md §5.1 (commit `6b4c9b6`, 2026-04-21) 에서 Lobby/Settings/Graphic Editor 를 **웹 브라우저 → Flutter Desktop** 으로 단일 스택 확정.

근거:
1. Rive 런타임 일치 (GE 프리뷰 ≡ Overlay 송출 자동 보증)
2. 내부 앱 개발팀 즉시 생산성
3. `ebs_common` Dart 패키지 재사용
4. CC 동시 접속 3~5 대 규모에서 웹 URL 배포 이점 축소

### 1.2 두 가지 별개 감사

본 계획은 **기획 문서 drift** 를 다룬다. **코드 drift** 는 이미 별개 감사 완료:

| 관점 | 대상 | 산출 |
|------|------|------|
| **코드** drift | `team1-frontend/lib/` vs `_archive-quasar/src-late/` | commit `0682547`, `2026-04-21-quasar-to-flutter-migration-audit.md` (45+ drift, Engineering.md §2.1/§4.3/§5.2 재작성 완료) |
| **기획 문서** drift (본 계획) | `docs/**/*.md` 전체 | 48 파일 / 317 occurrences / 본 Plan |

두 감사는 **보완적** 이며 중복 없음. 기획 문서 drift 는 외부 개발팀 인계 시 "스펙이 Quasar 인지 Flutter 인지" 혼동을 유발하므로 필수 해소 대상.

## 2. 영향 문서 전수 조사

**grep 패턴**: `Quasar`, `q-[a-z]+` (Vue 컴포넌트), `웹 브라우저`, `브라우저 탭`, `브라우저로 접속`, `Vue`, `Flutter` (부분)

**결과**: 48 파일 / 317 occurrences (2026-04-21 scan).

### 2.1 Tier A — 활성 SSOT, Quasar 컴포넌트 매핑 전면 재작성 필수

기획 문서의 핵심 표 (Element × Quasar component × Binding) 가 직접 Quasar 컴포넌트를 명시하고 있어 **Flutter widget 으로 전면 재작성 필요**.

| # | 경로 | 건수 | 주요 증상 | 작업 규모 |
|:-:|------|:----:|----------|:--------:|
| A1 | `docs/2. Development/2.1 Frontend/Lobby/UI.md` | **53** | 모든 화면 컴포넌트 표가 `q-input`/`q-btn`/`q-dialog`/`q-stepper`/`q-drawer`/`q-tabs` 매핑. ASCII 레이아웃은 유지 가능 | **L (대)** — 거의 전면 재작성 |
| A2 | `docs/2. Development/2.1 Frontend/Graphic_Editor/UI.md` | **48** | 3-Zone 레이아웃이 `q-splitter`/`q-page`/`q-list`/`q-form`/`q-card` 매핑. 반응형 `q-tabs` 분기 | **L** |
| A3 | `docs/2. Development/2.1 Frontend/Settings/UI.md` | 3 | 컴포넌트 일부 + Vue 참조 | **S** |
| A4 | `docs/2. Development/2.1 Frontend/Login/Form.md` | 2 | Login 화면 컴포넌트 (UI.md §0 와 중복) | **XS** |
| A5 | `docs/2. Development/2.1 Frontend/Login/Error_Handling.md` | 4 | 에러 배너/다이얼로그 Quasar 서술 | **S** |
| A6 | `docs/2. Development/2.1 Frontend/Graphic_Editor/Overview.md` | 2 | "Vue 컴포넌트 구조" 참조 | **XS** |
| A7 | `docs/2. Development/2.1 Frontend/Graphic_Editor/Metadata_Editing.md` | 1 | 단일 Quasar 언급 | **XS** |
| A8 | `docs/2. Development/2.1 Frontend/Graphic_Editor/RBAC_Guards.md` | 1 | 단일 언급 | **XS** |

**소계 A**: 8 파일, ≈ 114 건, 대규모 2건 + 소규모 6건.

### 2.2 Tier B — 활성 SSOT, 맥락 서술 교정 (소량)

웹/Quasar 단어가 서술 문맥에 섞여 있으나 컴포넌트 매핑은 없음. **단어 교체 + 문장 1~3개 수정 수준**.

| # | 경로 | 건수 | 주요 증상 |
|:-:|------|:----:|----------|
| B1 | `docs/2. Development/2.1 Frontend/Lobby/Overview.md` | 1 | "웹 브라우저" 잔여 1건 (Foundation §5.1 갱신 후 동기화 필요) |
| B2 | `docs/1. Product/1. Product.md` | 3 | 아키텍처 개요에서 "Admin UI (Team 1, Quasar)" 등 |
| B3 | `docs/2. Development/2.5 Shared/BS_Overview.md` | 1 | 용어 매트릭스 |
| B4 | `docs/2. Development/2.5 Shared/Authentication.md` | 1 | 환경 서술 |
| B5 | `docs/2. Development/2.2 Backend/Engineering/Tech_Stack.md` | 1 | FE 스택 표기 |
| B6 | `docs/2. Development/2.2 Backend/Database/GFSkin_Schema.md` | 1 | 소비자 FE 설명 |
| B7 | `docs/4. Operations/Network_Deployment.md` | 2 | Lobby 네트워크 서술 |
| B8 | `docs/4. Operations/Multi_Session_Handoff.md` | 2 | 팀 기술 스택 레지스트리 |
| B9 | `docs/4. Operations/Spec_Gap_Triage.md` | 3 | 예시 drift 인용 (교체 가능) |
| B10 | `docs/2. Development/2.4 Command Center/Integration_Test_Plan.md` | 3 | E2E 시나리오 내 "브라우저 탭" 언급 |

**소계 B**: 10 파일, ≈ 18 건, 모두 소규모.

### 2.3 Tier C — 역사 문서, 수정 불필요 (원본 보존)

**원칙**: CR/감사 보고서/archive 는 작성 당시 상태를 보존하는 것이 외부 인계 시 의사결정 추적에 필수. 수정하지 않는다.

| # | 카테고리 | 경로 | 건수 |
|:-:|----------|------|:----:|
| C1 | Change Requests done | `docs/3. Change Requests/done/CR-team1-20260410-tech-stack-ssot.md` | 17 |
| C2 | Change Requests done | `docs/3. Change Requests/done/CR-conductor-20260410-ge-ownership-move.md` | 10 |
| C3 | Change Requests done | `docs/3. Change Requests/done/CR-team1-20260410-wsop-parity.md` | 2 |
| C4 | Change Requests done | `docs/3. Change Requests/done/CR-conductor-20260410-gfskin-format-unify.md` | 1 |
| C5 | Change Requests done | `docs/3. Change Requests/done/CR-team4-20260410-bs08-graphic-editor-new.md` | 2 |
| C6 | Audit reports | `docs/4. Operations/Reports/2026-04-21-quasar-to-flutter-migration-audit.md` | 8 |
| C7 | Audit reports | `docs/4. Operations/Reports/2026-04-21-critic-ge-multi-session.md` | 2 |
| C8 | Audit reports | `docs/4. Operations/Reports/2026-04-10-ccr-batch-team-impact.md` | 5 |
| C9 | External reference | `docs/2. Development/2.4 Command Center/References/PokerGFX_Reference.md` (2026-05-04 이관 — SG-030 cascade) | 5 |
| C10 | HTML/archive | `docs/4. Operations/Archive/References_pre_2026-05/images/prd/src/prd-ebs-software-architecture.html` (2026-05-04 archive) | 2 |
| C11 | GE skin-editor archive | `docs/2. Development/2.1 Frontend/Graphic_Editor/References/skin-editor/**/*.md` + `mockups/*.html` + `data/*` | ≈ 80 (EBS-Skin-Editor_v3.prd.md 28건 포함) |

**소계 C**: ≈ 20 파일, ≈ 134 건. **전부 수정 불필요**.

### 2.4 Tier D — Backlog / CR in-progress, 상태 전환만

Backlog 항목은 작업 완료 시 자연스럽게 상태가 전환되므로 **단어 교체 대신 상태 표기 갱신**.

| # | 경로 | 건수 | 처리 |
|:-:|------|:----:|------|
| D1 | `docs/2. Development/2.1 Frontend/Backlog/B-068-team1-frontend-Quasar-프로젝트-실제-초기화.md` | 5 | **Status: DONE** 전환 (commit `2cc13b1`, `0682547` 로 Flutter 전환 완료). 제목은 역사 유지 |
| D2 | `docs/2. Development/2.1 Frontend/Backlog/B-075-React-아카이브-Quasar-이식-B-068-하위.md` | 4 | **Status: DONE** (B-068 하위) |
| D3 | `docs/2. Development/2.1 Frontend/Backlog/B-087-quasar-migration-drift-master.md` | 6 | 이미 IN_PROGRESS (B-087-3/4/5 완결 commit `0dca0fb`). 잔여 Task 지속 |
| D4 | `docs/4. Operations/Conductor_Backlog/B-074-IMPL-01-Lobby-섹션-stale-수정-Team-2-인계.md` | 3 | 재확인 — Lobby "웹" 서술이 아직 유효한지 검증 |
| D5 | `docs/4. Operations/Conductor_Backlog/SG-001-tech-stack-ssot-3way.md` | 6 | **SG-001 해소 선언** — Foundation §5.1 (2026-04-21) 결정으로 3-way 불일치 해소됨. RESOLVED 표기 |
| D6 | `docs/2. Development/2.1 Frontend/Backlog.md` | 1 | 인덱스. 하위 항목 상태 변화 동기화 |
| D7 | `docs/3. Change Requests/in-progress/CR-011-ge-ownership-move.md` | 1 | CCR 폐기 (2026-04-17, §거버넌스 v7) 후 in-progress 리걸 여부 재확인 |
| D8 | `docs/3. Change Requests/in-progress/CR-016-tech-stack-ssot.md` | 1 | Foundation §5.1 결정으로 **해소 완료** 표기 또는 done 이동 |
| D9 | `docs/3. Change Requests/in-progress/CR-037-bs08-graphic-editor-new.md` | 1 | CCR 폐기 후 처리 방침 결정 |

**소계 D**: 9 파일, ≈ 28 건. 상태 표기만 전환 — 내용 재작성 X.

### 2.5 총합

| Tier | 파일 | 건수 | 규모 |
|:----:|:----:|:----:|:----:|
| A | 8 | 114 | L + S 혼합 |
| B | 10 | 18 | 전부 S |
| C | 20 | 134 | 수정 X |
| D | 9 | 28 | 상태 전환 |
| **수정 대상 합계 (A+B+D)** | **27** | **160** | — |

## 3. Quasar → Flutter 컴포넌트 매핑표 (Tier A 작업 지원)

Tier A 재작성 시 사용할 공통 매핑. `team1-frontend/lib/` 실측 기반.

| Quasar (Vue 3) | Flutter 등가 | 비고 |
|----------------|--------------|------|
| `q-btn` (flat/outline/color) | `TextButton` / `OutlinedButton` / `ElevatedButton` | 색상은 Theme 사용 |
| `q-btn icon="..."` | `IconButton` 또는 `Button.icon` | Material Icons |
| `q-input outlined dense` | `TextField` with `InputDecoration(border: OutlineInputBorder(), isDense: true)` | — |
| `q-input type="password"` | `TextField(obscureText: true)` | visibility toggle = `suffixIcon` |
| `q-input mask="..."` | `TextField` + `TextInputFormatter` (`mask_text_input_formatter` 패키지) | — |
| `q-select` | `DropdownButton` 또는 `DropdownButtonFormField` | multi-select = `MultiSelect*` |
| `q-checkbox` | `Checkbox` + `Row(Text)` 또는 `CheckboxListTile` | — |
| `q-radio` | `Radio` / `RadioListTile` | — |
| `q-toggle` | `Switch` / `SwitchListTile` | — |
| `q-dialog persistent` | `showDialog(barrierDismissible: false)` | — |
| `q-stepper` | `Stepper` | — |
| `q-tabs` + `q-tab` + `q-tab-panels` | `TabBar` + `TabBarView` with `TabController` | — |
| `q-drawer side="left" bordered` | `Drawer` 또는 `NavigationRail` | Desktop 은 Rail 권장 |
| `q-header` + `q-toolbar` | `AppBar` | — |
| `q-list dense` + `q-item` | `ListView` + `ListTile` | dense = `dense: true` |
| `q-expansion-item` | `ExpansionTile` | — |
| `q-card` | `Card` | elevation 조정 |
| `q-form` | `Form` with `GlobalKey<FormState>` | validator 패턴 동일 |
| `q-separator` | `Divider` | vertical = `VerticalDivider` |
| `q-chip` | `Chip` | removable = `InputChip` |
| `q-banner` | `MaterialBanner` 또는 커스텀 `Container` | — |
| `q-icon name="..."` | `Icon(Icons.*)` | — |
| `q-splitter` | `Row`/`Column` + `ResizableWidget` (커스텀 또는 `multi_split_view` 패키지) | — |
| `q-infinite-scroll` | `ListView.builder` + `ScrollController.addListener` | — |
| `q-file` (file picker) | `file_picker` 패키지의 `FilePicker.platform.pickFiles()` | — |
| `q-linear-progress` | `LinearProgressIndicator` | — |
| `q-circular-progress` | `CircularProgressIndicator` | — |
| `q-countdown` (수동 tick) | `Timer.periodic` + `Text` | — |
| `q-page` | 화면 루트 `Scaffold` | — |
| `q-toolbar class="bg-red-9 text-white"` | `AppBar(backgroundColor: Colors.red.shade900, foregroundColor: Colors.white)` | — |
| `v-ripple` | `InkWell` 또는 `ListTile` | — |
| `v-model="x"` | `TextEditingController` / `ValueNotifier` 또는 Riverpod `StateProvider` | — |
| Pinia store | Riverpod `Notifier` / `StateNotifier` | EBS 관례: `*_provider.dart` |
| `router-view` + Vue Router | `go_router` `GoRoute` | `app_router.dart` |
| `q-route` push | `context.go('/route')` | — |
| i18n `$t('key')` | `AppLocalizations.of(context)!.key` 또는 `easy_localization` | — |
| `mailto:` href | `url_launcher` 패키지 `launchUrl(Uri.parse("mailto:..."))` | — |
| `browser tab 전환` (앱 백그라운드) | Flutter Desktop `WindowManager` / multi-window | — |

## 4. 단계별 실행 계획

### 4.1 Phase 1 — Tier B 일괄 교체 (Low risk, High coverage)

**decision_owner**: Conductor + 각 owner (Backend/Shared/Operations 교차)

- Tier B 10 파일 × 1~3 건 = 18 건 단어 교체 + 문장 1~2개 재작성
- 예상 PR 규모: 단일 PR (모두 additive 아님, 대체)
- 검증: `grep "웹 브라우저|Quasar" docs/` 로 잔여 확인

**예상 산출물**: `docs(flutter-align): Tier B 맥락 서술 일괄 정정` (+10 파일 / ≈ 30 라인)

### 4.2 Phase 2 — Tier D 상태 전환 (No content change)

**decision_owner**: team1 (Backlog) + Conductor (SG/CR)

- B-068 / B-075: Status DONE + 완료 커밋 SHA 기록
- B-087: IN_PROGRESS 유지 (잔여 task)
- SG-001: RESOLVED (Foundation §5.1 결정)
- CR in-progress 3건: CCR 폐기 정책 (2026-04-17) 에 따른 처리 방침 결정 필요 → Conductor 판정

**예상 산출물**: `docs(status): Tier D Backlog/SG/CR 상태 전환` (+9 파일 / ≈ 20 라인)

### 4.3 Phase 3 — Tier A 대규모 재작성 (핵심 작업)

**decision_owner**: team1 (소유 SSOT)

A1 `Lobby/UI.md` 와 A2 `Graphic_Editor/UI.md` 가 작업량 대부분 차지. 각각 **독립 PR 분리** 권장.

#### 3-A1: `Lobby/UI.md` 재작성

- 컴포넌트 표 **열 헤더** `Quasar 컴포넌트` → `Flutter widget` 전면 교체
- 53 건 중 각 셀을 §3 매핑표에 따라 교체
- ASCII 레이아웃은 유지 (Flutter 도 표현 가능)
- 하단 `**Quasar**: q-header ...` 같은 상태 요약 블록은 `**Flutter**: AppBar + ...` 로 교체
- i18n 키는 그대로 유지 (메시지 스트링은 프레임워크 독립)
- **예상**: PR +1 파일 / ≈ 150 라인 수정

#### 3-A2: `Graphic_Editor/UI.md` 재작성

- 3-Zone `q-splitter` → Flutter `multi_split_view` 또는 `Row` + `ResizableWidget`
- `q-list/q-item` → `ListView/ListTile`
- `q-form + q-card` → `Form + Card`
- 반응형 분기 `q-tabs` → `TabBar`
- **예상**: PR +1 파일 / ≈ 130 라인

#### 3-A3: 나머지 Tier A 6 파일 일괄 PR

- Settings/UI (3건), Login/Form (2), Login/Error_Handling (4), GE/Overview (2), Metadata_Editing (1), RBAC_Guards (1) = 13 건
- 단일 PR 처리 가능
- **예상**: PR +6 파일 / ≈ 40 라인

### 4.4 Phase 4 — 검증

실행 후 각 Phase 별 grep 검증:

```bash
# Tier B + Tier A 완료 후 잔여 확인
grep -rn "Quasar\|q-[a-z]\+\|웹 브라우저\|브라우저 탭\|브라우저로 접속" \
  "docs/2. Development/2.1 Frontend/" \
  "docs/2. Development/2.2 Backend/" \
  "docs/2. Development/2.5 Shared/" \
  "docs/1. Product/" \
  "docs/4. Operations/" \
  --exclude-dir=_archive-quasar \
  --exclude="*/Reports/*" \
  --exclude="*/References/*" \
  --exclude="*/done/*" \
  | wc -l

# 기대값: 0 (Tier C 를 제외하면)
```

`tools/spec_drift_check.py --all` 에 기술스택 항목 추가하여 CI 에 편입 가능 (후속 SG).

### 4.5 Phase 5 — 파급 문서 재검토

| 문서 | 점검 내용 |
|------|----------|
| `Foundation.md §5.1` | 스택 결정 문구 유지 (이미 완료) |
| `Engineering.md §2.1/§4.3/§5.2` | 코드 실측 정렬 (이미 완료 commit `0682547`) |
| `Lobby/Overview.md` Lobby-CC 관계 표 | "웹 프론트 페이지 (브라우저)" → "Flutter Desktop 앱" 전환 확인 (Tier B1 에서 처리) |
| `docs/_generated/**` | CI 자동 재생성 — `tools/backlog_aggregate.py` 실행 |
| `docs/mockups/*.html` | HTML 목업 자체는 포맷이므로 변경 없음. 단 레이아웃 주석에 Quasar 라벨이 있다면 교체 |

## 5. 팀별 PR 분해 (병렬 가능)

| PR | Phase | 팀 | 파일 | 규모 |
|----|:-----:|:--:|:----:|:----:|
| PR-α | 1 (Tier B) | Conductor | 10 | S |
| PR-β | 2 (Tier D) | team1 + Conductor | 9 | XS |
| PR-γ | 3-A1 (Lobby/UI) | team1 | 1 | **L** |
| PR-δ | 3-A2 (GE/UI) | team1 | 1 | **L** |
| PR-ε | 3-A3 (Tier A 잔여) | team1 | 6 | S |

**총 5 PR, 27 파일, ≈ 270 라인**. α/β/γ/δ/ε 모두 병렬 가능 (경로 겹치지 않음). γ/δ 는 가장 큰 작업이므로 team1 세션 1~2 시간 소요 예상.

## 6. 리스크

| 리스크 | 영향 | 완화 |
|--------|------|------|
| Flutter 매핑 오류 (q-splitter 등 비표준) | 재작성 된 스펙이 실제 구현과 불일치 | §3 매핑표 + `team1-frontend/lib/` 실측 cross-check 필수 |
| Quasar 라벨 완전 제거 시 역사 컨텍스트 손실 | "왜 변경되었나?" 추적 어려움 | Tier C (CR done + 감사 보고서) 보존. Tier A 문서 상단 Edit History 에 2026-04-21 Flutter 전환 row 기록 |
| CR in-progress 3건 (CCR 폐기 후) 처리 방침 불명확 | Tier D5 block | Phase 2 에서 Conductor 단일 판정. 권고: 내용을 해당 SSOT 로 이동 후 done 처리 |
| GE UI 재작성 시 Rive 런타임 차이 재확인 필요 | 프리뷰 ≡ 송출 보장 유지 | Foundation §5.1 근거 (1) 재검증: Rive Flutter runtime `rive` 패키지 사용 확인 |
| Integration_Test_Plan.md 의 "브라우저 탭" 3건 | E2E 테스트 단계 재정의 | flutter_driver / integration_test 기반으로 시나리오 재작성 |

## 7. 작업 승인 체크리스트

| 항목 | 상태 |
|------|:----:|
| 48 파일 / 317 건 전수 조사 | ✓ |
| Tier A/B/C/D 분류 | ✓ |
| Quasar↔Flutter 매핑표 | ✓ |
| Phase 1-5 실행 순서 | ✓ |
| 팀별 PR 분해 (5 PR) | ✓ |
| 리스크 + 완화 전략 | ✓ |
| **실제 Phase 1 실행** | 대기 (사용자 confirm) |
| **실제 Phase 2 실행** | 대기 |
| **실제 Phase 3 실행 (A1/A2/A3)** | 대기 |
| **Phase 4 검증 grep** | 대기 |

## 8. 후속 /team 실행 권고

사용자 승인 후 실행 순서:

```
/team "Phase 1: Tier B 10 파일 맥락 서술 일괄 정정"
/team "Phase 2: Tier D 9 파일 상태 전환 (SG-001 RESOLVED, B-068/075 DONE, CR in-progress 처리)"
/team "Phase 3-A1: Lobby/UI.md 53 Quasar 컴포넌트 → Flutter 전면 재작성"
/team "Phase 3-A2: Graphic_Editor/UI.md 48 Quasar → Flutter 전면 재작성"
/team "Phase 3-A3: Tier A 잔여 6 파일 일괄 정정"
/team "Phase 4: grep 검증 + 잔여 drift 해소"
```

γ (Lobby/UI) 와 δ (GE/UI) 는 **team1 세션이 병렬 수행 가능**. α (Conductor), β (team1+Conductor) 와 충돌 없음.

## 9. 결론

| 질문 | 답 |
|------|-----|
| 수정 대상 문서 총 몇 개? | **27 파일** (Tier A 8 + B 10 + D 9). Tier C 20 파일은 역사 보존 |
| 가장 큰 작업? | **Lobby/UI.md (53건)** + **Graphic_Editor/UI.md (48건)** — 각각 독립 L 규모 PR |
| 단어 교체만으로 충분? | **아니오**. Tier A 는 컴포넌트 표가 `Quasar` 열을 `Flutter widget` 으로 재구조화해야 함 |
| 이미 완료된 작업은? | Foundation §5.1 (결정), Engineering.md §2.1/§4.3/§5.2 (코드 실측), B-087-3/4/5 (일부 audit) |
| 외부 개발팀 인계 영향? | 본 계획 완료 전에는 "스펙이 Quasar 인지 Flutter 인지" 혼동 발생 가능. 우선순위 **P1** |

본 Plan 이 SSOT — 사용자 confirm 후 6 /team 트랜잭션으로 완수.
