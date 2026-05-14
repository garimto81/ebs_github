---
id: doc-wiki-index
title: Doc Wiki Index — 9 Topic-Wiki SSOT 카탈로그
type: meta_index
tier: meta
confluence-sync: false
owner: SMEM
status: ACTIVE
created: 2026-05-14
legacy-id: null
derivative-of: docs/_meta/doc-wiki/_schema.md
---

# Doc Wiki Index

> **자동 생성 대상** — `tools/doc_wiki_build.py` 구현 후 자동화 예정 (S11 후속 PR).
> 현재: 수동 관리 (SMEM 담당).
> 기준: **9 카테고리 SSOT v1.0.0** (Cycle 16, PR #393, 2026-05-13).

## 9 카테고리 × 9 Topic-Wiki 1:1 매핑

| 9-카테고리 SSOT v1.0.0 | Topic Wiki | Owner Stream | Status | source_files 요약 | token_estimate |
|------------------------|------------|:------------:|:------:|-------------------|:--------------:|
| Lobby UI | [lobby.md](lobby.md) | S2 | DRAFT | `docs/2. Development/2.1 Frontend/Lobby/**` | 0 |
| Command Center | [command-center.md](command-center.md) | S3 | DRAFT | `docs/2. Development/2.4 Command Center/**` | 0 |
| Back Office | [back-office.md](back-office.md) | S7 | DRAFT | `docs/2. Development/2.2 Backend/Back_Office/**` | 0 |
| Game Engine + RIVE/Overlay | [game-engine.md](game-engine.md) | S8 | DRAFT | `docs/2. Development/2.3 Engine/**` | 0 |
| QA / Integration | [qa-e2e.md](qa-e2e.md) | S9 | DRAFT | `docs/4. Operations/QA/**, tests/**` | 0 |
| Gap Registry | [spec-gap-registry.md](spec-gap-registry.md) | S10-A | DRAFT | `docs/_meta/conductor-ops/SG-*.md` | 0 |
| Gap Writing | [gap-writing.md](gap-writing.md) | S10-W | DRAFT | `docs/_meta/conductor-ops/gap-*.md` | 0 |
| DevOps / Runtime | [devops-ci.md](devops-ci.md) | S11 | DRAFT | `.github/workflows/**, docs/devops/**` | 0 |
| Conductor Ops / Meta | [meta-memory.md](meta-memory.md) | SMEM | DRAFT | `memory/**, weekly_diff_*.md` | 0 |

## 상태 범례

| 상태 | 설명 |
|------|------|
| `DRAFT` | frontmatter 작성 완료, 본문 미작성 (source_files 압축 대기) |
| `ACTIVE` | 본문 작성 완료, 최신 source_files 압축 반영 |
| `STALE` | source_files 변경 후 wiki 미갱신 (lint 경고 발생) |
| `DEPRECATED` | 폐기됨 (Log.md 에 `prune` 이벤트 기록) |

## 관련 파일

| 파일 | 역할 |
|------|------|
| [_schema.md](_schema.md) | Doc Wiki 구조 정의 (v0.1, PR #476) |
| [Log.md](Log.md) | Append-only ingest/lint/supersede/contradict/prune 이벤트 |
| `candidates/` | PR Draft 검토 대기 영역 (미생성 — S11 후속 PR 에서 구현) |

## Karpathy P2 프레임 진행 계획

```
PR-A (#476 — 머지 대기)   docs/_meta/doc-wiki/_schema.md
PR-B (본 PR)               Index.md + Log.md + 9 topic frontmatter
PR-C (S11)                 tools/doc_wiki_build/lint + GitHub Actions
PR-D (S2/S3/S7/S8/S9 각자) 자기 topic-wiki 본문 작성 (Wave 병렬)
PR-E (S10-A)               doc_discovery.py --wiki-lookup 통합 (Layer 0)
```

> **wiki 는 compression artifact** — raw docs 가 항상 진실. wiki 는 빠른 조회용 캐시.
> 충돌 시 raw docs 우선, wiki 갱신.
