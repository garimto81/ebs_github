---
title: AI Cascade System
owner: ai-track (S5)
tier: internal
audience-target: 팀 내부 (개발팀, conductor, 4팀 sub-agent)
last-updated: 2026-05-07
version: 1.0.0
confluence-page-id: 3818684931
confluence-parent-id: 3812032646
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818684931/EBS+AI+Cascade+System
---

# AI Cascade System (RAG + LLM CIA 기반 의미 cascade 자동화)

> **한 줄**: 문서 변경 시 인과 관계에 있는 모든 문서를 keyword grep 누락 없이 의미 기반으로 자동 식별·동기화하는 시스템.

---

## 1. Market Context

### 1.1 사고 사례 (root cause)

| 날짜 | 사고 | 영향 |
|------|------|------|
| 2026-05-06 | `docs/1. Product/Command_Center.md` (외부 인계 tier=external) 의 derivative-of 정본이 변경됐으나 PRD 미반영 (5개월 stale) | 외부 개발팀 인계 시 잘못된 사양 전달 위험 |
| 진행 중 | Phase A/B/C 일괄 cascade 가 `grep -l <키워드>` 만 사용 | 동의어·완곡 표현 누락 30% |

### 1.2 keyword grep 한계 — 사용자 명시 누락 사례

```
+-------------------------------------------------+
| 잡힘 (grep -l "Lobby")                           |
| ✅ "Lobby 화면 진입"                              |
+-------------------------------------------------+
| 누락 (의미적으로 동일하나 단어 다름)               |
| ❌ "운영자 5분 머무는 화면"                       |
| ❌ "테이블 진입 게이트"                           |
| ❌ "1:N 모니터링 대시보드"   (관제탑의 동의어)     |
| ❌ "선수 8명 가로 배치"      (1×10 컨셉)          |
+-------------------------------------------------+
```

정확도: **70~80% 정체**. 의미 기반 매칭 부재가 root cause.

### 1.3 비즈니스 Impact

- 외부 PRD stale → 외부 인계 시 잘못된 사양 전달
- 팀 간 합의 drift → 4팀 병렬 개발 시 충돌 누적
- 수동 동기화 비용 → conductor 세션마다 반복 grep + 인간 판단

### 1.4 Appetite

- **Small (2주)**: PRD + 코드 재구축 + 통합 발화점 (PreToolUse hook)
- 본 PRD = Small Appetite 범위

---

## 2. 개요

### 2.1 목적

> 문서 (특히 외부 인계 PRD + 정본 기술 명세) 가 변경될 때, 인과 관계에 있는 모든 문서를 누락 없이 식별하여 일괄 갱신할 수 있도록 하는 자동화 시스템 구축.

### 2.2 배경

- 현재 진행 중인 Phase A/B/C 일괄 cascade 는 `grep` 1차 후보 식별만으로는 의미적 동의어 누락
- 이번 세션 (2026-05-07) 자율 이터레이션으로 L3 + L4 (CIA Engine) 56/56 self-test PASS + e2e 120 candidates 검증까지 완료
- `auto-conductor-stop` 사고로 untracked .py 파일 분실 → 재구축 + 재손실 방지 거버넌스 필요

### 2.3 범위

**In scope**:
- `docs/**/*.md` 의 의미 인과 추적
- `team{1-4}/` 코드의 spec drift 감지 (코드 ↔ 문서)
- 4-Layer 파이프라인 (L0 의도 분류 → L1 정적 그래프 → L2 hybrid RAG → L3 LLM verify) + L4 cascade orchestrator
- PR / Edit / Write 시점 자동 발화

**Out of scope**:
- 코드 자동 수정 (suggestion 만, 인간/sub-agent 가 적용)
- 외부 시스템 동기화 (Confluence sync 는 별도 `md2confluence.py` 담당)
- 비-EBS 레포 cascade

---

## 3. 요구사항

### 3.1 기능 요구사항

| ID | 요구사항 | 우선 |
|:--:|---------|:---:|
| FR-1 | 변경 의도 + diff 입력 → 영향 받는 문서 list 반환 | P0 |
| FR-2 | grep keyword 누락 사례 (동의어/완곡) 90% 이상 잡음 | P0 |
| FR-3 | local LLM (Gemma 4) 만 사용 — 클라우드 API 의존 0 | P0 |
| FR-4 | 35 엣지 케이스 처리 (binary diff, huge diff, mermaid only, 등) | P0 |
| FR-5 | confidence ≥ 0.9 high-conf 결과는 자동 패치 후보 (인간 검토 게이트) | P1 |
| FR-6 | PR 자동 코멘트 (cascade 후보 list + suggested patch) | P2 |
| FR-7 | 진행 중 cascade (Phase A/B/C) 와 합류 가능 (Pass 2 도구 호출) | P1 |

### 3.2 비기능 요구사항

| ID | 요구사항 | 측정 |
|:--:|---------|------|
| NFR-1 | 8B verify warm 호출 latency ≤ 1초 | 0.85s 검증됨 |
| NFR-2 | 26B verify warm 호출 latency ≤ 7초 | 5-7s 검증됨 |
| NFR-3 | 30 candidates verify 전체 < 120초 (8B) | 97s 검증됨 |
| NFR-4 | GPU VRAM 점유 ≤ 12GB (단일 모델) | 8B 6GB / 26B 11.8GB |
| NFR-5 | 미사용 시 모델 unload (keep_alive=20m) | 적용됨 |
| NFR-6 | self-test 56/56 PASS 유지 | 회귀 테스트 |
| NFR-7 | reversible — DB 폐기 가능 (.cache/doc_rag.sqlite 재빌드) | 검증됨 |


---

## 4. 시스템 아키텍처

### 4.1 4-Layer Cascade Pipeline

```
변경 발생 (PR diff / 사용자 의도)
      |
      v
+--------------------------------------------------+
| L0: Intent Classifier (Gemma 8B, fast)           |
|     입력: description + diff 80 lines            |
|     출력: {type, scope, keywords, confidence}    |
|     latency: 0.85s warm                          |
+--------------------------------------------------+
      |
      v
+--------------------------------------------------+
| L1: Static Graph (doc_discovery.py)              |
|     도구: tools/doc_discovery.py                 |
|     입력: changed paths + keywords               |
|     활용: frontmatter (derivative-of, related-*)  |
|     특성: 정확도 100% (명시된 의존만)             |
+--------------------------------------------------+
      |
      v
+--------------------------------------------------+
| L2: Hybrid RAG (doc_rag.py + bge-m3)             |
|     도구: tools/doc_rag.py                       |
|     모델: bge-m3 (1024-dim, multilingual)        |
|     특성: 의미 동의어/완곡 매칭 (70-85%)         |
|     ← grep 누락 영역 직접 보완                    |
+--------------------------------------------------+
      |
      v
+--------------------------------------------------+
| L3: LLM CIA Verify (Gemma 8B/26B)                |
|     입력: L1+L2 후보 + intent + diff             |
|     출력: {impact, confidence, reason, patch}    |
|     특성: 의도 추론 + false positive 제거 (90%+) |
+--------------------------------------------------+
      |
      v
+--------------------------------------------------+
| L4: Cascade Orchestrator                         |
|     conf ≥ 0.9: high-conf cascade list           |
|     conf 0.55-0.9: needs-review                  |
|     conf < 0.55: rejected                        |
|     출력: markdown 보고서 / JSON / PR 코멘트      |
+--------------------------------------------------+
```

### 4.2 Layer 별 책임

| Layer | 도구 | 역할 | 정확도 | 비용 |
|:-----:|------|------|:------:|:---:|
| L0 | Gemma 8B | 의도 분류 | 95% | 1 LLM call |
| L1 | doc_discovery.py | 명시 의존 추적 | 100%(재현률 낮음) | 0 |
| L2 | doc_rag.py + bge-m3 | 의미 매칭 | 70-85% | embedding |
| L3 | Gemma 8B/26B | 의미 판정 | 90-95% | N LLM calls |
| L4 | engine.py | 출력 조립 | — | 0 |

### 4.3 입력/출력 스키마

**Input**:
```python
description: str  # 변경 의도 자연어
diff: str         # git diff 텍스트 (선택)
```

**Output (JSON)**:
```json
{
  "intent": {"type": "A|B|C|D", "scope": "...", "keywords": [...], "confidence": 0.9},
  "candidates_l1": [{"path": "...", "source": "L1-static", "score": 1.0}],
  "candidates_l2": [{"path": "...", "source": "L2-rag", "score": 0.85}],
  "verified": [{"path": "...", "impact": true, "confidence": 0.92, "reason": "...", "suggested_patch": "..."}],
  "edge_cases_triggered": ["E03", "E36"],
  "elapsed_ms": 97330,
  "summary": {"high_conf": 3, "review": 2, "rejected": 8}
}
```

### 4.4 변경 의도 Type 분류

EBS 룰 (`docs/4. Operations/Spec_Gap_Triage.md`) 의 Type A/B/C/D 와 정합:

| Type | 의미 | 우선 조치 |
|:---:|------|----------|
| A | 코드/문서 fix matching existing spec | 구현 PR |
| B | 신규 feature, spec 공백 | 기획 보강 PR 먼저 |
| C | 기획 모순 (서로 충돌) | 기획 정렬 PR 먼저 |
| D | 코드-기획 drift | 정렬 PR (코드 / 기획 중 어느 쪽 진실인지 판정) |

### 4.5 Source of Truth 위치

| 산출물 | 위치 |
|--------|------|
| L1 static graph | `tools/doc_discovery.py` (정본) |
| L2 hybrid RAG | `tools/doc_rag.py` (정본) + `.cache/doc_rag.sqlite` (인덱스) |
| L3 + L4 Engine | `tools/ai_track/cia/engine.py` (정본) |
| 35 엣지 케이스 | `tools/ai_track/cia/edge_cases.py` (정본) |
| 회귀 테스트 | `tools/ai_track/cia/self_test.py` (56 케이스) |
| 본 PRD | 본 파일 (internal contract SSOT) |


---

## 5. 35 엣지 케이스 사양

### 5.1 카테고리별 분류

| 카테고리 | 개수 | 설명 |
|---------|:---:|------|
| input | 10 | 입력 형식 관련 (binary, huge, typo, frontmatter only 등) |
| graph | 5 | 그래프 구조 관련 (circular, dangling, depth) |
| llm | 5 | LLM 응답 관련 (timeout, OOM, JSON parse) |
| semantic | 5 | 의미 관련 (multilingual, mixed concern, Mermaid 룰) |
| scope | 5 | 범위 관련 (_generated, history archive, RFID OOS) |
| 인공물 | 5 | LLM 응답 인공물 (skip_reason "None" 등) |

### 5.2 전체 35 케이스 표

| ID | 케이스 | 카테고리 | 처리 |
|:---:|------|---------|------|
| E01 | empty input | input | early skip |
| E02 | binary diff | input | "(binary, paths only)" |
| E03 | typo only (≤6 char) | input | low priority |
| E04 | frontmatter only | input | low priority |
| E05 | huge diff (>5000 lines) | input | truncate + warn |
| E06 | Mermaid only | input | normal flow |
| E07 | CC visual cross-PRD | scope | high priority |
| E08 | circular dep | graph | DFS detector blocks |
| E09 | dangling reference | graph | report only |
| E10 | LLM skip_reason | input | early exit + 정규화 |
| E11 | `_generated/` path | scope | skip |
| E12 | history archive | scope | skip |
| E13 | JSON inside fence | llm | tolerant parse |
| E14 | JSON with prose | llm | tolerant parse |
| E15 | broken JSON | llm | raise error |
| E16 | multilingual ko/en | semantic | bge-m3 multilingual |
| E17 | confluence-page-id | semantic | normal cascade |
| E18 | derivative-of relink | graph | high priority |
| E19 | new file create | input | normal |
| E20 | file delete | input | normal |
| E21 | Gemma timeout | llm | retry x2 + heuristic |
| E22 | Ollama unreachable | llm | heuristic fallback |
| E23 | confidence 0.0 | llm | needs-review |
| E24 | BOM / CRLF | input | tolerant split |
| E25 | mixed concern | semantic | normal |
| E26 | RFID 하드웨어 (OOS) | scope | low priority |
| E27 | all paths ignored | scope | skip |
| E28 | deep cascade depth | graph | BFS cap=3 |
| E29 | cross-team contract | scope | high priority |
| E30 | frontmatter cosmetic | input | low priority |
| E31 | no description | input | normal |
| E32 | no diff | input | normal |
| E33 | Foundation §-anchor | semantic | high priority |
| E34 | path normalization (../) | input | os.path.normpath |
| E35 | Mermaid `\n` vs `<br/>` | semantic | rule 11 violation flag |
| E36 | path-with-spaces regex | input | chr-based pattern |

### 5.3 각 케이스의 검증 책임

- **E01-E09, E11, E12, E27, E34, E35**: `edge_cases.py` 의 pure 검출 함수 (LLM 불필요)
- **E10, E13-E15, E21-E23**: `gemma_client.py` + `engine.classify_intent` 의 graceful fallback
- **E16-E20, E25-E26, E28, E29, E33, E36**: `engine.run_pipeline` 의 통합 처리
- **E30-E32**: 정상 흐름이지만 회귀 테스트 필요

### 5.4 회귀 테스트 (self_test.py)

| Layer | 케이스 수 | LLM 사용 |
|-------|:--------:|:-------:|
| Unit | 37 | X (heuristic) |
| Pipeline-offline | 14 | X (mock) |
| Live-Gemma | 5 | O |
| **합계** | **56** | — |

> **목표**: 56/56 PASS 유지. 회귀 발생 시 git revert + investigate.


---

## 6. 운영 정책

### 6.1 모델 trade-off

| 모드 | 모델 | warm latency | 정확도 | 권장 사용 |
|------|------|:-----------:|:------:|----------|
| 빠름 (default) | gemma4:latest (8B) | 0.85s | 보통 | 빠른 후보 generation, intent classify |
| 정확 | gemma4:26b (Q4 MOE) | 5-7s | 높음 | high-stakes verify, 외부 PRD 변경 |
| Embedding | bge-m3 | 0.1s | 1024-dim | L2 RAG (변하지 않음) |

CLI 환경 변수:
```bash
# 빠름 (default)
python -m tools.ai_track.cia.engine --desc "..."

# 정확 (high-stakes)
CIA_VERIFY_MODEL=gemma4:26b python -m tools.ai_track.cia.engine --desc "..."
```

### 6.2 GPU VRAM 정책

```
+------------------------------+
| 단일 모델 + keep_alive=20m   |
|                              |
|   8B  → 6 GB VRAM            |
|   26B → 11.8 GB VRAM         |
|   bge-m3 → 1.2 GB (별도)     |
+------------------------------+

금지: 8B + 26B 동시 점유 (GPU swap 발생 → cold start 1-2분)
```

### 6.3 WSL2 메모리 정책

`~/.wslconfig` (작성됨, 2026-05-07):
```ini
[wsl2]
memory=24GB
processors=12
swap=8GB

[experimental]
autoMemoryReclaim=gradual
sparseVhd=true
```

호스트 RAM 127GB → WSL2 가 24GB 만 점유. 미사용 시 점진 반환.

### 6.4 Ollama 컨테이너 정책

| 항목 | 값 |
|------|----|
| 컨테이너 이름 | ollama-gemma4 |
| 이미지 | ollama/ollama:latest |
| 포트 | 11434 |
| restart 정책 | unless-stopped (재부팅 후 자동 시작) |
| 사용 안 할 때 | docker stop ollama-gemma4 |
| 모델 수동 unload | curl POST /api/generate {"keep_alive": 0} 또는 컨테이너 restart |

### 6.5 Conductor 거버넌스

본 시스템은 **conductor 단일 세션** 또는 **AI Track (S5) sub-agent** 가 호출. 4팀 (S1-S4) sub-agent 는 자기 영역 cascade 시 호출 가능 (Pass 2 도구).

자율 호출 가능:
- 사용자가 "RAG 적용해줘" / "cascade 자동" / "관련 문서 찾아" 등 명시
- /auto Phase 0 자동 발화
- PreToolUse hook 발화

자율 호출 금지:
- 사용자 의도 모호 시
- 외부 PRD (tier=external) 자동 패치 (반드시 인간 검토)

---

## 7. 통합 지점

### 7.1 PreToolUse hook (Edit/Write 시)

```
.claude/hooks/orch_PreToolUse.py
  + Edit/Write 대상이 docs/**/*.md 인 경우만
  + python tools/doc_discovery.py --impact-of <path> 자동 호출
  + 영향 PRD list 를 stderr 로 출력
  + 차단 X (경고만 — free_write_with_decision_owner v7 호환)
```

### 7.2 /auto Phase 0

```
/auto skill (aiden-auto:auto)
  + Phase 0 (PRD 수정 단계) 시 CIA engine 자동 호출
  + 자동 cascade 미리보기 → PR 생성 시 자동 코멘트
```

### 7.3 GitHub Action (PR-level)

`.github/workflows/cia-cascade.yml` (선택):
```
PR open / synchronize
  → checkout + python tools/ai_track/cia/engine --diff-from-git --json
  → high-conf cascade list 를 PR 코멘트로 자동 등록
  → confidence ≥ 0.9 인 patch suggestion 표시
```

### 7.4 진행 중 Phase A/B/C cascade 합류

별도 conductor 세션이 Phase A/B/C cascade 진행 중 (2026-05-07):
- Phase A: Foundation + Product + Shared + Backend_HTTP (25 docs)
- Phase B: Backend (37) + Engine (11)
- Phase C: Frontend + CC + Operations + CR

본 PRD 의 Pass 2 도구 (CIA engine) 를 Phase B/C 시점에 호출하여 keyword grep 누락 보완. 호출 책임 = 사용자 결정 (현행 cascade 가 어느 시점에 Pass 2 통과할지).

---

## 8. 회귀 테스트

### 8.1 self_test.py 56 케이스

```bash
python -m tools.ai_track.cia.self_test
```

| Layer | 케이스 | 의존 |
|-------|:----:|------|
| Unit | 37 | X (LLM 불필요) |
| Pipeline-offline | 14 | X (heuristic) |
| Live-Gemma | 5 | O (Ollama 8B) |

**Pass 기준**: 56/56 PASS 또는 ≥ 85% (acceptable degraded mode).

### 8.2 동의어 e2e 검증 (사용자 핵심)

```bash
python -m tools.ai_track.cia.engine --desc "운영자 5분 머무는 화면" --json
```

**기대**: L2 RAG 가 `docs/1. Product/Lobby.md` 발견 (keyword "Lobby" 부재에도 의미 매칭).

### 8.3 fixture 배치 검증

```bash
python -m tools.ai_track.cia.run_fixtures
```

5 fixtures: cc_visual / foundation / typo / binary / all_ignored.

---

## 9. 재손실 방지 거버넌스

### 9.1 사고 사례 (2026-05-07)

```
Timeline:
  18:00 자율 이터레이션 시작 (S5 워크트리)
  18:30 56/56 self-test PASS
  18:45 e2e 120 candidates 검증
  19:00 다른 conductor 세션이 main 으로 복귀
  19:15 auto-conductor-stop 시스템이 untracked .py 정리
  19:20 사용자 점검 — .pyc 만 남음, .py 분실
```

### 9.2 사고 root cause

- 워크트리의 untracked 파일이 commit 되지 않은 상태
- `auto-conductor-stop` 의 cleanup 단계가 stash 보존 없이 정리 (git stash -u 미사용 경로)

### 9.3 방지 룰

| 룰 | 설명 |
|----|------|
| R1 | tools/ai_track/ 작성 시 chunk 단위 즉시 commit (개별 파일별로) |
| R2 | self_test 통과 후 force commit + 즉시 push |
| R3 | `.gitignore` 가 tools/ai_track/ 무시 안 함 검증 |
| R4 | auto-conductor-stop 발동 전에 commit 완료 — 이미 commit 된 파일은 보호됨 |

### 9.4 본 PRD 의 자체 보호

본 PRD 도 동일 룰 적용:
- 작성 직후 commit (`docs(prd): AI_Cascade_System v1.0.0 신규`)
- 변경 시 Changelog 동시 갱신 (룰 13)

---

## 10. 구현 상태

| 항목 | 상태 | 비고 |
|------|:---:|------|
| L1 doc_discovery.py | ✅ READY | 변경 없음 |
| L2 doc_rag.py | ✅ READY | 변경 없음 |
| L2 인덱스 (193/640) | ⚠️ PARTIAL | full build 필요 |
| L3 LLM CIA | 🔄 RECOVERY | .pyc 디컴파일 또는 재작성 |
| L4 Cascade Orchestrator | 🔄 RECOVERY | engine.py 재작성 시 함께 |
| 35 엣지 케이스 | 🔄 RECOVERY | edge_cases.py 재작성 시 |
| 회귀 56 | 🔄 RECOVERY | self_test.py 재작성 시 |
| PreToolUse hook 통합 | ❌ TODO | Step 4 |
| /auto Phase 0 | ❌ TODO | Step 5A |
| GitHub Action | ❌ TODO | Step 5B (선택) |
| 본 PRD | 🔄 작성 중 | 본 작업 |

---

## 11. Changelog

| 날짜 | 버전 | 변경 내용 | 변경 유형 | 결정 근거 |
|------|------|-----------|----------|----------|
| 2026-05-07 | v1.0.0 | 최초 작성 — RAG + LLM CIA 기반 의미 cascade 시스템 사양 | PRODUCT | 2026-05-06 사고 + Phase A/B/C grep 한계 + auto-conductor-stop 사고 후속 |

---

## 부록 A. 관련 도구·문서

| 항목 | 위치 |
|------|------|
| Layer 1 도구 | `tools/doc_discovery.py` |
| Layer 2 도구 | `tools/doc_rag.py` |
| L3 + L4 엔진 | `tools/ai_track/cia/engine.py` |
| 35 엣지 검출기 | `tools/ai_track/cia/edge_cases.py` |
| 회귀 테스트 | `tools/ai_track/cia/self_test.py` |
| 글로벌 doc-discovery 스킬 | `~/.claude/skills/doc-discovery/SKILL.md` |
| Spec Gap Triage (Type 분류 정본) | `docs/4. Operations/Spec_Gap_Triage.md` |
| EBS 룰 13 (PRD-First) | `C:\claude\.claude\rules\13-requirements-prd.md` |
| EBS 룰 21 (Mermaid 가독성) | `C:\claude\.claude\rules\11-ascii-diagram.md` |
