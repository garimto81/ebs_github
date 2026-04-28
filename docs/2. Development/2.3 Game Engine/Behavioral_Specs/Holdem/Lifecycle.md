---
title: Lifecycle
owner: team3
tier: deprecated
legacy-id: BS-06-01
deprecated: 2026-04-28
redirect-to: "../Lifecycle_and_State_Machine.md"
status: superseded
supersedes-by: "../Lifecycle_and_State_Machine.md"
---

# [DEPRECATED 2026-04-28] BS-06-01: Lifecycle

> ⚠️ **본 문서는 deprecated 되었습니다 (2026-04-28).**
>
> 모든 내용은 [Lifecycle & State Machine](../Lifecycle_and_State_Machine.md) 도메인 마스터에 **무손실 통합** 되었으며, 후속 변경은 도메인 마스터에서 이루어집니다.

## 흡수 위치

본 문서의 매트릭스 / 알고리즘 / pseudocode / 유저 스토리 / WSOP Rule 매핑 등 모든 항목은 [`../Lifecycle_and_State_Machine.md`](../Lifecycle_and_State_Machine.md) 의 **부록 A: Legacy-ID Mapping** 에서 정확한 위치를 확인할 수 있습니다.

| 원본 | → 통합 위치 |
|------|------------|
| BS-06-01 (Lifecycle) | Lifecycle & State Machine 도메인 마스터 §부록 A |

## 원본 보존

원본 내용은 **git history 에 영구 보존** 됩니다 — 본 deprecation 직전 commit hash 에서 전체 내용 조회 가능:

```bash
git log --all --follow -- "docs/2. Development/2.3 Game Engine/Behavioral_Specs/Holdem/Lifecycle.md"
git show <commit-hash>:"docs/2. Development/2.3 Game Engine/Behavioral_Specs/Holdem/Lifecycle.md"
```

## 통합 PR

| 도메인 | PR | 일자 |
|--------|----|------|
| Lifecycle & State Machine | #7 | 2026-04-27 |
| Triggers & Event Pipeline | #9 | 2026-04-27 |
| Betting & Pots | #12 | 2026-04-28 |
| Variants & Evaluation | #14 | 2026-04-28 |
| **Deprecation Shim (본 PR)** | TBD | 2026-04-28 |

## 신규 참조

- 도메인 마스터 본문: [`../Lifecycle_and_State_Machine.md`](../Lifecycle_and_State_Machine.md)
- 도메인 마스터 부록 A (legacy-id 매핑): 같은 파일 §부록 A
- Legacy-ID redirect mapping (audit 도구용): [`docs/_generated/legacy-id-redirect.json`](../../../../_generated/legacy-id-redirect.json) (Conductor 자동 생성)
