---
title: Karpathy LLM Wiki 패턴 EBS 적용 v2 — 멀티스트림 분산 wiki + 9-카테고리 SSOT 결합
tier: meta
confluence-sync: false
owner: conductor
legacy-id: null
last-updated: 2026-05-14
---

# Karpathy LLM Wiki 패턴 EBS 적용 v2

> 작성일: 2026-05-14
> 담당: Gap Writing Stream (S10-W) — 제안만, 다른 스트림 SCOPE 침범 없음
> 기반: v1 (`karpathy-idea-ebs-application_2026-05-14.md`)
> 차별점: WebFetch 재추출 신규 컨셉 5개 + 멀티스트림 분산 모델 + 9-카테고리 SSOT(Cycle 16) 결합

---

## 0. v1 vs v2 차이 (요약)

v1 은 wiki + memo + lint 3 제안에 집중했다. v2 는 다음 5 영역을 추가한다.

| 영역 | v1 상태 | v2 추가 |
|------|:-------:|---------|
| Log.md 이중 구조 (Index + Log) | 미반영 | 신규 제안 B 의 핵심 |
| Three-tier memory (Facts / Working / Wisdom) | 미반영 | EBS MEMORY.md 매핑 |
| Typed-edge knowledge graph | 미반영 | 기존 derivative-of 확장 |
| Candidates staging (PR-as-stage) | 미반영 | 신규 제안 C |
| Branching for scale | 미반영 | 9-카테고리 SSOT 와 결합 |
| Wiki 단일 Conductor 모델 | v1 가정 | 멀티스트림 분산 wiki 로 교정 |

핵심 교정: EBS 는 이미 9 stream 분산 운영 중이다. v1 의 단일 Conductor 가 wiki 전체를 관리하는 모델은 멀티세션 격리 원칙과 충돌. v2 는 **각 stream 이 자기 topic-wiki 만 갱신** 하는 분산 wiki 로 재설계.

---

## 1. Karpathy 컨셉 재추출 (v1 미반영 5개)

### 1.1 Index.md + Log.md 이중 구조

Karpathy 원문에서 wiki 인프라의 두 축:

```
Index.md   = content-oriented catalog (메타 + 카테고리별 wiki 페이지 목록)
             LLM 이 쿼리 시 가장 먼저 읽는 entry
Log.md     = append-only chronological record
             prefix 패턴 예: ## [2026-04-02] ingest | Title
             표준 도구로 파싱 가능
```

EBS 대응 현황:
- Index 역할: `docs/_generated/full-index.md` (767 줄, 정적 표) - 부분 대응
- Log 역할: **부재** - 가장 큰 갭. case_studies/ 가 있으나 사례 학습용이지 ingest log 아님

### 1.2 Three-tier memory

| Tier | 정의 | EBS 대응 |
|------|------|---------|
| Facts | 불변 사실 | docs/ 원본 파일 (raw sources) |
| Working memory | 현재 컨텍스트 | session, MEMORY.md 본문 |
| Wisdom | 큐레이션된 종합 | case_studies/ + weekly_diff |

이 매핑이 명시되어 있지 않아 현재 운영자가 같은 정보를 여러 곳에 중복 기록한다.

### 1.3 Typed-edge knowledge graph

Karpathy 확장: wiki 페이지 간 관계를 단순 링크가 아닌 typed edge 로 표현.
예: A `derives-from` B, A `supersedes` B, A `contradicts` B, A `implements` B.

EBS 현황: frontmatter `derivative-of` 만 존재. supersedes, related-to, contradicts 등 미정의.

### 1.4 Candidates staging

새 wiki 페이지를 main wiki 에 즉시 promote 하지 않고, candidates/ 폴더에 보류했다가 검토 후 promote.
EBS 의 GitHub PR Draft 메커니즘과 자연스럽게 매칭됨.

### 1.5 Branching for scale

corpus 가 커지면 routing layer 를 두어 topic branch 로 partition.
쿼리 latency 가 corpus 크기와 무관하게 flat.

EBS 의 9-카테고리 SSOT v1.0.0 (Cycle 16, 2026-05-13 weekly_diff) 이 이 patterns 의 자연스러운 branch 정의.

---

## 2. EBS 멀티스트림 컨텍스트 재분석

### 2.1 9 stream 분산 운영 현황

```
                   +---------------------+
                   |   Conductor (s0)    |
                   +----------+----------+
                              |
        +---------------------+---------------------+
        |             |              |              |
   +----+----+   +----+----+    +----+----+   +----+----+
   |  s2     |   |  s3     |    |  s7     |   |  s8     |
   | Lobby   |   |   CC    |    | Backend |   | Engine  |
   +---------+   +---------+    +---------+   +---------+

   +---------+   +---------+    +---------+   +---------+
   |  s9     |   | s10-A   |    | s10-W   |   |  s11    |
   |   QA    |   |gap audit|    |gap write|   | DevOps  |
   +---------+   +---------+    +---------+   +---------+

                  +---------+
                  |  smem   |
                  | memory  |
                  +---------+
```

각 stream 은 자기 scope_owns 안의 docs/ 영역만 수정 가능. PreToolUse hook 이 scope 위반을 차단한다.

### 2.2 단일 conductor wiki 의 문제점

v1 제안의 `docs/_meta/doc-wiki/` 폴더는 **누가 갱신하는가** 가 정의되지 않았다.
- s10-W 가 갱신? → Lobby/CC/BO 등 다른 stream 영역에 대한 wiki 도 s10-W 가 작성. scope 위반.
- Conductor 가 갱신? → AI Conductor 가 9 stream 의 모든 변경을 수동 추적. 사용자 진입점 증가.

### 2.3 분산 wiki 모델로의 교정

```
docs/_meta/doc-wiki/
├── _schema.md              # conductor 가 한 번 작성 (구조 선언)
├── Index.md                # smem 또는 자동 빌드 (모든 topic-wiki 목록)
├── Log.md                  # smem append-only (모든 stream 의 ingest event 누적)
│
├── topic-lobby.md          # s2 owns (Lobby stream)
├── topic-cc.md             # s3 owns (CC stream)
├── topic-backend.md        # s7 owns (Backend stream)
├── topic-engine.md         # s8 owns (Engine stream)
├── topic-qa.md             # s9 owns (QA stream)
├── topic-devops.md         # s11 owns (DevOps stream)
├── topic-gap-registry.md   # s10-A owns (Gap Audit)
└── topic-conductor-ops.md  # conductor owns (meta + multi-session)
```

이 매핑이 9 stream scope 와 1:1 정합한다. 각 stream 이 자기 topic-wiki 만 갱신.

### 2.4 9-카테고리 SSOT v1.0.0 과의 결합

Cycle 16 (2026-05-13) 에서 사용자가 표 9 카테고리 SSOT 를 확정 (PR #393). 9 카테고리는 다음과 같이 topic-wiki 와 매핑된다.

| 9-카테고리 (SSOT v1.0.0) | topic-wiki | 담당 stream |
|--------------------------|------------|-------------|
| RIVE / Overlay | topic-overlay.md | s8 (engine) |
| Lobby UI | topic-lobby.md | s2 |
| Command Center | topic-cc.md | s3 |
| Back Office | topic-backend.md | s7 |
| Game Engine | topic-engine.md | s8 |
| QA / Integration | topic-qa.md | s9 |
| DevOps / Runtime | topic-devops.md | s11 |
| Gap Registry | topic-gap-registry.md | s10-A |
| Conductor Ops | topic-conductor-ops.md | conductor |

9 카테고리 + 9 stream + 9 topic-wiki 의 **3중 1:1 매핑**. 이 정합성이 v2 분산 모델의 근본 안전성.

---

## 3. v2 신규 제안 3개

### 제안 A: Stream-Owned Topic Wiki (v1 제안 1의 분산 재설계)

**What**: v1 의 `docs/_meta/doc-wiki/` 를 멀티스트림 격리 원칙에 맞게 재설계. 각 stream 이 자기 topic-wiki 1 개만 갱신.

**How — 구현 단계**:

```
Step 1: conductor 가 _schema.md 작성 (1 회)
        담당: smem
        내용: 9 topic-wiki 의 frontmatter 표준, 갱신 조건, Cross-link 규칙

Step 2: 각 stream 이 자기 topic-wiki 초기 작성 (PR Draft 로 staging)
        담당: s2/s3/s7/s8/s9/s10-A/s11 (분산 병렬)
        scope: 각자 scope_owns 안의 docs/ 만 source 로 사용
        PR title: "feat(doc-wiki): topic-<stream> 초기 작성"

Step 3: smem 이 Index.md 자동 빌드 + Log.md 첫 entry 작성
        담당: smem
        Log entry 형식:
          ## [2026-05-14] init | topic-lobby (s2)
          source: 12 files in docs/2.1 Frontend/Lobby/**
          decisions: 5, gaps: 2, derivatives: 3

Step 4: CLAUDE.md (worktree root) 에 wiki 우선 조회 1 줄 추가
        담당: 각 stream worktree CLAUDE.md
        규칙: 작업 시작 시 자기 topic-wiki 먼저 읽고, 부족하면 raw docs 확장
```

**Impact**:
- 토큰 절감: 각 stream 작업 시 자기 topic-wiki ~300 tokens vs raw scope docs ~5,000 tokens = 94%
- scope 격리 유지: 다른 stream 영역 wiki 접근 불필요 (cross-link 만 read-only)
- 병렬 갱신: 9 stream 이 자기 wiki 를 독립 갱신 → bottleneck 0

**Risk**:
- 각 stream 이 자기 wiki 갱신을 잊으면 stale → 해결: 제안 B 의 Log.md hook 으로 변경 감지 시 강제 알림
- topic 간 cross-link 누락 → 해결: smem 의 lint loop (제안 C 의 일부)

### 제안 B: Append-Only Log.md (Karpathy Log.md 직접 적용, v1 미반영)

**What**: 모든 stream 의 ingest event 를 단일 Log.md 에 append-only 로 기록.

**파일 위치**: `docs/_meta/doc-wiki/Log.md`

**Entry 표준 형식** (parseable):

```
## [YYYY-MM-DD HH:MM] <event> | <topic> (<stream>)
- source: <변경된 파일 또는 PR>
- decisions: <count>
- gaps: <count>
- derivatives-affected: <count>
- pr: <PR URL or hash>
```

**event 종류** (5 가지):
1. `ingest` — 새 정보 흡수 (PR merge 후)
2. `lint` — 정합성 검증 결과
3. `supersede` — 기존 wiki 페이지를 신규로 대체
4. `contradict` — 모순 감지 (사람 개입 필요)
5. `prune` — stale 페이지 제거

**How — 구현 단계**:

```
Step 1: smem 이 Log.md 초기화 + frontmatter 작성
        담당: smem
        frontmatter:
          tier: meta
          confluence-sync: false
          owner: smem
          append-only: true

Step 2: GitHub Action 또는 post-merge hook 신설
        담당: s11 (DevOps)
        동작: PR merge 시 변경 path 분석 → 해당 topic-wiki 식별 → Log.md 에 ingest entry 추가
        구현 위치: .github/workflows/log-md-append.yml (s11 scope)

Step 3: smem 이 주간 Log.md 요약을 weekly_diff_YYYY-MM-DD.md 에 통합
        담당: smem
        기존 weekly_diff 메커니즘 확장 (Cycle 7/16 등 이미 운영 중)

Step 4: tools/doc_log_query.py 신규 작성 (선택)
        담당: s11 또는 smem
        용도: "최근 7일 Lobby 변경" 같은 쿼리를 Log.md grep 으로 즉답
```

**Impact**:
- 시간축 추적: 어느 stream 이 언제 무엇을 변경했는지 단일 파일로 추적
- weekly_diff 자동화 보조: smem 의 수동 합성 부담 감소
- 멀티세션 onboarding: 신규 cycle 진입 시 Log.md 최근 30 줄만 읽어도 직전 상태 파악

**Risk**:
- Log.md 파일 크기 증가 → 해결: 월 단위 rotate (`Log_2026-05.md`)
- 자동 hook 오작동 시 entry 누락 → 해결: lint 가 PR merge log 와 Log.md entry 를 cross-check

### 제안 C: Candidates Staging via PR Draft (v1 미반영)

**What**: 새 wiki 페이지를 main wiki 에 즉시 promote 하지 않고, PR Draft 상태로 staging 한다. 검토 후 ready 전환 → merge → main wiki promote.

EBS 의 GitHub PR Draft 메커니즘이 Karpathy candidates/ 폴더의 자연스러운 구현.

**How — 운영 규칙**:

```
1. 새 wiki 페이지 작성 시 PR 을 Draft 로 생성
2. PR title 패턴: "wiki-candidate: <topic> — <reason>"
3. PR description 에 다음 4 항목 의무:
   - 어떤 raw docs 를 ingest 했는가
   - 어떤 결정/갭/derivative 를 추출했는가
   - 기존 wiki 페이지와의 supersede / contradict / extend 관계
   - 검증 방법 (lint 통과 여부, cross-link 확인)
4. doc_critic agent 가 자동 검토 (frontmatter, cross-link, stale 여부)
5. doc_critic APPROVE 시 PR ready 전환 가능
6. ready → merge 시점에 자동으로 Log.md ingest entry 추가
```

**How — 구현 단계**:

```
Step 1: conductor 가 _schema.md 에 candidates 규칙 추가
        담당: smem (conductor 위임)

Step 2: GitHub Actions: PR Draft 상태에서 doc_critic 자동 호출
        담당: s11
        구현: .github/workflows/wiki-candidate-review.yml
        트리거: PR 변경 path 가 docs/_meta/doc-wiki/** 일 때

Step 3: doc_critic 결과를 PR comment 로 게시
        담당: doc_critic agent (이미 존재)
        결과 형식: APPROVE / REJECT (reason)

Step 4: 사용자 진입점 = PR ready 전환 1 회 (Draft → ready)
        다른 모든 결정 (doc_critic 검토, lint, Log.md 추가) 은 자율
```

**Impact**:
- 사용자 진입점: PR ready 클릭 1 회 (Core Philosophy 정합)
- 자율 이터레이션: doc_critic 검토 + lint + Log.md 추가 모두 자율
- 검증 강화: main wiki 에 promote 되기 전 doc_critic 게이트 통과 보장

**Risk**:
- PR Draft 가 장기 stale → 해결: 30 일 미 ready 전환 시 자동 close + 알림
- doc_critic 잘못된 REJECT → 해결: 사용자 override 가능 (수동 ready 전환)

---

## 4. v1 제안과의 관계

| v1 제안 | v2 처분 | 사유 |
|---------|---------|------|
| 제안 1: Doc Wiki 단일 폴더 | **REVISE** | 제안 A 가 분산 모델로 재설계 |
| 제안 2: Query Memo Cache | **KEEP** | v2 와 무관, 그대로 유지 |
| 제안 3: Doc Wiki Lint | **EXTEND** | 제안 B 의 Log.md 와 결합. Lint 가 Log.md 의 contradict event 를 발생시킴 |

v2 는 v1 을 폐기하지 않고 보강한다 (additive). v1 의 Query Memo Cache 는 stream 별 wiki 와 무관하므로 그대로 운영.

---

## 5. 통합 아키텍처 (v2 최종)

### 5.1 Read 경로 (쿼리 시)

```
사용자 요청 수신
    |
    v
[Query Memo Cache]            -- hit --> 즉답 (~50 tokens)         (v1 제안 2)
    | miss
    v
[stream worktree CLAUDE.md]   -- wiki 우선 조회 규칙 trigger        (v2 제안 A Step 4)
    |
    v
[topic-<stream>.md]           -- 자기 topic-wiki 우선 (~300 tokens) (v2 제안 A)
    | wiki miss or stale
    v
[Index.md cross-link]         -- 다른 topic 의 cross-link 확인       (v2 제안 A Step 3)
    | 의미 검색 필요
    v
[doc_discovery.py Layer 1]    -- frontmatter 매칭 (~1,000 tokens)   (기존)
    | 의미 검색 필요
    v
[doc_rag.py Layer 2]          -- Ollama bge-m3 (~2,000 tokens)      (기존)
    |
    v
결과 --> [Query Memo Cache 저장] + [Log.md ingest entry trigger]
                                       (v1 제안 2)        (v2 제안 B)
```

### 5.2 Write 경로 (PR merge 시)

```
PR merge 발생 (path: docs/<stream>/**)
    |
    v
[GitHub Action: log-md-append.yml]                                   (v2 제안 B Step 2)
    |
    v
변경 path 분석 -> 해당 topic-wiki 식별
    |
    v
[topic-<stream>.md 자동 stale 마킹]
    |
    v
해당 stream 이 wiki 갱신 PR Draft 생성                                (v2 제안 C)
    |
    v
[doc_critic agent 자동 검토]                                         (v2 제안 C Step 2)
    |
    v
APPROVE -> PR ready -> merge -> Log.md ingest entry                  (v2 제안 B + C)
```

### 5.3 Lint 경로 (주간)

```
주 1 회 (또는 manual trigger)
    |
    v
[tools/doc_wiki_lint.py]                                             (v1 제안 3 + v2 확장)
    |
    +-- topic-wiki last-ingest vs source files mtime
    +-- Index.md cross-link 무결성
    +-- Log.md entry 와 Git history 일관성
    +-- typed-edge graph 의 supersede/contradict cycle 감지
    |
    v
이상 발견 시 -> Log.md 에 [lint] 또는 [contradict] event 추가         (v2 제안 B)
    |
    v
contradict 인 경우 -> 사람 개입 알림 (사용자 진입점 1 회)              (Core Philosophy)
```

### 5.4 토큰 예산 비교 (v1 vs v2)

| 경로 | v1 토큰 | v2 토큰 | 변화 |
|------|:-------:|:-------:|:----:|
| Query Memo hit | ~50 | ~50 | - |
| Doc Wiki hit (단일) | ~300 | - | - |
| Topic Wiki hit (분산, stream 격리) | - | ~250 | -17% |
| Index.md cross-link | - | ~100 | NEW |
| Layer 1 fallback | ~1,000 | ~1,000 | - |
| Layer 2 fallback | ~2,000-4,000 | ~2,000-4,000 | - |
| 현재 (매번 전체 scan) | ~8,000-15,000 | ~8,000-15,000 | - |

v2 추가 절감: stream 격리로 자기 topic 만 읽으면 충분 (17% 추가 절감).
**v2 총 절감 예상**: 약 87-92% (v1 의 85-90% 대비 약 2-3%p 추가).

---

## 6. CLAUDE.md Core Philosophy 정합성 점검

| Core Philosophy 원칙 | v2 정합도 | 근거 |
|---------------------|:---------:|------|
| 사용자 진입점 최소화 | PASS | 제안 C 의 PR ready 클릭 1 회만 사용자 영역 |
| 자율 이터레이션 최대화 | PASS | doc_critic, lint, Log.md 추가 모두 자율 |
| A/B/C 옵션 나열 금지 | PASS | 본 문서는 사용자 결정 항목 없음. 분산 모델 확정 제안 |
| 옵션 강요 금지 | PASS | 9 stream 의 자율 갱신, scope 위반 시 hook 차단 |
| 자율 결정 + 결과 보고 | PASS | conductor 는 _schema.md 만 한 번 결정, 이후 자율 |
| critic / architect 자율 다중 검증 | PASS | doc_critic agent 가 PR Draft 단계에서 자율 검토 |

R3 (AI Conductor 메타 경로 정책) 정합성:
- 저장 경로 `docs/_meta/conductor-ops/` PASS (R3 허용 경로)
- frontmatter `tier: meta` + `confluence-sync: false` PASS

15세 응답 스타일 룰 정합성:
- 본 문서는 내부 운영 spec → 기술 용어 허용. 단, 다이어그램 우선 원칙 적용 (ASCII 사용)
- 비유 (책의 색인 / 책의 ISBN 등) 본 문서에 직접 사용은 부적합 (운영자 문서). 사용자 보고 시점에 변환

---

## 7. 다른 stream SCOPE 침범 검증 (S10-W 워크트리 안전성)

본 v2 문서는 다음을 보장한다:

| 위반 가능 경로 | v2 처분 | 확인 |
|---------------|---------|------|
| tools/doc_discovery.py 수정 | 제안만, 실제 구현은 S8/S11 위임 | PASS |
| tools/doc_rag.py 수정 | 수정 없음 | PASS |
| GitHub Actions 추가 | 제안만, 실제 구현 s11 위임 | PASS |
| 다른 stream 의 topic-wiki 작성 | 각 stream 이 자기 wiki 만 작성하도록 명시 | PASS |
| S10-W scope_owns 외 docs 수정 | 본 문서만 작성, 다른 docs 수정 없음 | PASS |

본 문서 자체의 저장 경로 `docs/_meta/conductor-ops/karpathy-idea-ebs-application_2026-05-14_v2.md` 는 R3 정책상 conductor 메타 영역으로 S10-W 가 작성 가능한 제안 산출물. 다른 stream 의 scope_owns 침범 없음.

---

## 8. 구현 우선순위 (P1 ~ P3)

| 우선순위 | 항목 | 담당 | 의존성 |
|---------|------|------|--------|
| P1 | _schema.md 작성 (9 topic-wiki 표준 선언) | smem | 없음 |
| P1 | 본 v2 문서 PR merge | s10-W (현재 작업) | 없음 |
| P2 | 9 stream 각자 topic-wiki 초기 작성 (병렬) | s2/s3/s7/s8/s9/s10-A/s11 | P1 _schema |
| P2 | Index.md 자동 빌드 + Log.md 초기화 | smem | P2 topic-wiki 9 개 |
| P2 | log-md-append.yml GitHub Action | s11 | P2 Log.md |
| P3 | wiki-candidate-review.yml + doc_critic 연동 | s11 + doc_critic agent | P2 |
| P3 | tools/doc_wiki_lint.py 작성 | s11 | P2 |
| P3 | weekly_diff 와 Log.md 연동 | smem | P2 |
| P3 | CLAUDE.md (각 worktree) wiki 우선 조회 1줄 추가 | conductor | P2 |

병렬 가능성: P2 의 9 stream topic-wiki 초기 작성은 완전 독립 → Wave 병렬 dispatch 가능 (Cycle 16 Wave 1+2 패턴).

---

## 9. 위험 + 완화 (통합)

| 위험 | 심각도 | 완화 |
|------|:------:|------|
| 9 stream 분산 갱신의 정합성 불균일 | 중 | Index.md 자동 빌드가 누락 stream 표시. Log.md 가 stream 별 갱신 빈도 추적 |
| Log.md 파일 비대화 | 저 | 월 단위 rotate (`Log_2026-05.md`) + 직전 1 개월만 활성 |
| PR Draft 장기 stale | 저 | 30 일 자동 close + 알림 |
| topic-wiki 간 cross-link 누락 | 중 | smem 의 lint loop 가 graph 무결성 확인 |
| typed-edge graph contradict cycle | 중 | Lint 가 contradict event 발생 시 사용자 진입점 1 회 (정상 운영 안에 들어맞음) |
| 9-카테고리 SSOT 변경 시 wiki 재구조 비용 | 저 | _schema.md 만 갱신, 각 stream wiki 는 supersede 패턴으로 점진 마이그레이션 |
| smem 단일 의존성 (Index/Log) | 저 | smem 가 down 이어도 stream 별 wiki 는 독립 운영. Index/Log 만 일시 stale |

---

## 10. 기존 자산 활용 (v1 보다 정교)

| 기존 자산 | 활용 방식 | 수정 여부 |
|-----------|----------|-----------|
| tools/doc_discovery.py | wiki miss 시 Layer 1 fallback (기존 그대로) | 0 |
| tools/doc_rag.py | wiki miss 시 Layer 2 fallback (기존 그대로) | 0 |
| docs/_generated/full-index.md | 자동 빌드 source, Index.md 는 별도 wiki 인덱스 | 0 |
| MEMORY.md case_studies/ | Wisdom tier 대응. wiki Index 에 링크만 | 0 |
| MEMORY.md weekly_diff | Log.md 의 주간 요약 출력으로 자동화 | 확장 |
| 기존 frontmatter (derivative-of 등) | typed-edge 의 초기 종류 (supersede/contradict 등 추가 필요) | 확장 |
| GitHub PR Draft | candidates staging 의 자연스러운 구현체 | 0 |
| doc_critic agent | PR Draft 자동 검토 (이미 작동 중) | 0 |
| Cycle 16 9-카테고리 SSOT v1.0.0 | 9 topic-wiki 의 정의 source | 0 |

수정 0 자산: 7 개. 확장만 필요: 2 개. 신규 작성: _schema.md, 9 topic-wiki, Log.md, Index.md, 2 GitHub Actions, doc_wiki_lint.py.

---

## 11. 사용자 보고 요약 (15세 응답 스타일 룰 적용)

> 본 섹션만 사용자 진입점용. 운영자 영역은 위 1-10 절.

### 무엇이 문제인가

매번 작업할 때마다 docs/ 폴더 안 640 개 문서를 처음부터 다시 훑어보는 비효율이 있다. 마치 도서관에서 책을 찾을 때마다 매번 전체 책장을 처음부터 다시 보는 것과 같다.

### 무엇을 제안하는가

1. **각 팀이 자기 영역의 요약 카드 1 장씩 만든다** (총 9 장).
   - 작업할 때 자기 카드 1 장만 보면 충분.
   - 640 개 문서 전체 훑기 불필요.
2. **모든 팀의 변경사항을 한 곳에 시간순으로 기록한다** (Log.md).
   - 어제 무슨 일이 있었는지 30 줄만 읽으면 파악 가능.
3. **새 카드를 만들 때 GitHub PR Draft 로 먼저 준비**.
   - 비평가 (doc_critic) 가 자동 검토 후 통과하면 사용자가 ready 클릭 1 회.
   - 사용자가 결정할 것은 ready 클릭 1 회만.

### 결과 (예상)

- 토큰 소비: 약 87-92% 절감
- 사용자 결정 횟수: 작업당 1 회 미만 (PR ready 클릭만)
- 9 팀 병렬 갱신 → bottleneck 없음

---

## 12. 다음 단계 권고

1. **본 v2 문서 PR merge** (S10-W, 현재 작업)
   - title: `docs(meta): Karpathy wiki v2 분산 멀티스트림 모델 제안`

2. **smem 에 _schema.md 작성 위임**
   - 9 topic-wiki frontmatter 표준 + 갱신 조건 + Cross-link 규칙
   - 다음 cycle 의 smem cycle 작업으로 dispatch

3. **9 stream P2 병렬 dispatch 계획** (다음 cycle 또는 그 다음)
   - 각 stream 이 자기 topic-wiki 초기 작성 (Wave 병렬 가능)
   - Cycle 16 Wave 1+2 패턴 재활용

4. **사용자 결정 항목** (필요 시 1 회)
   - 본 v2 모델로 진행할지 (또는 v1 단일 모델 유지)
   - 본 작성자 추천: v2 분산 모델 (멀티세션 격리 원칙 정합 + 9-카테고리 SSOT 활용)

---

## 13. 변경 이력

| 날짜 | 버전 | 내용 |
|------|------|------|
| 2026-05-14 | v1.0 | 최초 작성. Karpathy gist fetch + EBS 현황 분석 + 3 제안 (`karpathy-idea-ebs-application_2026-05-14.md`) |
| 2026-05-14 | v2.0 | 본 문서. WebFetch 재추출 신규 컨셉 5 개 추가, 멀티스트림 분산 wiki 로 재설계, 9-카테고리 SSOT(Cycle 16) 와 결합, Log.md 이중 구조 + Candidates staging 신규 제안 추가 |

---

## 14. 참조

- v1 문서: `docs/_meta/conductor-ops/karpathy-idea-ebs-application_2026-05-14.md`
- Karpathy gist 원문: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
- EBS Core Philosophy: `~/.claude/CLAUDE.md` (Core Philosophy 섹션)
- R3 메타 경로 정책: `C:/claude/ebs/CLAUDE.md` (R3 섹션)
- 9-카테고리 SSOT v1.0.0: PR #393 (Cycle 16, 2026-05-13)
- Cycle 16 사례: `~/.claude/projects/C--claude-ebs/memory/case_studies/2026-05-13_cycle16_overlay_9_categories.md`
- 멀티세션 설계: `docs/orchestrator/Multi_Session_Design.md` (현재 `_archive/conductor-meta-2026-05-14/`)
- 기존 도구: `tools/doc_discovery.py` (294 줄), `tools/doc_rag.py` (327 줄)
- 정적 인덱스: `docs/_generated/full-index.md` (767 줄)
