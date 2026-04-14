# SSOT-Aligned Spec Section Template (EBS)

복사해서 쓰는 템플릿. 각 섹션은 아래 5개 블록 필수 (project-native 는 🏷️ 블록 1개).

편집 시 `/ssot-align <file> <heading>` 실행하면 자동 생성/갱신됨.

---

## §<N>. <섹션 제목>

### 📎 원본 SSOT

- Confluence 페이지: <제목>
- Page ID: `<page_id>`
- URL: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/<page_id>
- 조회 명령: `/con-lookup page <page_id>`
- 마지막 SSOT 확인: YYYY-MM-DD HH:MM KST
- Confluence version: v<N>

### 📋 Verbatim 추출

> 추출 시각: YYYY-MM-DD HH:MM KST (source version v<N>)
> Source location: <heading path in upstream>

```
<WSOP 원문 verbatim. PascalCase, int 코드 등 변경 없이>
```

### 🔀 매핑표

| WSOP 원본 | 원본 타입 | EBS 반영 | EBS 타입 | 판정 | Phase | Adapter |
|----------|---------|---------|---------|------|-------|---------|
| `<value>` | `<type>` | `<local or —>` | `<type or —>` | `<VERDICT>` | `<bucket>` | `<path>` |

판정: IDENTICAL / RENAMED / SUBSET / SUPERSET / DIVERGENT / DEFERRED

### 🚀 마이그레이션 계획

- **Phase 1 (2026 Q2)**: <target rows>
- **Phase 2 (2026 Q3-Q4)**: <target rows>
- **Phase 3+ (2027+)**: <target rows>
- Adapter:
  - `<path>` — `<function signature or purpose>`
- Test:
  - `<path>` — <coverage>

### ✅ 검증 체크리스트

- [ ] 최근 7일 이내 `/con-lookup page <page_id>` 재조회 완료 (last: YYYY-MM-DD)
- [ ] Confluence 최신 version 과 본 섹션의 SSOT version 일치
- [ ] 매핑표 모든 행에 판정 존재
- [ ] DEFERRED 행 모두 Phase 계획에 배정됨
- [ ] RENAMED 행에 Adapter 경로 + 테스트 참조 존재
- [ ] doc-critic: High 지적 0건

---

## §<N>. <프로젝트 고유 섹션 제목>

### 🏷️ 프로젝트 고유 (No SSOT)

외부 SSOT 없음 (예: RFID HAL, Rive Overlay 등 EBS 고유 영역). Owner: `<owner>`. 사유: <한 줄>.
