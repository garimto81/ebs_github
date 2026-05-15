---
title: Product SSOT Policy
owner: conductor
tier: internal
governance: v10.3 architect_then_observer
last-updated: 2026-05-08
confluence-page-id: 3818848697
confluence-parent-id: 3811344758
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818848697/EBS+Product+SSOT+Policy
mirror: none
---

# Product SSOT Policy

`docs/1. Product/` = **EBS 기준 SSOT**. 다른 모든 폴더 (`2. Development/`, `4. Operations/`, `_archive/` 등) 가 Product 와 정합한다.

## 1. SSOT 진술

| 영역 | 역할 |
|------|------|
| `Foundation.md` | EBS 비전 + 핵심 정체성 (3 입력 → 오버레이) |
| `*_PRD.md` (3개) | 외부 인계 PRD (Lobby / Command_Center / Back_Office) |
| `Game_Rules/**` | 22 게임 규칙 명세 (Engine spec 의 외부 측) |
| `RIVE_Standards.md` | Rive 오버레이 그래픽 표준 |
| `References/**` | PokerGFX / WSOP 벤치마크 |
| `images/`, `visual/`, `archive/` | 자산 + 이력 |
| `1. Product.md` | landing (CI generated) |

## 2. derivative-of 룰

외부 인계 PRD 는 정본 기술 명세 (`docs/2. Development/2.{N}/.../Overview.md`) 의 derivative.

### Frontmatter 필수 필드

```yaml
---
derivative-of: ../2. Development/2.{N}/.../Overview.md
if-conflict: derivative-of takes precedence
last-synced: <정본 last-updated 와 동일>
---
```

### 동기화 절차

| 트리거 | 동작 |
|--------|------|
| 정본 (Overview.md) 변경 | derivative PRD 의 본문 + `last-synced` 동시 갱신 (단일 PR) |
| PRD 본문 임의 수정 | 금지 — 정본 먼저 수정 후 cascade |
| Foundation.md 변경 | 3 PRD 모두 재검토 (cascade advisory 출력) |

## 3. Stream 책임 매트릭스

`team_assignment_v10_3.yaml` 의 `streams[*].phases[*].scope_owns` / `scope_read` 를 Product 영역으로 정렬:

| Product 파일 / 폴더 | Owner Stream | Read Streams | Phase |
|--------------------|:-----------:|--------------|:-----:|
| `Foundation.md` | **S1** | S2~S8 (all) | P1 |
| `Lobby.md` | **S2** | S6 | P2 |
| `Command_Center.md` | **S3** | S6 | P2 |
| `Back_Office.md` | **S1** (interim — 이관 대기) | S2, S3, **S7** | P1 |
| `RIVE_Standards.md` | **S4** | S2, S3, S6 | P2 |
| `Game_Rules/**` | **S1** (interim — 이관 대기) | S2, S3, S6, **S8** | P1 |
| `References/**` | conductor (frozen) | All | — |
| `images/`, `visual/`, `archive/` | conductor (asset) | All | — |
| `1. Product.md` | CI generated (`meta_files_blocked`) | — | meta |

**S1 interim 확장**: Back_Office + Game_Rules 는 외부 인계 정체성 SSOT 성격이라 S1 통합. S7 (Backend) / S8 (Engine) 은 2026-05-08 정합성 감사 (#168) Phase 0 dispatch 로 활성화 완료. ownership 이관 (Back_Office → S7 / Game_Rules → S8 frontmatter owner 변경) 은 PR #175 / #180 머지 + 각 owner 자율 검증 후 별도 작업.

## 4. Cascade Routing 4 Layer

| Layer | 도구 / 파일 |
|:-----:|------------|
| L1 frontmatter | `derivative-of` + `if-conflict` |
| L2 reverse-graph | `tools/doc_discovery.py --impact-of` |
| L3 hook advisory | `.claude/hooks/orch_PreToolUse.py:cascade_advisory()` |
| L4 CI gate | `.github/workflows/scope_check.yml` (Product 동시 변경 강제) |

상세 흐름: `docs/4. Operations/Multi_Session_Design_v10.3.md` §1.5.

## 5. Stream 충돌 해결

Stream 이 자기 영역 외 Product 파일 Edit 시도 → `orch_PreToolUse.py` 차단.

| 상황 | 처리 |
|------|------|
| S2 가 Foundation.md Edit | block (S1 영역) → S2 의 의도가 Foundation 변경이면 conductor 또는 S1 세션으로 escalate |
| S3 가 Lobby.md Edit | block (S2 영역) → contract 동시 변경 필요 시 Phase 0 Architect 가 두 Stream 순차 dispatch |
| 동시 수정 충돌 | `team-policy.json` `governance_model.conflict_resolution.ssot_priority` 적용 (Foundation > team-policy > Risk_Matrix > APIs > Backlog) |

## 6. 검증 명령

| 검증 | 명령 |
|------|------|
| Product 모든 파일이 yaml 매핑 | `grep -E "1\\. Product/" docs/4. Operations/team_assignment_v10_3.yaml` |
| phantom path 0 | yaml 의 모든 path 가 실재 (CI scope_check) |
| Foundation cascade 시뮬 | `python tools/doc_discovery.py --impact-of "docs/1. Product/Foundation.md"` |
| Stream scope 차단 검증 | 각 워크트리에서 다른 Stream owner 파일 Edit 시도 → block |

## 7. 본 정책 변경 절차

1. conductor 가 자기 영역 (`docs/4. Operations/`) PR 로 변경
2. 변경 사항이 Stream 매트릭스 영향 시 `team_assignment_v10_3.yaml` 동시 갱신
3. archive INDEX.md 변경 이력 entry 추가
4. main 머지 후 모든 Stream 에 cascade advisory (다음 hook trigger 시 자동)

## 8. 인과관계 매핑 (Causal Map)

ID 체계: `[POL-NN]` = Product SSOT 노드 / `[DEV-NN]` = Development 정본 기술 명세 노드.
`derivative-of` 방향: **DEV → POL** (정본 변경 → PRD 갱신 cascade).

### Product 노드 (POL)

| ID | 문서 | 역할 | 인과 방향 | Confluence ID |
|:--:|------|------|:--------:|:-------------:|
| POL-01 | `Foundation.md` | SSOT 루트 — EBS 비전 + 핵심 정체성 | Source | 3625189547 |
| POL-02 | `Lobby.md` | Lobby PRD (외부 인계) | DEV-01 → POL-02 | 3811672228 |
| POL-03 | `Command_Center.md` | CC PRD (외부 인계) | DEV-04 → POL-03 | 3811901603 |
| POL-04 | `Back_Office.md` | BO PRD (외부 인계) | DEV-02 → POL-04 | 3811967073 |
| POL-05 | `RIVE_Standards.md` | Rive 오버레이 그래픽 표준 | POL-01 → POL-05 | 3816784235 |
| POL-06 | `Game_Rules/Betting_System.md` | 베팅 시스템 룰 (외부 측) | DEV-03 → POL-06 | 3811410570 |
| POL-07 | `Game_Rules/Flop_Games.md` | Flop 계열 게임 룰 | POL-01 → POL-07 | 3811443642 |
| POL-08 | `Game_Rules/Draw.md` | Draw 게임 룰 | POL-01 → POL-08 | 3810853753 |
| POL-09 | `Game_Rules/Seven_Card_Games.md` | 7 Card 게임 룰 | POL-01 → POL-09 | 3811771012 |

### Development 정본 노드 (DEV)

| DEV ID | 파일 (`docs/2. Development/` 기준) | PRD 관계 |
|:------:|-------------------------------------|---------|
| DEV-01 | `2.1 Frontend/Lobby/Overview.md` | POL-02 의 derivative 소스 |
| DEV-02 | `2.2 Backend/Back_Office/Overview.md` | POL-04 의 derivative 소스 |
| DEV-03 | `2.3 Game Engine/Rules/Multi_Hand_v03.md` | POL-06 의 derivative 소스 |
| DEV-04 | `2.4 Command Center/Command_Center_UI/Overview.md` | POL-03 의 derivative 소스 |

**자동 검증**: `python tools/ssot_verify.py` — 모든 POL/DEV 체인 0 orphan + 0 broken link + llms.txt 커버리지 일관성.

## 9. 전체 문서 9 카테고리 분류 정책

`docs/` 전체 780+ `.md` 파일을 **9 카테고리**로 분류. 각 카테고리는 인과관계 필요성, 검증 강도, 정리 기준이 다름.

### 9.1 분류 매트릭스

| ID | 카테고리 | 위치 패턴 | tier | 인과관계 | 검증 강도 |
|:--:|---------|----------|------|:--------:|:---------:|
| **A** | SSOT 정본 | `1. Product/*.md` + `2. Development/*/Overview.md` (4종) | `external` / `internal` | **강제** (POL/DEV ID + derivative-of) | High |
| **B** | Contract spec | `2. Development/2.{2,3,4,5}/.../*.md` 중 `tier: contract` | `contract` | **강제** (derivative-of 또는 related-spec) | High |
| **C** | Change Request | `3. Change Requests/CR-*.md` | (미설정 또는 `internal`) | impacts: [POL-NN, DEV-NN] 매핑 권장 | Medium |
| **D** | Backlog 항목 | `*/Backlog/B-*.md`, `*/Backlog/SG-*.md` | `internal` (status frontmatter 필수) | 약함 (할 일 목록) | Low |
| **E** | Operations 기록 | `4. Operations/Cycle_*/`, `*_Critic_*.md`, `*_Audit_*.md`, `Conductor_Backlog/` | `operations` / `audit` / `log` | **무관** (시간순 기록) | None (검증 제외) |
| **F** | Internal spec | `2. Development/` 중 A/B/D 제외 + `tier: internal` | `internal` | 약함 (owner 명시 + references 약한 참조) | Low |
| **G** | Generated | `_generated/`, `*.md` 중 `tier: generated`, landing index | `generated` | 없음 (CI auto-regen) | None (검증 제외) |
| **H** | Archive | `_archive/`, `_journey/` | `frozen` / `deprecated` / `archive` | 없음 (변경 금지) | None (PreToolUse 차단) |
| **I** | Tier 누락 | frontmatter `tier:` 필드 없음 | (없음) | 분류 필요 | Auto-fix (`tier_autofill.py`) |

### 9.2 카테고리별 처리 정책

#### [A] SSOT 정본 — 강제 인과관계

- `derivative-of` frontmatter 필수
- POL-NN / DEV-NN ID 부여 (§8 인과관계 매핑)
- `Traceability Matrix` 섹션 본문 필수
- 변경 시 cascade advisory 자동 (`tools/doc_discovery.py --impact-of`)
- `confluence-sync: true` (외부 위키 동기화 대상)

#### [B] Contract spec — 강제 인과관계

- `tier: contract` frontmatter 필수
- `derivative-of: <상위 Overview.md>` 또는 `related-spec: [<contract IDs>]`
- 변경 시 영향받는 [A] PRD 동시 갱신 (PR 강제)
- `confluence-sync: true`

#### [C] Change Request (CR-NNN) — 영향 매핑

- frontmatter `impacts: [POL-NN, DEV-NN, contract-spec.md]`
- `status: open | active | done | rejected`
- `done` + 60일 경과 → `_archive/cr-done/` 자동 이동 (Phase 2)
- `confluence-sync: false` (내부 변경 추적 — 외부 공유 불필요)

#### [D] Backlog 항목 (B-NNN, SG-NNN) — 약한 추적

- frontmatter `backlog-status: open | in-progress | done | abandoned` 필수
- `close-date: YYYY-MM-DD` (done 일 때 필수)
- 인과관계 그래프 무관 (할 일 목록)
- `done` / `abandoned` 즉시 `_archive/backlog-done/` 이동 (Phase 2, 날짜 무관)
- `confluence-sync: false`

#### [E] Operations 기록 — 시간순 (인과관계 무관)

- `tier: operations` 또는 `tier: log` 또는 `tier: audit`
- Cycle 로그, Critic reports, Audit reports, Conductor_Backlog 결정 기록
- `ssot_verify.py` 검증 **제외**
- 시간 경과 무관 — 모두 archive 대상 (Phase 2 사용자 결정)
- `confluence-sync: false` (잡음 누적 방지)

#### [F] Internal spec — 약한 참조

- `tier: internal` + frontmatter `owner: <stream-name>` 또는 `stream: SN` 필수
- `references: [<상위 spec>]` 약한 참조 권장 (강제 아님)
- doc-discovery graph orphan (어디서도 link 없음) 검출 시 정리 대상
- `confluence-sync: true` (내부 기술 명세도 위키에 공유)

#### [G] Generated — 검증 제외 (이미 적용)

- `tier: generated`
- CI auto-regen (`tools/spec_aggregate.py`, `tools/manifest_generate.py` 등)
- `_generated/`, `*.md` landing index 포함
- 사람 편집 금지 (frontmatter `owner: ci`)
- `confluence-sync: false`

#### [H] Archive — 변경 금지 (이미 적용)

- `_archive/`, `_journey/` 폴더 전체
- `tier: frozen` 또는 `deprecated`
- PreToolUse hook 가 Edit/Write 차단
- `confluence-sync: false`

#### [I] Tier 누락 — 자동 정리 대상

- `tier:` 필드 없는 frontmatter
- `tools/tier_autofill.py` 가 경로 기반 자동 추론:
  - `Backlog/B-*.md` → `tier: internal` + `backlog-status` 추가
  - `Backlog/SG-*.md` → `tier: internal` + `backlog-status` 추가
  - `3. Change Requests/CR-*.md` → `tier: internal` + `impacts` placeholder
  - 그 외 → 사람 수동 분류 (`tools/ssot_verify.py` 가 list 출력)

### 9.3 Confluence Sync 정책

| 카테고리 | confluence-sync | 사유 |
|:--------:|:---------------:|------|
| A SSOT 정본 | **true** | 외부 인계 |
| B Contract | **true** | 외부 인계 (계약 추적) |
| F Internal spec | **true** | 기술 인계 |
| C Change Request | false | 내부 변경 추적 (외부 잡음) |
| D Backlog | false | 작업 항목 (외부 무관) |
| E Operations | false | 시간순 기록 (외부 잡음) |
| G Generated | false | CI auto |
| H Archive | false | 폐기 이력 |

명시 위치: `docs/_archive/confluence-exclude.txt` (패턴 기반 제외) + 각 파일 frontmatter `confluence-sync: false` (개별 명시).

### 9.4 자동 검증 (`ssot_verify.py` v2)

```bash
python tools/ssot_verify.py
# 9 검증 카테고리:
# [1] derivative-of Chain (A + B)
# [2] Confluence page-id (A)
# [3] llms.txt Coverage (A)
# [4] Category Distribution (전체 — 카테고리별 갯수 보고)
# [5] Tier 누락 (I — orphan 검출)
# [6] Backlog status 완전성 (D)
# [7] CR-NNN impact 매핑 완전성 (C)
# [8] Contract derivative-of 완전성 (B)
# [9] Internal spec owner 명시 (F)
```

### 9.5 정리 정책 (Phase 2 Aggressive Cleanup)

사용자 결정 (2026-05-13):

1. **Orphan 노드 전부 archive**: doc-discovery graph 상 어디서도 참조 안 됨
2. **기록물 전부 archive**: [E] Operations 기록 (Cycle/Critic/Audit/Conductor_Backlog done)
3. **B-NNN done/abandoned 전부 archive**: 날짜 무관, 즉시 이동
4. **Confluence sync 제외**: archive 대상 + `docs/_archive/confluence-exclude.txt` 패턴

도구: `tools/archive_records.py` (Phase 2 신규).

---

**버전**: §9 신규 추가 v1.0 (2026-05-13). 사용자 결정 D1/D2 반영.
