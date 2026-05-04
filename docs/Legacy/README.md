---
title: Legacy — 일회성 broadcast 아카이브
owner: conductor
tier: internal
mirror: none
last-updated: 2026-05-04
---

# Legacy 폴더

## 정의

**일회성** 으로 발행됐지만 더 이상 활성 SSOT 가 아닌 문서들의 보관소. Confluence 폴더 3184328827 의 `Legacy` parent 페이지 (Phase 1 신규) 와 1:1 미러.

## 보관 대상 (Phase 1 이관 시)

다음 카테고리의 Confluence 페이지가 (현재 평면 발행) Confluence 의 `Legacy` parent 로 이동 + 로컬 docs 의 `Legacy/` 로 archive 됩니다:

| 카테고리 | 개수 | 성격 |
|----------|:----:|------|
| `EBS · NOTIFY-*` | 5 | Conductor decision broadcast (1회성) |
| `EBS · IMPL-001~011` | 11 | V9.5 reimplementability audit 결과 (완료) |
| `EBS · B-Q*-*` | 13 | Phase 1 Decision Queue (대부분 DONE / SUPERSEDED) |

## 보관 대상이 아닌 것

- 진행중 backlog 항목 (`docs/4. Operations/Conductor_Backlog/SG-*-*.md`) — **Legacy 아님, 활성 SSOT**
- 진행중 IMPL/B-Q (status: PENDING / IN_PROGRESS) — **Legacy 아님**

case-by-case 검토 후 status: DONE / SUPERSEDED / ARCHIVED 만 Legacy 로 이동.

## 운영 정책

- `mirror: none` frontmatter — sync_confluence.py 의 push 대상 아님 (별도 archive 도구로만 처리)
- 외부 stakeholder 인계 자료에서 제외 (Tier 1 / Tier 2 둘 다 아님)
- 신규 문서 작성 시 Legacy 우선 검토 후 활성 폴더로 옮길지 결정

## 현재 보관 (2026-05-04 기준)

(empty — Phase 1 이관 시 채워짐)
