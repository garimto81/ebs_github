---
title: Product SSOT Policy
owner: conductor
tier: internal
governance: v10.3 architect_then_observer
last-updated: 2026-05-08
confluence-page-id: 3818848697
confluence-parent-id: 3811344758
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818848697/EBS+Product+SSOT+Policy
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
| `Lobby_PRD.md` | **S2** | S6 | P2 |
| `Command_Center_PRD.md` | **S3** | S6 | P2 |
| `Back_Office_PRD.md` | **S1** (interim — 이관 대기) | S2, S3, **S7** | P1 |
| `RIVE_Standards.md` | **S4** | S2, S3, S6 | P2 |
| `Game_Rules/**` | **S1** (interim — 이관 대기) | S2, S3, S6, **S8** | P1 |
| `References/**` | conductor (frozen) | All | — |
| `images/`, `visual/`, `archive/` | conductor (asset) | All | — |
| `1. Product.md` | CI generated (`meta_files_blocked`) | — | meta |

**S1 interim 확장**: Back_Office_PRD + Game_Rules 는 외부 인계 정체성 SSOT 성격이라 S1 통합. S7 (Backend) / S8 (Engine) 은 2026-05-08 정합성 감사 (#168) Phase 0 dispatch 로 활성화 완료. ownership 이관 (Back_Office_PRD → S7 / Game_Rules → S8 frontmatter owner 변경) 은 PR #175 / #180 머지 + 각 owner 자율 검증 후 별도 작업.

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
| S3 가 Lobby_PRD.md Edit | block (S2 영역) → contract 동시 변경 필요 시 Phase 0 Architect 가 두 Stream 순차 dispatch |
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
