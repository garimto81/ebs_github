---
title: SMEM Weekly Memory Audit — 2026-05-11
owner: SMEM
stream: SMEM
type: audit
period: 2026-05-04 → 2026-05-11
audited_target: ~/.claude/projects/C--claude-ebs/memory/
issue: "#228"
related_pr: "#229"
init_pr: "#214"
broker_state: alive (pid 53412, port 7383)
---

# SMEM Weekly Memory Audit — 2026-05-11

> **Stream**: SMEM (Conductor Memory Stream, optional, cross-cutting)
> **KPI 목표**: Weekly MEMORY.md append-only diff report
> **감사 대상**: 사용자 자동 메모리 `~/.claude/projects/C--claude-ebs/memory/`

## 1. Executive Summary

| 항목 | 상태 | 비고 |
|------|:----:|------|
| append-only discipline | ✅ PASS | 신규 4 파일 모두 추가 only, 기존 메모리 재작성/삭제 없음 |
| MEMORY.md 인덱스 동기화 | ✅ PASS | orphan 파일 0건, 신규 2026-05-11 항목 정상 등재 |
| MEMORY.md 200줄 한계 | ⚠️  **VIOLATION** | 현재 250줄 — 시스템 truncation 발생 |
| frontmatter 표준 | ✅ PASS | 신규 파일 (`project_cleanup_2026_05_11`, `project_ebs_v4_separate`) name/description/type 완비 |
| broker liveness | ✅ PASS | pid=53412 LISTEN @ 127.0.0.1:7383 |

**핵심 조치 권고**: MEMORY.md 50줄 축소 (인덱스 항목 압축 또는 sub-index 분할).

## 2. Period Snapshot

```
+-----------------------------------------------------+
| 감사 기간   : 2026-05-04 19:47  → 2026-05-11 15:34  |
| 총 메모리   : 63 파일 (.md)                          |
| 신규/변경   : 4 파일                                 |
| 삭제        : 0 (append-only 준수)                   |
| MEMORY.md   : 250 줄 (한계 200 줄, +50 over)        |
+-----------------------------------------------------+
```

## 3. Append-only Diff (변경 파일 4건)

| mtime (KST) | 파일 | 분류 | 인덱스 등재 |
|-------------|------|------|:----------:|
| 2026-05-11 15:34 | `project_cleanup_2026_05_11.md` | 신규 (project) | ✅ L221 |
| 2026-05-11 15:34 | `MEMORY.md` | 인덱스 갱신 | — |
| 2026-05-11 15:22 | `project_ebs_v4_separate.md` | 신규 (project) | ✅ L220 |
| 2026-05-04 19:47 | `project_docs_structure_misalignment_2026_05_04.md` | 신규 (기간 경계) | ✅ |

### 3.1 신규 메모리 요약

**`project_cleanup_2026_05_11`** — 4 옛 디렉토리 정리 + zip backup (`_archive/cleanup-2026-05-11/` 481MB). ebs-wt-team1-round2 / ebs_ecosystem / ebs_lobby / ebs_v3. 검증: broker pid=53412, monitor 13 stream 인식.

**`project_ebs_v4_separate`** — `C:/claude/ebs_v4` = 별개 프로젝트 사용자 명시. `ebs*` glob 정리 시 영구 제외.

## 4. Discipline 검사

### 4.1 append-only 준수 (PASS)

```
검증 방법: 기간 내 mtime 신규 파일만 존재, 기존 파일 mtime 변경 0건.
   ls -la --time-style=long-iso *.md | awk '$1 >= "2026-05-04"'
   → 4건 (3 신규 + MEMORY.md 인덱스만 갱신)
   기존 파일 본문 재작성 흔적 없음.
```

### 4.2 orphan 파일 검사 (PASS)

```
for f in *.md; do
  basename=$(basename "$f" .md)
  grep -q "$basename" MEMORY.md || echo "ORPHAN: $f"
done
→ total_orphans: 0
```

### 4.3 frontmatter 표준 (PASS)

```yaml
# project_cleanup_2026_05_11.md
name: 구 EBS 멀티세션 폴더 정리 완료 (2026-05-11)
description: 9-session matrix v10.4 후속 — 4 옛 디렉토리 archive + 제거.
type: project
originSessionId: 70da27dd-9850-45d9-b062-60812e084dbd  # NEW field

# project_ebs_v4_separate.md
name: ebs_v4 = 별개 프로젝트
description: C:/claude/ebs_v4 는 EBS 프로젝트(C:/claude/ebs) 와 완전 무관한 별개 프로젝트.
type: project
originSessionId: 70da27dd-9850-45d9-b062-60812e084dbd  # NEW field
```

**관찰**: `originSessionId` 필드는 표준 frontmatter (name/description/type) 외 신규 확장. 추적성 향상 목적으로 보이며 위반 아님. 향후 표준화 검토 권고.

## 5. ⚠️ Open Issue — MEMORY.md 250줄 한계 초과

### 5.1 증거

시스템 컨텍스트 로딩 메시지:
```
> WARNING: MEMORY.md is 250 lines (limit: 200).
> Only part of it was loaded. Keep index entries to one line under ~200 chars;
> move detail into topic files.
```

`wc -l MEMORY.md` → **250** (한계 +50, 25% 초과).

### 5.2 영향 (Why this matters)

- 251줄 이후 콘텐츠는 미래 세션에서 **자동 로드 누락**
- "사례 학습 인덱스 / 토픽별 메모리 인덱스" 후반부 (시각화 & 품질 섹션) 가 잘림
- 미래 세션이 LEGACY 섹션은 보지만 신규 사례 학습 인덱스를 못 보는 역설 발생 가능

### 5.3 권고 조치 (How to apply)

| 우선순위 | 조치 | 예상 효과 |
|:--------:|------|----------|
| P1 | "프로젝트 핵심 이해" 하위 맥락 (L29~L88) → 별도 `project_core_context.md` 분리 | -60 줄 |
| P2 | "실수 기록" L186~L201 (16건) → `feedback_lessons_index.md` 외부화 | -16 줄 |
| P3 | "토픽별 메모리 인덱스" 줄당 압축 (현재 평균 220자, 150자 한계) | -10 줄 |

총 약 86줄 감축 가능 → 목표 ≤ 200 줄.

> **주의**: SMEM 의 audit-only 원칙상 본 보고서는 **권고**까지만. 실제 MEMORY.md 편집은 사용자 또는 다른 stream 권한 (SMEM `meta_files_blocked` 에 MEMORY.md 포함, 단 user-global memory 는 별개 권한 영역).

## 6. Broker Activity (v10.4 Message Bus 통합)

```
broker        : http://127.0.0.1:7383/mcp  (FastMCP StreamableHTTP)
pid           : 53412 (LISTENING)
last_seq      : 3 (project_cleanup memo 기록 기준 pipeline:cleanup-complete)
publish 권한  : audit:memory-snapshot, audit:memory-rotate (SMEM)
subscribe     : *  (전체 감사)
```

본 audit 사이클에서 SMEM publish 시도 없음 (audit-only KPI 산출이 목적, snapshot/rotate 트리거 조건 미발생).

## 7. Next Cycle

- **다음 audit**: 2026-05-18 (주간 cadence)
- **모니터링 항목**:
  - MEMORY.md 줄 수 추세 (250 → ?)
  - 신규 case_studies 등재 비율
  - `originSessionId` 필드 표준화 여부

---

🤖 SMEM weekly KPI 산출 — append-only diff snapshot
관련: Issue #228, Init PR #214
