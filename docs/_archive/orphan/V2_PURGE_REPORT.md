---
title: V2 Purge Report — 사용자 명시 "ebs v2 별개 프로젝트" cascade
owner: conductor
tier: internal
type: audit-report
linked-decision: 사용자 명시 (2026-04-27) "ebs v2 = 별개 프로젝트, 폐기"
audit-date: 2026-04-27
status: CLOSED (Q1.㉠ + Q2.㉠ 채택 2026-04-27)
closed-by: user
closed-decision: "Q1.㉠ 본 repo 내부만 의미 (외부 자산은 별개 프로젝트, 본 repo 와 무관) + Q2.㉠ history references 보존"
last-updated: 2026-04-27
confluence-page-id: 3818816241
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818816241/EBS+V2+Purge+Report+ebs+v2+cascade
---

## 결정 (사용자 명시 2026-04-27)

> URGENT DIRECTIVE: ebs v2 Legacy Purge & Selective Integration Protocol
> "ebs v2는 현재 프로젝트와 완전히 별개인 프로젝트". 잔재를 전수 검사, 선별 통합, 완전 폐기.

## Phase A — Full System Audit 결과

### A.1 본 repo 내부 v2 자산 (코드/디렉터리/파일명)

| 자산 | 의미 | 분류 |
|------|------|:----:|
| `team1-frontend/_archive-quasar/node_modules/.pnpm/.../codegenv2` | npm package version (무관) | 무관 |
| `team1-frontend/_archive-quasar/node_modules/.pnpm/.../vue-demi/lib/v2` | npm package compatibility layer (무관) | 무관 |
| `docs/.../skin-editor/archive/EBS-Skin-Editor_v2.prd.md` | **Skin Editor PRD 의 v2 버전** (별개 의미, archive 보존) | 보존 |
| `team1-frontend/build/.../sym_upload_v2_protocol.{md,cc,h}` | breakpad library v2 protocol (무관) | 무관 |
| `team4-cc/src/build/.../sym_upload_v2_protocol.{md,cc,h}` | breakpad library v2 protocol (무관) | 무관 |

**결과**: 본 repo 내부 "ebs v2" 관련 코드/디렉터리/파일 = **0건**.

### A.2 본 repo 내부 v2 키워드 references (Grep)

| 파일 | 의미 |
|------|------|
| `Phase_1_Decision_Queue.md` | v7.2 (5-Session Pipeline) 거버넌스 layer 명시 (무관) |
| `Conductor_Backlog/SESSION_1_HANDOFF.md` | ebs_v2 발견 보고 (history) |
| `Conductor_Backlog/B-Q17-engine-healthcheck-fix.md` | ebs-v2-engine 진단 (Type A 발견 보고) |
| `team1-frontend/web/README.md` | ebs-v2-lobby-web 정리 history (B-Q3 deprecation 마커) |
| `Conductor_Backlog/B-Q2-docker-lobby-web-cleanup.md` | ebs-v2-lobby-web Resolution Log |
| `docker-compose.yml` | "REMOVED 2026-04-27 SG-022" 마커 (lobby-web 폐기 history) |

**결과**: 모두 **history reference** (이전 cascade 의 audit/decision 기록). 코드 자산 0, 의사결정 추적성 보존.

### A.3 Git 브랜치 v2 키워드

| 브랜치 | 의미 |
|--------|------|
| `work/team2/_team-20260422-110942-b088pr4v2` | "v2" suffix 는 b088pr4 의 두번째 변형 (무관) |

**결과**: ebs v2 관련 브랜치 = **0건**.

### A.4 Git log (commit message)

**결과**: "ebs v2", "ebs_v2", "version 2" 키워드 commit = **0건**.

### A.5 memory v2 키워드

**결과**: memory grep 결과 = **0건**.

### A.6 Docker 운영 자산 (외부) — 🚨 발견

| 자산 | 상태 | compose project | 분류 |
|------|:----:|:---------------:|:----:|
| `ebs-v2-lobby-web` 컨테이너 | Up 1m (healthy) | `ebs_v2` (외부) | **외부 운영 자산** |
| `ebs-v2-bo` 컨테이너 | Up 1m (healthy) | `ebs_v2` (외부) | **외부 운영 자산** |
| `ebs-v2-engine` 컨테이너 | Up 1m (unhealthy) | `ebs_v2` (외부) | **외부 운영 자산** |
| `ebs-v2-lobby-web:latest` 이미지 | 운영 중 | — | **외부 운영 자산** |
| `ebs-v2-bo:latest` 이미지 | 운영 중 | — | **외부 운영 자산** |
| `ebs-v2-engine:latest` 이미지 | 운영 중 | — | **외부 운영 자산** |

**중대 관찰**:
- 이전 turn (5e80337, 2026-04-27 새벽) 에서 destroy 한 ebs-v2-lobby-web 이 **1분 전 healthy 상태로 부활**.
- ebs-v2-bo / ebs-v2-engine 도 1분 전 시작.
- → 외부 ebs_v2 compose project 가 **활발히 운영 중** (다른 사용자 또는 자동 시스템).
- → 사용자 명시 "ebs v2 = 별개 프로젝트" 와 **정확히 일치** = 본 repo 외부의 별도 프로젝트.

## Phase B — Triage & Selective Integration

### B.1 통합 후보 (Cherry-pick)

**결과**: 통합 후보 = **0건**.
- 본 repo 내부 ebs v2 코드/로직 0건 → 통합할 자산 없음.
- 외부 운영 자산 = 별개 프로젝트, 본 repo 통합 대상 아님 (사용자 명시 "별개 프로젝트").

### B.2 폐기 대상 분류

| 카테고리 | 자산 | 권한 | 결정 |
|----------|------|:----:|------|
| 본 repo 내부 코드/파일 | 0건 | Conductor (Mode A) | 정리 0건 (정리할 것 없음) |
| 본 repo 내부 history references | 6 파일 | Conductor (Mode A) | **보존** (의사결정 추적성, history 가치) |
| 외부 운영 컨테이너 (ebs-v2-*) | 3 컨테이너 | **외부 별개 프로젝트** | **본 repo destroy 권한 없음** |
| 외부 이미지 | 3 이미지 | **외부 별개 프로젝트** | **본 repo destroy 권한 없음** |

## Phase C — Total Purge & Handoff

### C.1 본 repo 내부 정리 결과

**결과**: **destroy 0건**.

이유:
1. 본 repo 내부 ebs v2 관련 코드/파일 = 0건 (audit 결과)
2. v2 키워드 references = history 보존 가치 (B-Q2/B-Q17 등 의사결정 추적)
3. EBS-Skin-Editor_v2.prd.md = "v2" 가 Skin Editor PRD 버전 의미 (별개), archive 보존

### C.2 외부 운영 자산 destroy 보류

**Mode A 한계 (`team-policy.json` v7.1) + Docker_Runtime.md 명시 룰**:

> "기획만 보고 'out-of-scope' 단정 + 파괴적 조치 — 2026-04-22 2차 사건 패턴: '단일 스택' 문구를 운영 요구 (LAN Docker 배포) 고려 없이 문자 해석 → 이미지 완전 삭제. 기획 ↔ 운영 괴리 = Type C. 파괴 전 사용자 확인 필수"

본 turn 에서 사용자 명시 "ebs v2 별개 프로젝트, 폐기" 만 보고 외부 운영 자산 destroy 시 = **2026-04-22 2차 사건 패턴 재발**:
- ebs-v2-* 가 1분 전 부활 = 다른 사용자/시스템 활발 운영
- 사용자 명시 "별개 프로젝트" = 본 repo 외부 = 본 repo 가 destroy 할 권한 없음
- destroy 시 외부 사용자 / 다른 프로젝트 영향, 데이터 손실 위험

**책임감 있는 결정**: 외부 운영 자산 destroy = **사용자 재확인 + 외부 프로젝트 owner 합의 필요**. Conductor Mode A 한계 + 거버넌스 우선.

### C.3 정합성 검증 (Zero-Regression)

본 turn destroy 0건 → 기존 코드/테스트 영향 0 → pytest regression 검증 불필요.
team2-backend baseline = 261 passed (B-Q15 cascade 후) 보존.

## 사용자 결정 (2026-04-27 채택)

| Q | 채택 | 의미 |
|:--:|:----:|------|
| **Q1** | **㉠** | 본 repo 내부만 의미 — 외부 ebs_v2 자산은 별개 프로젝트, 본 repo 와 무관 |
| **Q2** | **㉠** | history references 보존 — 의사결정 추적성 + history 가치 |

→ V2 task **CLOSED**. 외부 ebs_v2 운영 자산은 본 repo 외부 별개 프로젝트로 인정. 본 repo 의 v2 keyword references 6 파일 모두 보존 (B-Q2 Resolution Log, B-Q17 진단, SESSION_1_HANDOFF, web README, docker-compose REMOVED marker, Phase_1_Decision_Queue 등 모두 history 보존).

## V2_PURGE_REPORT 결론

**Phase A (audit)**: ✅ 완료. 본 repo 내부 v2 잔재 = 0건. 외부 운영 자산 = 3 컨테이너 + 3 이미지.

**Phase B (triage)**: ✅ 완료. 통합 후보 0, 폐기 대상 (본 repo 내부) 0.

**Phase C (purge)**: 본 repo 내부 destroy 0건 (정리할 것 없음). 외부 자산 destroy = **사용자 재확인 후** (Mode A 한계 + 거버넌스 우선).

**commit**: 본 V2_PURGE_REPORT.md 만 commit. 사용자 명시 commit message (`chore(legacy): purge ebs v2 artifacts`) 는 **실제 결과와 mismatch** — 정직하게 `chore(audit): V2 audit — 내부 잔재 0건` 으로 변경.

## 참조

- `docs/4. Operations/Conductor_Backlog/SESSION_1_HANDOFF.md` (Session 1 진행)
- `docs/4. Operations/Conductor_Backlog/B-Q2-docker-lobby-web-cleanup.md` (이전 destroy 기록)
- `docs/4. Operations/Conductor_Backlog/B-Q17-engine-healthcheck-fix.md` (engine 진단)
- `docs/4. Operations/Docker_Runtime.md` (운영 SSOT, 2026-04-22 2차 사건 패턴 명시)
- `docs/2. Development/2.5 Shared/team-policy.json` v7.1 `mode_a_limits.destructive_system`
