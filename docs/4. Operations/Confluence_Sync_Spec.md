---
title: Confluence Sync Spec
owner: conductor
tier: internal
last-updated: 2026-05-13
version: 2.1.0
audience-target: 운영자 + Conductor + S11
related-docs:
  - Docker_Runtime.md
  - Cycle_Entry_Playbook.md
  - ../_generated/confluence-mirror-matrix.md
  - ../_generated/confluence-pagename-audit.md
---

# Confluence Sync Spec

> **SSOT for Markdown → Confluence mirroring.**
> 본 문서가 sync 도구 (`tools/sync_confluence.py` + `C:/claude/lib/confluence/md2confluence.py`) 의 계약을 정의한다.
> 코드/Confluence 가 본 문서와 충돌하면 **본 문서를 정정**해서 단방향으로 흐른다.

---

## 한 줄 요약

`docs/**/*.md` 의 frontmatter 에 `confluence-page-id` 또는 `confluence-url` 이 있으면 mirror 대상.
Sync 시 `related-docs:` 의 모든 `.md` 상대 경로는 **Confluence 내부 클릭 가능 링크** 로 변환된다.

---

## 1. End-to-End 흐름

```
+--------------------+      +-------------------------+      +------------------+
|  .md 파일           |      |  sync_confluence.py     |      |  md2confluence   |
|  frontmatter +     +----->+  - mirror 대상 스캔       +----->+  - MD → HTML     |
|  본문 markdown      |      |  - --check / --dry-run  |      |  - linkify       |
+--------------------+      |  - --filter             |      |  - upload        |
                            +-------------------------+      +--------+---------+
                                                                      |
                                                                      v
                                              +---------------------------------+
                                              |  Confluence Cloud (WSOPLive)    |
                                              |  - 페이지 본문                    |
                                              |  - related-docs 정보 패널         |
                                              |  - 인라인 cross-link              |
                                              +---------------------------------+
```

---

## 2. 페이지 명 vs 파일 stem — 현실은 불일치 (v2.0 정정)

> **Cycle 10 가정**: "Confluence 페이지 명 = 로컬 파일 stem". `ri:content-title=stem` 로 링크 생성.
> **Cycle 11 정정**: 7/7 Product PRD 가 가정 위반 — 페이지명이 한국어 설명형으로 길게 작성됨.

실측 데이터 (`tools/confluence_pagename_audit.py --filter "1. Product/*"` — 2026-05-13):

| 파일 stem | Confluence 페이지명 | 일치 |
|-----------|----------------------|:----:|
| `Foundation` | `EBS 기초 기획서` | X |
| `Lobby` | `EBS · Lobby PRD — 모든 테이블을 내려다보는 관제탑` | X |
| `Command_Center` | `EBS · Command Center PRD — 운영자가 매 순간 머무는 조종석` | X |
| `Back_Office` | `EBS · Back Office PRD — 보이지 않는 뼈대` | X |
| `Product_SSOT_Policy` | `EBS · Product SSOT Policy` | X |
| `RIVE_Standards` | `RIVE Standards — Overlay Graphics 정본` | X |
| `1. Product` | `EBS · 1. Product` | X |

전체 mirror 표: [`docs/_generated/confluence-pagename-audit.md`](../_generated/confluence-pagename-audit.md).

**선택지**:

| 대응 | 영향 | 채택? |
|------|------|:----:|
| (A) Confluence 페이지명 → file stem 으로 rename | 북마크 깨짐, 검색 히스토리 손실 | X 보류 (destructive, 사용자 결정 영역) |
| (B) Linkify 가 `<a href="{confluence-url}">` 사용 | 즉시 클릭 가능, 제목 변경에 무관 | O Cycle 11 채택 |

확정: **링크 가능성을 코드로 보장**하고, 페이지명 sync 는 별개 의제로 분리.

---

## 3. Frontmatter 계약

| 필드 | 필수 | 역할 |
|------|:----:|------|
| `confluence-page-id` | △ | 이 값 또는 `confluence-url` 중 하나 필수 |
| `confluence-url` | ◎ | **권장**. page-id 기반 URL — 페이지명 변경에도 stable |
| `confluence-parent-id` | ○ | 페이지 이동(`ancestors` 갱신) 시 사용 |
| `related-docs:` | ○ | YAML 리스트. 각 항목은 `.md` 상대 경로 + 선택적 괄호 설명 |
| `derivative-of` | ○ | 정본 파일 경로. 있으면 causality 패널 상단에 표시 |
| `tier` | ◎ | `contract` / `external` / `internal` / `generated`. 라벨 자동 부착 |

> `mirror: none` 을 frontmatter 에 추가하면 명시적으로 sync 대상에서 제외.

권장 frontmatter snippet:

```yaml
confluence-page-id: 3811901603
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3811901603
confluence-parent-id: 3811344758
```

---

## 4. linkify 해결 순서 (Cycle 11 — URL-first)

```
related-docs 항목 1개당:

  +-------------------------------+
  |  경로 토큰 추출 (괄호 strip)     |
  +---------------+---------------+
                  |
                  v
  +-------------------------------+   miss
  |  repo_map 조회 (relpath /     +-------+
  |                  basename)    |       |
  +---------------+---------------+       |
                  | hit                   |
                  v                       |
  +-------------------------------+       |
  |  confluence-url 있음?         |       |
  +---+---------------------------+       |
      | YES                | NO          |
      v                    v             v
  <a href="{url}">     ac:link(stem)   <code>...</code>
  (page-id URL,        (best-effort,    (no link)
   stable)              title-match
                        필요)
```

| 단계 | 산출 | 사용자 효과 |
|------|------|------------|
| URL anchor | `<a href="{confluence-url}">` | Confluence 페이지명 변경에도 stable. 클릭 시 페이지 이동 |
| ac:link fallback | `<ri:page ri:content-title="{stem}"/>` | hover preview 카드 (단, 페이지명=stem 일 때만) |
| code | `<code>경로</code>` | 회색 박스, 클릭 안 됨 — **신호: frontmatter 결락** |

**왜 URL-first?**
- `<a href>` URL 은 `/pages/3811901603` 처럼 page-id 기반. 페이지 rename 에도 변하지 않음.
- `<ri:page ri:content-title>` 는 페이지명 매칭 — Cycle 10 의 7/7 위반이 이미 증명.
- ac:link 의 hover card UX 손실은 cross-link 가능성보다 후순위.

---

## 5. CLI 사용법

```
# 1) Mirror 대상 미리보기
python tools/sync_confluence.py --list

# 2) Dry-run (변환만 시뮬레이션, 업로드 X)
python tools/sync_confluence.py --dry-run

# 3) CI 모드 (drift 감지 — main 외 브랜치 OK)
python tools/sync_confluence.py --check

# 4) 부분 sync (Game_Rules 만)
python tools/sync_confluence.py --filter "1. Product/Game_Rules/*"

# 5) 실 푸시 (main branch 강제)
python tools/sync_confluence.py

# 6) Title vs Stem audit
python tools/confluence_pagename_audit.py --filter "1. Product/*"
python tools/confluence_pagename_audit.py --markdown > docs/_generated/confluence-pagename-audit.md
```

> **Branch guard**: `--list` / `--check` 외에는 `main` 브랜치에서만 실행. 우회는 `EBS_FORCE_MIRROR=1` 또는 `--no-branch-guard`.

---

## 6. 회귀 테스트

| 파일 | 검증 |
|------|------|
| `tests/test_md2confluence_linkify.py` | URL-first 우선순위, ri:content-title fallback, unmapped → `<code>`, 공백 포함 경로 |

```
pytest tests/test_md2confluence_linkify.py -v
```

신규 PRD 추가 시 위 테스트가 통과해야 sync 신뢰 가능.

---

## 7. 운영 체크리스트

1. PRD 신규 추가 → frontmatter 에 `confluence-page-id` + **`confluence-url` 필수** 채움
2. 해당 PRD 의 `related-docs:` 항목들이 모두 mirror 대상인지 확인 (`--list` 로 점검)
3. `--check` 가 0 종료 코드 반환 확인
4. main 머지 후 `python tools/sync_confluence.py` 실 푸시
5. Confluence 에서 `related-docs` 정보 패널의 링크들이 **실제로 클릭** 되는지 1건 확인
6. (선택) `tools/confluence_pagename_audit.py` 로 페이지명 mismatch 보고 — 사용자와 rename 여부 협의

---

## 8. 페이지명 동기화 정책 (Cycle 18 부분 적용)

| 페이지 | 현재 Confluence 제목 | 정책 |
|--------|---------------------|------|
| `Back_Office.md` | **Back Office** | OK Cycle 18 rename 적용 (stem ↔ space 정규화 매칭) |
| `Command_Center.md` | **Command Center** | OK Cycle 18 rename 적용 |
| `Lobby.md` | **Lobby** | OK Cycle 18 rename 적용 |
| `Foundation.md` | EBS 기초 기획서 | X rename 보류 (사용자 명시 제외) |
| `RIVE_Standards.md` | RIVE Standards — Overlay Graphics 정본 | X rename 보류 (사용자 명시 제외) |
| `Product_SSOT_Policy.md` | EBS · Product SSOT Policy | X rename 보류 (사용자 명시 제외) |
| `1. Product.md` (parent) | EBS · 1. Product | X rename 보류 (사용자 명시 제외) |

**Rename 도구**: `tools/confluence_rename_pages.py` (S11 Cycle 18). 사용자 명시 권한 필수 (외부 북마크/검색 히스토리 손상 가능).

**Audit 정규화 규칙** (Cycle 18 신설 — `confluence_pagename_audit._normalize`):

```
underscore -> space    "Back_Office"  -> "back office"
collapse whitespace    "Back  Office" -> "back office"
case-insensitive       "Lobby"        -> "lobby"
strip                  "  Lobby  "    -> "lobby"
```

-> `Back_Office.md` <-> `Back Office` 제목은 MATCH 로 분류. 회귀 가드: `tests/test_confluence_pagename_audit_normalize.py` (12 cases).

---

## Changelog

| 날짜 | 버전 | 변경 내용 | 변경 유형 | 결정 근거 |
|------|------|-----------|----------|----------|
| 2026-05-13 | v2.1.0 | Cycle 18 partial rename 정책 + audit normalize 규칙 추가 | PRODUCT | 사용자 명시 권한 — Back Office / Command Center / Lobby 3 페이지 rename + audit underscore↔space 정규화 |
| 2026-05-13 | v2.0.0 | URL-first linkify 로 전환 + 페이지명 audit 도구 추가 + spec 정정 | TECH | `tools/confluence_pagename_audit.py` 가 Product PRD 7/7 가정 위반 증명. ri:content-title=stem 전략은 실측 환경에서 dead link 생성. URL-first 가 page-id 기반이라 stable |
| 2026-05-12 | v1.0.0 | 최초 작성 (Cycle 10 S11) — stem 기반 ri:content-title | TECH | Confluence 내 related-docs 링크가 클릭 불가능했던 사용자 보고. (Cycle 11 에서 가정 자체가 깨졌음을 발견) |
