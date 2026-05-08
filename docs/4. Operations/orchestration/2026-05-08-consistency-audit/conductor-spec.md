---
owner: conductor
tier: internal
stream: Conductor
name: 잔여 영역 + 통합 검증
worktree: C:/claude/ebs (main)
phase: P0 (잔여) + P4 (통합 검증)
audit_basis: docs/4. Operations/orchestration/2026-05-08-consistency-audit/foundation_ssot.md
last-updated: 2026-05-08
confluence-page-id: 3818521179
confluence-parent-id: 3811573898
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818521179/EBS+Conductor+spec
---

# Conductor — 잔여 영역 + 통합 검증 spec

## 🎯 미션

1. **8 Stream 이 다루지 않는 잔여 영역 정합** (~302 files)
2. **모든 Stream PR 머지 후 통합 검증**

## 📂 영향 파일 (잔여 ~302)

### A. governance / meta (수정 가능)

| 파일 | 작업 |
|------|------|
| `docs/1. Product/Product_SSOT_Policy.md` | self-consistency |
| `docs/2. Development/2.5 Shared/team-policy.json` | meta — 변경 시 advisory |
| `docs/2. Development/2.5 Shared/Stream_Entry_Guide.md` | 정합 |
| `docs/2. Development/2.5 Shared/Authentication/**` | RBAC cascade (Foundation §15) |
| `docs/4. Operations/Multi_Session_Design_v10.3.md` | meta self-check |
| `docs/4. Operations/team_assignment_v10_3.yaml` | meta |
| `docs/4. Operations/Spec_Gap_Triage.md` | governance |
| `docs/4. Operations/Docker_Runtime.md` | 운영 (cross-stream drift 발견 시 NOTIFY 위탁 — Foundation §A.4 정합성은 owner 영역) |
| ~~`docs/4. Operations/Multi_Session_Handoff.md`~~ | **deprecated** — `docs/_archive/governance-2026-05/Multi_Session_Handoff.md` 로 이전됨 (frozen) |
| `docs/4. Operations/Conductor_Backlog/**` | conductor backlog |
| `docs/4. Operations/Reports/**` | conductor reports |
| `docs/4. Operations/Critic_Reports/**` | conductor critic |
| `docs/4. Operations/handoffs/**` | conductor handoffs |
| `docs/4. Operations/Task_Dispatch_Board/**` | conductor dispatch |

### B. frozen (read only)

| 패턴 | 처리 |
|------|------|
| `docs/1. Product/References/**` | 벤치마크. drift 발견 시 보고만 |
| `docs/1. Product/archive/**` | 이력. 수정 X |
| `docs/_archive/**` | 거버넌스 archive. 수정 X |

### C. assets (감사 대상 외)

| 패턴 | 처리 |
|------|------|
| `docs/mockups/**` | 자산. 정합성 감사 외 |
| `docs/examples/**` | 자산. 정합성 감사 외 |
| `docs/images/**` | binary. skip |

### D. 별도 워크플로우 (감사 대상 외)

| 패턴 | 처리 |
|------|------|
| `docs/3. Change Requests/**` (94 files) | CR 별도 워크플로우. 각 CR 의 stream owner 가 정상 처리 |

## ✅ 검증 항목

### Phase A — 잔여 영역 (Stream PR 머지 전 병렬 진행)

1. governance / meta 파일 self-consistency
2. RBAC cascade (Foundation §15)
3. 본 audit 의 README + foundation_ssot + classification + stream-specs 일관성

### Phase B — 통합 검증 (모든 Stream PR 머지 후)

1. **doc_discovery cascade 전체**: `python tools/doc_discovery.py --impact-of "docs/1. Product/Foundation.md"` → 모든 derivative drift 0건
2. **scope_check.yml CI**: 모든 PR 통과
3. **product_cascade.yml CI**: 통과
4. **wsop-alignment-check.yml CI**: 통과
5. **spec-drift-gate.yml CI**: 통과
6. **Match Rate**: 각 Stream gap-detector ≥ 90%
7. **사용자 보고**: 정합성 100% 달성 + 미해소 drift list (있을 시)

## 🔄 자율 Iteration

### Phase A (즉시 진행)

```
1. 잔여 영역 ~302 files 그룹별 cascade 검증
2. governance / meta 문서 self-consistency
3. drift 정정 (단일 commit per file)
4. main 직접 commit (orchestrator 권한)
```

### Phase B (Stream 머지 후)

```
1. 30s 간격 gh pr list --label consistency-audit --state merged 폴링
2. 8 Stream 모두 머지 확인 후 통합 검증 시작
3. doc_discovery cascade → drift 0 확인
4. CI gate 모두 통과 확인
5. 미해소 drift 발견 시 → 해당 stream NOTIFY backlog
6. 사용자 최종 보고
```

## 📋 통합 검증 체크리스트

- [ ] 8 Stream PR 모두 머지 (S1 → S2..S4,S7,S8 → S5,S6 순서)
- [ ] `tools/doc_discovery.py --impact-of` 전체 cascade 통과
- [ ] CI gates 모두 green
- [ ] Match Rate ≥ 90% (모든 Stream)
- [ ] frozen 영역 변경 없음 검증
- [ ] 잔여 영역 (~302) cascade 통과
- [ ] 사용자 보고 작성 (Reports/2026-05-08-consistency-audit-final.md)
