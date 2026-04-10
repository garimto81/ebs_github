# 07-archive — 레거시 문서 보관소

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 경계 명시 | archive 문서 참조 금지 규칙 명시 |

---

## 규칙

**이 폴더의 문서는 활성 문서에서 참조하지 않는다.**

- 여기에 있는 문서는 역사적 기록 목적으로만 보존
- 새로운 행동 명세나 기술 설계에서 이 폴더의 문서를 직접 참조하면 안 됨
- 활성 참조가 필요한 문서는 해당 활성 폴더로 승격 (복사) 해야 함

### 승격된 문서 (2026-04-09)

| 원본 (archive) | 승격 위치 | 이유 |
|---------------|----------|------|
| `00-prd-archive/EBS-Feature-Catalog.md` | `docs/01-strategy/EBS-Feature-Catalog.md` | 144개 기능 ID — BS-00, 로드맵, QA에서 참조 |
| `00-prd-archive/PRD-EBS_DB_Schema.md` | `contracts/data/PRD-EBS_DB_Schema.md` | DATA-04에서 참조 |

## 폴더 구조

| 폴더 | 내용 |
|------|------|
| `00-prd-archive/` | 초기 PRD 버전, 기능 카탈로그 (원본 보존) |
| `01-pokergfx-analysis/` | PokerGFX 역설계 분석 자료 |
| `02-design/` | 초기 UI 설계 |
| `03-plans/` | 과거 계획서 |
| `04-reports/` | 과거 보고서 |
| `05-phase-prds/` | Phase별 PRD 초안 |
| `06-operations/` | 운영 문서 (업체 관리, 커뮤니케이션) |
| `07-legacy/` | 폐기된 문서 |
