# PDCA Plan: PokerGFX Clone PRD v4.0 전면 재설계

**Plan ID**: pokergfx-clone-prd-v4
**Created**: 2026-02-14
**Status**: APPROVED (Ralplan 합의 완료)

---

## 배경

PRD v3.0.1이 "맥락적으로도 내러티브적으로도 무의미한 정보의 나열"이라는 사용자 피드백을 받음. 처음 PokerGFX를 만드는 개발팀이 읽을 수 있는 내러티브 기반 기획서로 전면 재설계.

## 문제 정의

v3.0.1의 5가지 문제:
1. PokerGFX가 뭔지 구체적으로 설명하지 않음 — 포커 방송 자체를 모르는 팀은 이해 불가
2. 비즈니스 맥락 부재 — 왜 경쟁사 인수가 위험인지, 왜 WSOP+가 기회인지 설명 없음
3. 역공학 데이터가 PRD에 무분별하게 혼합됨 — Feature ID(PS-001~013)는 외부인에게 암호
4. Phase 번호가 Master PRD와 불일치 — Clone PRD Phase 1-5 vs Master PRD Phase 0-3
5. "왜" 섹션이 제네릭/보일러플레이트 — 설득력 없는 이유 나열

## 복잡도 점수

**5/5** (Ralplan 실행)

| # | 조건 | 점수 | 근거 |
|:-:|------|:----:|------|
| 1 | 파일 범위 | 1 | PRD + Plan + 다수 참조 문서 |
| 2 | 아키텍처 | 1 | 문서 구조 전면 재설계 (11섹션 → 9섹션 내러티브) |
| 3 | 의존성 | 1 | Master PRD, Feature Checklist, 역공학 분석 3종 참조 |
| 4 | 모듈 영향 | 1 | PRD + Google Docs + PDCA 문서 3종 |
| 5 | 사용자 명시 | 1 | "전면 재설계" 명시 |

## Ralplan 합의 결과

### Planner 관점
- **구조**: 7섹션 (What→Why→Known→Build→How→Risk→Ref)
- **진단**: v3.0.1의 5가지 문제 식별
- **핵심 제안**: "30초 요약 + 구체적 PokerGFX 설명" 필수, ~510줄 목표

### Architect 관점
- **구조**: 4레이어 (왜→무엇을→어떻게→언제)
- **접근법**: 2-Layer 문서 (PRD = 전략적 전체 그림, 별도 상세문서 = 기술)
- **기술 보정**: 4개 기술적 오류 식별 (RFID 안테나 수, 네트워크 명령 수, 게임 상태 머신 등)

### Critic 관점
- **구조**: 9섹션 통합 제안
- **핵심 지적**: Phase 번호 Master PRD 정렬 필수, "역공학 결과를 PRD에 혼합하는 것이 핵심 문제"
- **리포-스패닝 충돌**: ebs vs ebs_reverse 두 레포 간 문서 참조 정합성

### 3자 합의 사항
1. **PokerGFX 구체적 설명**: 포커 방송의 특수성부터 시작하여 시스템 역할 설명
2. **비즈니스 이유 3가지 명확히**: PokerGO 인수 → WSOP+ 기회 → 최소 리소스 전략
3. **역공학 데이터는 요약만**: 핵심 아키텍처 패턴만 PRD에 포함, 상세는 별도 문서 참조
4. **Phase 번호 정렬**: Master PRD Phase 0-3 체계 사용
5. **Feature 상세 위임**: 149개 기능 상세는 Feature Checklist에 위임, PRD는 카테고리별 요약만

## 구현 범위

- `pokergfx-clone-prd.md` 전면 재작성 (v3.0.1 → v4.0.0)
- 9섹션 내러티브 구조
- 대상 독자: "처음 PokerGFX를 만드는 개발팀"

## 제외 항목

- Feature Checklist 수정 (별도 문서, 변경 불필요)
- UI Analysis 수정 (별도 문서)
- 역공학 분석 문서 수정 (별도 문서)
- 기존 이미지/다이어그램 재생성 (기존 것 활용 가능)

## 예상 영향 파일

- `C:\claude\ebs_reverse\docs\01-plan\pokergfx-clone-prd.md` (전면 재작성)
- `C:\claude\ebs_reverse\docs\01-plan\pokergfx-clone-prd.plan.md` (본 문서)

## 위험 요소

1. **PRD 길이 과도** → 500줄 이내 목표, 상세는 참조 문서로 위임
2. **역공학 요약 수준 조절** → 개발팀이 구현에 필요한 핵심만 포함
3. **Phase 일정 불일치** → Master PRD가 단일 진실 공급원, 그대로 따름
4. **두 레포 간 참조 경로** → 상대 경로 사용, ebs/ebs_reverse 명시

## 관련 PRD

- PRD-0003-EBS-Master (Master PRD v9.1.0)

## 기존 Plan 중복 확인

- `pokergfx-prd-rewrite.plan.md`: 이전 v3.0 리라이트 계획 → v4.0으로 대체됨
- `designer-prd-rewrite.plan.md`: 디자이너 PRD 별도 문서 → 중복 아님
- `pokergfx-reverse-engineering.plan.md`: 역공학 분석 계획 → 별도 작업, 중복 아님

---

**Version**: 1.0.0 | **Updated**: 2026-02-14
