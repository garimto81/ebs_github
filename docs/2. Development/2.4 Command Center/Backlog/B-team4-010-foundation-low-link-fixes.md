---
id: B-team4-010
title: Foundation 재설계 P3 — LOW 링크·참조 갱신
status: PENDING
source: docs/2. Development/2.4 Command Center/Foundation_Impact_Review.md §3.4
mirror: none
---

# [B-team4-010] Foundation 재설계 LOW — 참조·링크 갱신

- **등록일**: 2026-04-22
- **기획 SSOT**: `docs/2. Development/2.4 Command Center/Foundation_Impact_Review.md` §3.4 (L1~L4)

## 수락 기준

### L1. Overlay/Overview.md §3 — Foundation Ch.4 Layer 1 참조

- [ ] "Foundation (Confluence SSOT) Ch.4 Layer 1" 참조를 Ch.4 재작성 (2 렌즈) 반영하여 적절 섹션으로 업데이트
- [ ] Layer 1/2/3 개념의 상위 근거가 필요하면 Layer_Boundary.md 로 delegate

### L2. Command_Center_UI/Overview.md 편집 이력

- [ ] 2026-04-22 행 추가: "Foundation §6.3 재작성 cross-reference 확인 — §1.1.1 병행 dispatch 는 이미 반영 완료"

### L3. Overlay/Skin_Loading.md

- [ ] "배경 config flag" 관련 언급 검증 (grep 미발견이면 변경 없음)
- [ ] 스킨 로드/전환 시 배경 flag 영향 여부 검토 — 별도 섹션이 필요하면 후속 PR

### L4. Overlay/Security_Delay.md — 2 모드 분기 하 버퍼 위치

- [ ] 2 런타임 모드 (§5.0) 에서 Security Delay 버퍼가 어느 프로세스에 있는지 확인
- [ ] 탭 모드: CC 프로세스 내 / 다중창 모드: Overlay 프로세스 내 (송출 직전 버퍼)
- [ ] 차이가 있다면 §1 구현 위치 표에 2 모드 행 추가

### 공통

- [ ] 문서 only — 코드 영향 없음
- [ ] 커밋: `docs(team4): B-team4-010 Foundation 재설계 참조 링크 정리 (L1~L4) 🔗`

## 참조

- Foundation SSOT: `docs/1. Product/Foundation.md`
- Impact Review: `docs/2. Development/2.4 Command Center/Foundation_Impact_Review.md` §3.4
