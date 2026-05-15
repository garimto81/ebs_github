---
id: doc-wiki-schema-v0.1
title: "Doc Wiki Schema — Stream-Owned Topic Wiki + Append-Only Log + PR Draft Candidates"
type: meta_schema
status: DRAFT
owner: SMEM
tier: meta
mirror: none
created: 2026-05-14
legacy-id: null
derivative-of: docs/_meta/conductor-ops/karpathy-idea-ebs-application_2026-05-14_v2.md
related_pr:
  - "#471 (Karpathy idea v2 advisory)"
  - "#474 (SG-042 cross-cutting)"
---

# Doc Wiki Schema — v0.1 DRAFT

## 목적

`tools/doc_discovery.py` / `doc_rag.py` 가 매번 640 raw docs 를 스캔하는 비효율을 해소. **Topic 별 압축 wiki 1 페이지** 를 SSOT 로 사용. raw docs 변경 시 wiki 갱신 트리거.

PR #471 (Karpathy v2 advisory) 의 3 제안 (Stream-Owned Topic Wiki / Append-Only Log.md / PR Draft Candidates) 을 schema 로 frame.

## 디렉토리 레이아웃

```
docs/_meta/doc-wiki/
├── _schema.md                     ← 본 파일 (구조 정의)
├── Index.md                       ← 자동 생성, topic 9개 → wiki 페이지 매핑
├── Log.md                         ← append-only ingest/lint/supersede/contradict/prune 이벤트
├── candidates/                    ← PR Draft 대기 영역 (검토 후 wiki 로 흡수)
│   └── <pr-number>.md
└── <topic-slug>.md                ← topic 별 wiki 1 페이지 (9개 목표)
```

## Topic 매핑 (TBD — SMEM/S10-W 결정 후 확정)

> 본 schema 는 frame 만 제시. **9 카테고리 SSOT v1.0.0** (Cycle 16 도입) 와의 1:1 매핑은 SMEM owner 가 후속 PR 로 확정.

```
9 카테고리 SSOT (Cycle 16) ←──── 1:1 ────→ 9 topic-wiki 페이지
                                            (TBD)
```

권장 매핑 후보 (advisory):

| Stream | Topic Wiki (제안) | source 영역 |
|--------|------------------|------------|
| S2 | `lobby.md` | docs/2. Development/2.1 Frontend/Lobby/ |
| S3 | `command-center.md` | docs/2. Development/2.4 Command Center/ |
| S7 | `back-office.md` | docs/2. Development/2.2 Backend/Back_Office/ |
| S8 | `game-engine.md` | docs/2. Development/2.3 Engine/ |
| S9 | `qa-e2e.md` | docs/4. Operations/QA/, integration-tests/ |
| S10-A | `spec-gap-registry.md` | docs/_meta/conductor-ops/SG-*.md |
| S10-W | `gap-writing.md` | docs/_meta/conductor-ops/ writing artifacts |
| S11 | `devops-ci.md` | .github/workflows/, docs/devops/ |
| SMEM | `meta-memory.md` | memory/, weekly_diff_*.md |

## Topic Wiki 페이지 frontmatter 표준

```yaml
---
id: topic-<slug>
title: "<Topic 이름> — Wiki SSOT"
type: topic_wiki
topic: <slug>                  # 예: lobby / command-center / back-office
owner_stream: <S2|S3|S7|...>   # 1개 stream 만 소유 (cross-cutting 도 1 owner 강제)
status: ACTIVE | DRAFT | DEPRECATED
tier: meta
mirror: none
created: YYYY-MM-DD
last_ingest_at: YYYY-MM-DDTHH:MM:SSZ   # raw docs 마지막 흡수 시각
last_ingest_commit: <SHA>               # 흡수 기준 commit
source_files:                           # 본 wiki 가 압축하는 raw docs
  - docs/2. Development/.../*.md
  - docs/1. Product/<related>.md
token_estimate: <int>                   # wiki 본문 토큰 추정
log_pointer: Log.md#<line>              # append-only log 의 마지막 ingest 라인
candidates_open:                        # 현재 검토 대기 PR Draft list
  - https://github.com/garimto81/ebs_github/pull/<n>
---
```

## Append-Only Log.md 5 event 형식

```
2026-05-14T09:30:00Z [ingest]      lobby           src=docs/2.1.../Lobby/Overview.md#L45-L78  reason=PR-#NNN merged
2026-05-14T09:31:00Z [lint]        lobby           result=PASS  tokens=312  drift=0%
2026-05-14T09:32:00Z [supersede]   back-office     prev=src=docs/.../old.md  now=src=docs/.../new.md
2026-05-14T09:33:00Z [contradict]  command-center  with=lobby  resolution=lobby owner 결정 SG-NNN 신규
2026-05-14T09:34:00Z [prune]       qa-e2e          removed=docs/.../obsolete.md  reason=archive 이동
```

| event | trigger | 책임 stream |
|-------|---------|-------------|
| ingest | raw docs PR merge | 해당 owner_stream |
| lint | wiki 본문 변경 / weekly 재계산 | SMEM |
| supersede | source file 이동/이름 변경 | owner_stream + SMEM |
| contradict | 두 wiki 의 정의 충돌 발견 | S10-A (Gap Registry) |
| prune | source file 삭제/archive | owner_stream + SMEM |

## Candidates 운영 (PR Draft 활용)

- 신규 wiki 또는 큰 변경 = PR Draft 로 `candidates/` 에 push
- `doc_critic` 자동 review (frontmatter / link / token estimate / 9 카테고리 SSOT 정합)
- APPROVE 시 사용자 ready 클릭 1회 → wiki 본문 흡수
- REJECT 시 PR draft 유지 + 사유 comment

**사용자 진입점 = ready 클릭 1회만** (Core Philosophy 정합).

## Conductor 조회 흐름 (raw docs → wiki 전환)

```
신규 cycle 진입 / 사용자 요청
        │
        ▼
Conductor 가 본 _schema.md 확인 → Index.md 로드
        │
        ▼
관련 topic 찾기 (예: "BO chip stack" → back-office.md)
        │
        ▼
wiki 1 페이지 read (~300 tokens)
        │
        ▼
부족하면 source_files 의 raw docs 일부만 fetch (full scan X)
        │
        ▼
Log.md 최근 30줄 (~150 tokens) 확인 → 직전 상태 파악
```

raw docs 640개 (~50k tokens) → wiki 1 페이지 (~300 tokens) = **96% 절감 잠재**.

## 구현 도구 (후속 PR)

| 도구 | 책임 stream | 목적 |
|------|-------------|------|
| `tools/doc_wiki_build.py` | S11 | source_files 변경 시 wiki 자동 재생성 (LLM 압축) |
| `tools/doc_wiki_lint.py` | S11 | mtime vs last_ingest_at drift 감지, stale wiki 보고 |
| `.github/workflows/wiki-candidate-review.yml` | S11 | candidates PR Draft 에 doc_critic 자동 실행 |
| `.github/workflows/log-md-append.yml` | S11 | PR merge 시 5 event 자동 Log.md append |
| `tools/doc_discovery.py --wiki-lookup` | S10-A | Layer 0 에 wiki 우선 조회 추가 |

## 다음 단계 (PR 분리 계획)

```
PR-A (본 PR)    docs/_meta/doc-wiki/_schema.md 초안 (frame only)
                ──► SMEM/S10-W review + 9 카테고리 매핑 확정

PR-B (SMEM)     Index.md + 9 topic-wiki 빈 페이지 (frontmatter only)
                ──► 각 stream owner 가 본문 작성

PR-C (S11)      tools/doc_wiki_build.py + lint + GitHub Action
                ──► 자동화 인프라

PR-D (S2/S3/S7/S8/S9 각자)
                자기 topic-wiki 본문 작성 (source_files 압축)
                ──► 9 stream 병렬

PR-E (S10-A)    tools/doc_discovery.py --wiki-lookup 통합
                ──► Layer 0 우선 조회 적용
```

## 폐기 조건 / 진화

- 9 topic-wiki 가 모두 ACTIVE 상태 → 본 schema 정식 채택
- 토큰 절감 측정치 < 80% 면 schema v0.2 재설계
- 9 카테고리 SSOT 가 cycle N 에서 변경 시 본 schema 도 동시 갱신 (drift 방지)

## 폐기되지 않을 핵심 원칙

> **wiki 는 compression artifact 이지 새 SSOT 가 아니다.** raw docs 가 항상 진실. wiki 는 빠른 조회용 캐시.
> 충돌 시 → raw docs 우선, wiki 갱신.
