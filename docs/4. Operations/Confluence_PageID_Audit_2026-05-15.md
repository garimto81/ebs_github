---
title: Confluence Page-ID Mapping Audit — 2026-05-15
owner: S11/conductor
tier: internal
type: audit-report
audit-date: 2026-05-15
related-tool: tools/confluence_page_id_audit.py
confluence-page-id: null
---

# Confluence Page-ID Mapping Audit — 2026-05-15

> **결론**: 344개 git `.md` 파일 중 **341개 정상 확인**, 자율 정정 1건, 사용자 결정 필요 4건.

---

## 요약

| 항목 | 수 |
|------|:--:|
| ✅ 정상 (page-id 검증 통과) | 341 |
| 🔄 자율 정정 (URL shortlink → 전체 URL) | 1 |
| ❌ 페이지 없음 (Confluence 404) | 2 |
| 📋 중복 타이틀 (spaces 간) | 1 |
| 🆕 미매핑 Confluence 페이지 | 342 |

---

## 자율 정정 내역

### Foundation.md — confluence-url shortlink 정정

| 항목 | 내용 |
|------|------|
| 파일 | `docs/1. Product/Foundation.md` |
| 수정 유형 | `confluence-url` shortlink → 전체 canonical URL |
| 변경 전 | `https://ggnetwork.atlassian.net/wiki/x/qwAU2` |
| 변경 후 | `https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3625189547` |
| page-id | `3625189547` (변경 없음 — 원래 정확했음) |

Shortlink는 Confluence UI에서 "복사" 시 생성되는 단축 URL. page-id는 정확했으나 URL 형식이 다른 파일과 불일치.

---

## 사용자 결정 필요 항목

### 1. `4. Operations.md` — Confluence 페이지 삭제됨

| 항목 | 내용 |
|------|------|
| 파일 | `docs/4. Operations/4. Operations.md` |
| 현재 page-id | `3811573898` |
| Confluence 상태 | **404 Not Found** (페이지 삭제됨) |
| parent | `3184328827` (WSOPLive EBS root) |

**확인 결과**: WSOPLive EBS 트리에서 `4. Operations` 섹션이 사라짐. EBS root의 직접 자식은 현재 5개뿐:
- EBS · 1. Product
- EBS · 2. Development  
- EBS · 3. Change Requests
- EBS · Phase Plan 2027
- EBS · Global SSOT Sync

**권고**: 아래 중 선택

| 옵션 | 방법 |
|------|------|
| A. 새 Confluence 페이지 생성 | Confluence에서 EBS root 아래 `EBS · 4. Operations` 신규 생성 → 새 page-id로 frontmatter 업데이트 |
| B. Confluence 미러링 제외 | `confluence-page-id: null` + `mirror: none` 으로 변경 |

---

### 2. `Inter_Session_Chat_Design.md` — page-id TBD (미발행)

| 항목 | 내용 |
|------|------|
| 파일 | `docs/4. Operations/Inter_Session_Chat_Design.md` |
| 현재 page-id | `TBD` (발행 전 placeholder) |

**권고**: Confluence에 발행 후 frontmatter 업데이트. 또는 미발행 상태 유지 (현재대로).

---

### 3. `EBS-Skin-Editor_v3.prd` — spaces 간 중복 타이틀

| space | page-id | 버전 | 비고 |
|-------|---------|:----:|------|
| WSOPLive | `3818717668` | v2 | ← git frontmatter 참조 |
| 개인 space | `3833462916` | v3 | 개인 space에 최신본 존재 |

Git frontmatter는 WSOPLive v2를 가리킴. 개인 space에 v3가 있어 최신 내용이 다를 수 있음.

**권고**: 아래 중 선택

| 옵션 | 방법 |
|------|------|
| A. WSOPLive를 정본으로 유지 | 개인 space v3를 WSOPLive에 머지 후 개인 space 페이지 삭제 |
| B. git frontmatter를 개인 space v3로 업데이트 | page-id를 `3833462916`으로 변경 |

---

### 4. 개인 space 334개 미매핑 페이지 — 삭제 여부

**상황**: 개인 space(`~71202036ff7e0a7684471195434d342e3315ed`)에 EBS 전체 구조의 완전한 mirror가 존재. 334개 페이지가 WSOPLive의 대응 페이지와 별도로 존재.

**패턴 분석**:
- 개인 space 페이지들은 WSOPLive 페이지와 동일한 구조/타이틀을 가짐
- Git frontmatter는 모두 WSOPLive를 가리킴 (정확)
- 개인 space는 작업 draft/staging area로 사용된 것으로 추정

**권고**: 개인 space 페이지 정리를 검토. 단, **자율 삭제 금지** (사용자 확인 필수).

주요 중복 예시:
```
개인 space Betting_System:
  id=3833036921  title=Betting_System           (v1)
  id=3833462896  title=Betting_System (Game_Rules) (v1)
  
WSOPLive (git 정본):
  id=3811410570  title=EBS Game Rules — Betting System (v10)
```

---

## 미매핑 Confluence 페이지 분류

| 분류 | 수 | 설명 |
|------|:--:|------|
| WSOPLive structural (폴더 루트) | 8 | EBS root, 서브섹션 루트 등. git .md 불필요 (navigation 전용) |
| 개인 space mirror | 334 | WSOPLive 대응 페이지의 개인 space 복사본 |
| **합계** | 342 | |

WSOPLive structural 8개 (git .md 불필요):
- `3184328827` EBS (root)
- `3818521542` EBS · 3. Change Requests
- `3812360338` EBS · 1. Product · Game Rules
- `3811606750` EBS · 2.1 Frontend
- `3811770578` EBS · 2.2 Backend
- `3811836049` EBS · 2.3 Game Engine
- `3811901565` EBS · 2.4 Command Center
- `3812032646` EBS · 2.5 Shared

---

## 도구 정보

```bash
# Audit 재실행 (dry-run)
python tools/confluence_page_id_audit.py --dry-run

# 실제 적용
python tools/confluence_page_id_audit.py

# 특정 EBS 루트만
python tools/confluence_page_id_audit.py --roots 3184328827
```

- **도구 위치**: `tools/confluence_page_id_audit.py`
- **JSON 보고서**: `docs/4. Operations/confluence-page-id-audit.json`
- **대상 space**: WSOPLive (EBS root: `3184328827`) + Aiden Kim 개인 space (EBS root: `3833167989`)
