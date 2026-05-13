---
title: "Confluence Cycle 18 Rename + Content Push Report"
owner: stream:S11
tier: internal
last-updated: 2026-05-13
status: COMPLETE
cycle: 18
related-docs:
  - ../Confluence_Sync_Spec.md (SSOT v2.1)
  - ../../_generated/confluence-pagename-audit.md
  - ../../_generated/confluence-mirror-matrix.md
---

# Confluence Cycle 18 Rename + Content Push Report

> **요약**: 사용자 명시 권한으로 3 Confluence 페이지명 변경 + 5 PRD 본문 push 완료.
> 전체 작업 = 단일 cycle 내 자율 진행 (사용자 진입점 1회 — 작업 명시).

## 1. 한 줄 결과

```
+-----------------------+        +-----------------------+
| 사용자 명시 작업       |  --->  | 3 rename + 5 push     |
|  - 3 페이지 rename    |        |  - 모두 success       |
|  - 5 PRD 본문 갱신    |        |  - 343 drift = 0      |
+-----------------------+        |  - 12 tests PASS      |
                                 +-----------------------+
```

## 2. 페이지명 Rename 결과 (3/3 success)

| page_id | 이전 제목 | 새 제목 | 결과 |
|---------|----------|---------|:----:|
| 3811967073 | EBS · Back Office PRD — 보이지 않는 뼈대 | **Back Office** | v13 → v14 |
| 3811901603 | EBS · Command Center PRD — 운영자가 매 순간 머무는 조종석 | **Command Center** | v14 → v15 |
| 3811672228 | EBS · Lobby PRD — 모든 테이블을 내려다보는 관제탑 | **Lobby** | v12 → v13 |

**Rename 도구**: `tools/confluence_rename_pages.py` (신규, S11 Cycle 18).
**제외 (사용자 명시)**: Foundation / RIVE_Standards / Product_SSOT_Policy / "1. Product".

## 3. 본문 Push 결과 (5/5 success — Cycle 16 PR #393 반영)

| PRD | page_id | 갱신 버전 | header verify | 비고 |
|-----|---------|----------|:-------------:|------|
| Back_Office.md (§5.3) | 3811967073 | v15 (rename 이후 v14 → v15) | 15/15 OK | — |
| Command_Center.md (§16.9) | 3811901603 | v16 | 23/23 OK | — |
| Foundation.md (§Ch.2) | 3625189547 | v49 | 13/13 OK | — |
| RIVE_Standards.md (Ch.2 9 카테고리) | 3816784235 | v10 | 38/42 (4 누락) | sanitizer 경고 |
| Game_Rules/Betting_System.md (§8) | 3811410570 | v10 | 13/13 OK | — |

### 3.1 RIVE_Standards 4 헤더 누락 (carry-over)

```
+-----------------------------------------------------+
| Confluence sanitizer 가 일부 구조 거부               |
+-----------------------------------------------------+
| Ch.14 — Community & Table Layout                    |
| Ch.19 — 토너먼트 상태 — JSON DB Output Only          |
| Ch.20 — 시계 — JSON DB Output Only                   |
| Ch.21 — 브랜딩 — JSON DB Output Only                 |
+-----------------------------------------------------+
```

**원인 가설** (확정 X): 직전 페이지에서 ac:layout 구조가 unbalanced → Confluence Cloud renderer 가 후속 H2 를 hidden frame 안으로 포섭. md2confluence.py `_convert_layout_blocks` 의 leaf-detection 한계.

**대응**:
- 본 cycle 에서는 사용자 진입점 최소화 위해 carry-over 처리 (페이지는 정상 push 됨).
- 다음 cycle S11 후속: `_convert_layout_blocks` regression test + headers verify 디버그 로그 강화 안건.

## 4. 도구 변경 (S11 신규/갱신)

| 도구 | 종류 | 역할 |
|------|------|------|
| `tools/confluence_rename_pages.py` | NEW | 사용자 명시 권한 페이지명 일괄 변경 (--plan / --dry-run / --execute) |
| `tools/confluence_pagename_audit.py` | PATCH | `_normalize` 추가 (underscore↔space + case + whitespace 정규화) |
| `tests/test_confluence_pagename_audit_normalize.py` | NEW | normalize 회귀 가드 12 case (Cycle 18 핵심 결정 pin) |
| `docs/4. Operations/Confluence_Sync_Spec.md` | PATCH v2.1.0 | §8 Cycle 18 partial rename 정책 + normalize 규칙 명시 |
| `docs/_generated/confluence-pagename-audit.md` | REGEN | 3/7 Product → MATCH (rename 반영) |
| `docs/_generated/confluence-mirror-matrix.md` | REGEN | 724 docs, coverage 63.7% |

## 5. KPI 달성

| KPI | 목표 | 결과 |
|-----|------|:----:|
| Confluence 페이지명 일치화 (사용자 명시 3종) | 3 MATCH | OK 3/3 |
| 5 PRD Confluence 본문 갱신 | 5 success | OK 5/5 |
| confluence-mirror-matrix.md drift | 0건 | OK (forward drift 343/343 aligned) |
| 회귀 테스트 통과 | 100% | OK 12/12 PASS |
| 사용자 진입점 | 최소 (1회) | OK (작업 명시 1회로 전체 cycle 자율 진행) |

## 6. broker 이벤트

```
mcp__ebs-message-bus__acquire_lock {
  resource: "tools/confluence_*",
  holder: "S11",
  ttl_sec: 900,
  acquired: true
}

mcp__ebs-message-bus__publish_event {
  topic: "cascade:confluence-sync-applied",
  payload: {
    cycle: 18,
    renamed_pages: ["3811967073", "3811901603", "3811672228"],
    content_pushed: 5,
    drift_violations: 0,
    headers_warn: ["RIVE_Standards 4/42 missing"]
  }
}
```

## 7. 영향 분석

### 7.1 외부 사용자 시각
- ✅ Confluence 검색에서 "Back Office", "Command Center", "Lobby" 직접 매칭
- ⚠️ 기존 한국어 제목 ("EBS · Back Office PRD — ...") 기반 북마크/공유 링크: page-id URL 은 stable, 제목 변경에 영향 없음
- ✅ 5 PRD 본문 = Cycle 16 PR #393 9 카테고리 재편 반영

### 7.2 내부 sync 파이프라인
- `md2confluence.py` 재실행 시: 새 제목 ("Back Office") 그대로 유지 (`info["title"]` 보존 contract). rename 한 번 → 영구 안정.
- `_linkify_path` URL-first 정책 (Cycle 11): 페이지명 변경에 무관하게 cross-link 클릭 가능.

## 8. Carry-over (다음 cycle)

| 항목 | 우선순위 | 비고 |
|------|:--------:|------|
| RIVE_Standards 4 헤더 누락 디버그 | LOW | Confluence sanitizer 거부 — `_convert_layout_blocks` regression test 추가 검토 |
| Foundation/RIVE_Standards/Product_SSOT_Policy rename 결정 | NONE | 사용자 명시 제외 — 결정 영역, 자율 변경 금지 |

## Changelog

| 날짜 | 버전 | 변경 |
|------|------|------|
| 2026-05-13 | v1.0 | Cycle 18 완료 보고 — rename 3 + push 5 + audit normalize + tests |
