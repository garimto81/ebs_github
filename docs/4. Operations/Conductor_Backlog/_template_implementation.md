---
id: IMPL-XXX
title: "구현: <기능명>"
type: implementation
status: PENDING  # PENDING | IN_PROGRESS | DONE
owner: conductor  # 또는 해당 팀
created: YYYY-MM-DD
spec_ready: true  # 기획 확정 전에는 false. false 일 땐 spec_gap 먼저 해결 필수
blocking_spec_gaps: []  # 차단하는 SG-XXX 리스트
implements_chapters:
  - docs/2. Development/2.X XXX/YYY.md
---

# IMPL-XXX — <제목>

## 구현 범위

이 작업이 건드리는 파일/모듈 목록과 변경 성격.

## 기획 참조 (재확인 필수)

- 챕터 A: 이 작업이 준수해야 할 계약
- 관련 API / Schema: 고정 참조점

> **전제**: `spec_ready: true` 인가? false 라면 먼저 `../Spec_Gaps/` 해결 → 여기로 복귀.

## 수락 기준

- [ ] 빌드/테스트 통과
- [ ] 기획 챕터의 모든 수락 기준 만족
- [ ] 연결된 `Prototype_Scenario` 시나리오 통과
- [ ] 재구현 가능성 FAIL → PASS 로 전환 (Roadmap 반영)

## 구현 메모

- 구현 중 발견된 기획 공백/모순 (→ `../Spec_Gaps/` 로 분리):
