# PRD-기술설계 경계 재정립 계획서

> **Version**: 1.0.0
> **Date**: 2026-02-18
> **복잡도**: 4/5 (HEAVY)
> **모드**: 적극 이관

---

## 배경

PRD v2 (v21.0.0)는 "무엇"(what) 중심으로 잘 작성되었으나, 일부 기술 구현 상세("how")와 대형 카탈로그(부록 B/C)가 PRD에 남아있다. Design doc (v2.0.0)은 이미 기술 스펙 중심이므로, "how" 콘텐츠를 design doc으로 이관하여 문서 경계를 명확히 한다.

## 4개 작업

### Task 1: PRD→Design Doc "how" 콘텐츠 이관

**이관 항목 6개:**

| # | 출처 (PRD v2) | 대상 (Design Doc) | 분량 |
|:-:|--------------|-------------------|------|
| 1 | Section 11 Lookup Table 상세 | Section 6.6 Lookup Table 아키텍처 | ~25줄 |
| 2 | Section 6 GameInfoResponse 필드 분해 | Section 8.5 GameInfoResponse | ~16줄 |
| 3 | Section 6 AES-256 CBC 참조 | Section 12.5 암호화 시스템 | ~3줄 |
| 4 | Section 8 Dual Transport 속도 비교 | Section 9.2 듀얼 트랜스포트 | ~15줄 |
| 5 | 부록 B: 99개 외부 명령 카탈로그 | Section 8.4 프로토콜 명령 | ~160줄 |
| 6 | 부록 C: 144개 기능 카탈로그 | 새 Section 17: 기능 카탈로그 | ~106줄 |

**PRD 처리**: 이관된 내용을 요약 1-2줄 + `→ design doc 참조` 링크로 대체

**Design Doc 처리**:
- 부록 B → Design doc Section 8.4에 11개 카테고리 상세 통합 (기존 9개→11개 정정)
- 부록 C → Design doc 새 Section 17로 추가
- 나머지 → 기존 해당 섹션에 통합

### Task 2: 데이터 모델/ERD

Design doc Section 16 확장:
- 핵심 엔티티: Game, Player, Card, Hand, Seat, Board, Bet, Action, Skin, GraphicElement, RfidReader, Canvas
- Mermaid erDiagram 작성
- 기존 Enum 카탈로그와 연동

### Task 3: 구조 다이어그램 Mermaid 변환

3개 PNG → inline Mermaid:
- `prd-3layer-architecture.png` → graph TB (Hardware → Server → Clients)
- `prd-6module-overview.png` → graph (Hub-Spoke: Server 중심 6모듈)
- `prd-7app-ecosystem.png` → graph (GfxServer + ActionTracker + HandEvaluation)

### Task 4: 미사용 이미지 아카이브

~52개 이미지를 `docs/archive/images/`로 이동:
- diagram-* (15) → archive/images/diagram/
- screenshots/ (11) → archive/images/screenshots/
- annotated/ (11) → archive/images/annotated/
- prd/ 미참조 (5) → archive/images/prd/
- web/ 미참조 (10) → archive/images/web/

## 실행 순서

```
Phase 1: Task 1 (경계 재정립) + Task 4 (이미지 아카이브) — 병렬
Phase 2: Task 2 (데이터 모델/ERD) + Task 3 (Mermaid 변환) — 병렬
Phase 3: 검증 (Architect)
```

## 영향 파일

| 파일 | 변경 |
|------|------|
| `docs/01-plan/pokergfx-prd-v2.md` | 이관 콘텐츠 축소, Mermaid 교체, v22.0.0 |
| `docs/02-design/features/pokergfx.design.md` | 이관 콘텐츠 통합, ERD 추가 |
| `docs/01-plan/images/` | 미사용 이미지 이동 |
| `docs/archive/images/` | 아카이브 대상 |

## 위험 요소

| 위험 | 대응 |
|------|------|
| Google Docs 동기화 깨짐 | Mermaid는 GitHub 렌더링용, Google Docs용 PNG는 mockups/에 유지 |
| 아카이브 이미지가 다른 문서에서 참조 | 아카이브 문서의 경로는 이미 ../images/ 형태라 별도 수정 불필요 |
| Design doc 섹션 번호 변경 | 부록 C를 Section 17로 추가, 기존 번호 유지 |
