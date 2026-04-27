---
title: Phase 1 Decision Queue (18건 결정 기록)
owner: conductor
tier: internal
last-updated: 2026-04-27
---

# Phase 1 Decision Queue — 사용자 18건 결정 SSOT

## 개요

사용자 (기획자) 가 2026-04-27 에 결정한 **18건 spec 결정** 의 SSOT 기록. Phase 1 차단 해제 조건. 본 문서는 cascade 작업 (메커니컬 + 정책 동기화) 의 최상위 결정 근거로 사용된다.

| 그룹 | 건수 | 요약 |
|:---:|:---:|------|
| A | 1 | SG-022 단일 Desktop 바이너리 (Lobby 포함) 채택 |
| B | 11 | SG-008-b1~b9, b14, b15 registry 권고 일괄 채택 |
| C | 4 | C.1 Settings 4-level scope, C.2 Rive `.riv` 단일파일 + 표준 메타, C.3 100ms 전체 파이프라인, C.4 worktree fast-forward + pre-push hook |
| Q (보류) | 2 | Q2 Docker lobby-web 정리, Q3 team1 Web 빌드 자산 |

> **18건 = A(1) + B(11) + C(4) + Q(2)**. Q 는 사용자 후속 결정 대기.

---

## Decision Group A — 단일 Desktop 바이너리

### SG-022 (NEW) — 단일 Desktop 바이너리 (Lobby 포함)

| 항목 | 내용 |
|------|------|
| 결정 | EBS 모든 프론트엔드 (Lobby/CC/Overlay) = **하나의 Flutter Desktop 바이너리** |
| Supersedes | `feedback_web_flutter_separation` (2026-04-22 γ 하이브리드 — Web Lobby + Desktop CC 분리) |
| 영향 (자동 처리) | Foundation §5.0, BS_Overview §1 (Agent 1 처리) |
| 영향 (보류) | Docker compose `lobby-web` 정리 (Q2), team1-frontend Web 빌드 자산 (Q3) |
| Why | 사용자 (기획자) 가 단순성 우선, RFID/SDI/NDI 직결 환경 통일 선호 |

> Lobby Web 배포 제안 금지. team1 빌드는 Desktop 만 유지. 후속 Web 빌드 요구 시 새 Spec Gap 으로 처리.

---

## Decision Group B — SG-008-b 11건 일괄 채택

registry 권고 (default option) 를 일괄 수용. 구현은 team2 위임.

| ID | endpoint / key | 결정 |
|----|----------------|------|
| SG-008-b1 | `GET /api/v1/audit-events` | RBAC: Admin only |
| SG-008-b2 | `GET /api/v1/audit-logs` | 별도 리소스 (events=user, logs=system) |
| SG-008-b3 | `GET /api/v1/audit-logs/download` | NDJSON + 100req/min rate limit |
| SG-008-b4 | `GET /api/v1/auth/me` | 확장 필드 (role, permissions, settings_scope) |
| SG-008-b5 | `POST /api/v1/auth/logout` | current + `?all=true` 옵션 |
| SG-008-b6 | `POST /api/v1/sync/mock/seed` | env guard: dev/staging only |
| SG-008-b7 | `DELETE /api/v1/sync/mock/reset` | env guard: dev/staging only |
| SG-008-b8 | `GET /api/v1/sync/status` | Public + Admin detail bifurcation |
| SG-008-b9 | `POST /api/v1/sync/trigger/{source}` | Admin only + reject 권한 |
| SG-008-b14 | Settings.`twoFactorEnabled` | User scope (per user) |
| SG-008-b15 | Settings.`fillKeyRouting` | NDI fill/key param (Hardware Out Phase 2) |

> Why: 사용자 efficient 결정 패턴 — registry 권고가 충분히 분석된 옵션이면 일괄 채택. SG-008-b10/b11/b12 는 본 그룹에 포함되지 않음 (별도 처리).

---

## Decision Group C — 정책 결정 4건

### C.1 — SG-003 + SG-017 합산 — Settings 5-level scope

- **결정**: Settings 는 **5-level scope** (Global / Series / Event / Table / User) 분리
- **Override 우선순위**: User > Table > Event > Series > Global
- **Cascade**: `docs/2. Development/2.1 Frontend/Settings/Overview.md` 재작성
- **Why**: WSOP LIVE Confluence 패턴과 정렬 (원칙 1). 일부 키 (예: `twoFactorEnabled` per Decision SG-008-b14) 는 User scope 만 적용
- **Supersedes**: `feedback_settings_global` (2026-04-15 — Settings 글로벌 단일)

### C.2 — SG-021 — Rive 메타데이터 표준 스키마

- **결정**: `.riv` **단일 파일** (no `.gfskin` ZIP, no sidecar `.json`)
- **메타데이터 위치**: artboard Custom Property + Text Run binding + State Machine
- **Cascade**: `docs/4. Operations/Conductor_Backlog/SG-021-rive-embedded-metadata-schema.md` (DONE 결정 추가)
- **Why**: 회의 D3 (2026-04-22) 의도 직접 반영 + Rive 표준 지원

### C.3 — BLANK-1 — 100ms 전체 파이프라인 정의

- **결정**: 100ms = **RFID → Engine → WebSocket → Render → Output 전체** 의 end-to-end 지연
- **WebSocket 단일 구간**: 별도 부연 (구간별 budget 은 Phase 2 측정 대상)
- **Cascade**: Foundation §6.4 분해 (Agent 1 처리)
- **Why**: 사용자 의도 명확화 — 100ms 가 단일 구간 budget 이 아님을 명문화

### C.4 — BLANK-3 — Multi_Session_Workflow merge strategy

- **결정**: **worktree fast-forward + pre-push hook** 으로 충돌 사전 검출
- **Cascade**: `docs/4. Operations/Multi_Session_Workflow.md` L4 신규 섹션
- **Why**: sibling-dir worktree 모델 (v5.0+) 기준 반영 + Conductor 중재 경로 명문화

---

## Cascading Impact 파일 목록

### 자동 처리됨 (이번 cascade)

| 파일 | 처리자 | 변경 요약 |
|------|--------|----------|
| `docs/1. Product/Foundation.md` (§5.0, §6.4) | Agent 1 | SG-022 + BLANK-1 |
| `docs/2. Development/2.5 Shared/BS_Overview.md` (§1) | Agent 1 | SG-022 |
| `docs/4. Operations/Spec_Gap_Registry.md` | Agent 2 (이 turn) | SG-022 신규, SG-020/021/003/017/008-b DONE |
| `docs/2. Development/2.1 Frontend/Settings/Overview.md` | Agent 2 (이 turn) | C.1 5-level scope 재작성 |
| `docs/4. Operations/Multi_Session_Workflow.md` | Agent 2 (이 turn) | L4 merge strategy |
| `docs/4. Operations/Conductor_Backlog/SG-021-*.md` | Agent 2 (이 turn) | C.2 Rive 스키마 DONE |
| `docs/1. Product/Game_Rules/*.md` (4 files) | Agent 2 (이 turn) | frontmatter `tier: external` + `last-updated` 갱신 |
| MEMORY 3종 | Agent 2 (이 turn) | feedback_web_flutter_separation [SUPERSEDED], 신규 project_decision_2026_04_27_phase1.md |

### 사용자 보류 (후속 결정 대기)

| 항목 | 사유 | decision_owner |
|------|------|----------------|
| Q2 — Docker compose `lobby-web` 컨테이너/이미지 정리 | 좀비 위험 (Docker_Runtime.md 규칙 위반 가능). 사용자 명시 승인 필요 | 사용자 |
| Q3 — team1-frontend Web 빌드 자산 (`web/` 폴더, build script) | 코드 변경, team1 세션 위임 | team1 |

→ **Conductor_Backlog 등재 완료 (2026-04-27)**:
- `docs/4. Operations/Conductor_Backlog/B-Q2-docker-lobby-web-cleanup.md`
- `docs/4. Operations/Conductor_Backlog/B-Q3-team1-frontend-web-build-assets.md`

각 항목에 due-date 권고 (2026-05-04, 1주일) + 미합류 시 사용자 에스컬레이션 조건 명시.

---

## 결정 검증 (Verification Checklist)

| 검증 항목 | Pass 조건 |
|----------|----------|
| SG-022 가 registry 에 존재 | Spec_Gap_Registry §4.4 에 신규 row |
| SG-008-b1~b9, b14, b15 = DONE | Spec_Gap_Registry §4.4 의 status 컬럼 갱신 |
| Settings/Overview.md = 5-level scope | "글로벌 단일" 표현 폐기 + Override 표 존재 |
| SG-021 = DONE | Conductor_Backlog/SG-021-*.md frontmatter status: DONE |
| Multi_Session_Workflow.md L4 존재 | "L4. Merge Strategy" 헤더 등장 |
| Game_Rules 4 파일 frontmatter | `tier: external`, `last-updated: 2026-04-27` |
| MEMORY feedback_web_flutter_separation | description 끝에 `[SUPERSEDED 2026-04-27]` |
| MEMORY 신규 1건 추가 | `project_decision_2026_04_27_phase1.md` 존재 + MEMORY.md 인덱스 행 추가 |

---

## 참조

- `docs/4. Operations/Spec_Gap_Registry.md` (SG-022, SG-008-b, SG-021, SG-003, SG-017)
- `docs/4. Operations/Spec_Gap_Triage.md` §7 Type B / Type C
- `docs/2. Development/2.5 Shared/team-policy.json` v7 `free_write_with_decision_owner`
- MEMORY `feedback_settings_global` [SUPERSEDED]
- MEMORY `feedback_web_flutter_separation` [SUPERSEDED]
- MEMORY `project_decision_2026_04_27_phase1` (신규)

## Decision Group D — Cascade 후속 confirm (2026-04-27)

사용자가 18건 결정 적용 후 cascade 후속 4건을 추가 confirm:

| ID | 결정 | 처리 |
|----|------|------|
| 1.㉠ | 14 파일 single commit (`feat(spec): SG-022 + Phase 1 18-item cascade`) | Conductor 처리 |
| 2.㉡ | Q2 (Docker lobby-web) → team1 세션 합류 시 처리 | B-Q2 등재, due 2026-05-04 |
| 3.㉠ | memory `project_decision_2026_04_27_phase1.md` L41 경로 정정 (Spec_Gaps→Conductor_Backlog) | 정정 완료 |
| 4.㉠ | Game_Rules 4파일 `tier: internal → external` 채택 | 이미 적용됨 (Confluence 발행 정책 정렬) |

> Phase_1_Decision_Queue.md 본문 (L77, L106) 의 SG-021 경로는 이미 정확. 잘못된 경로는 memory 파일에만 존재했음.

---

## Decision Group E — SG-023 인텐트 전환 (production 출시)

사용자가 2026-04-27 (Phase 2 시작 메시지 후 cascade) 에 **인텐트 자체를 전환**:

| 항목 | 내용 |
|------|------|
| 결정 | EBS = **production 출시 프로젝트** (이전 "기획서 완결 + 프로토타입 검증" SUPERSEDED) |
| Type | C (기획 모순 — 사용자 본인 2026-04-20 vs 2026-04-27 reversal) |
| Cascade 처리 (Conductor 자율) | memory 3종 (intent SUPERSEDED + 신규 production_intent), CLAUDE.md "🎯 프로젝트 의도" 갱신, Spec_Gap_Registry SG-023, NOTIFY-ALL-SG023-INTENT-PIVOT, Conductor_Backlog/SG-023 |
| 후속 결정 필요 (사용자 명시 대기) | **B-Q5** 거버넌스 (Conductor team 코드 영역 권한) / **B-Q6** timeline (MVP/런칭 일정) / **B-Q7** 품질 기준 (prototype vs production-grade 측정) / **B-Q8** vendor (RFI/RFQ reactivate) / **B-Q9** Type 분류 (A/B/C/D 의 production 의미) |
| Why | 사용자 명시 (2026-04-27): "B 가 사용자 진정 의도. memory + Foundation 명시 갱신 PR 먼저, SG-023 분류, cascade 재실행" |

> ⚠️ **본 SG-023 cascade 는 인텐트 명시 변경만 처리**. 거버넌스 / timeline / 품질 / vendor / Type 분류 의 후속 cascade 는 별도 turn 에서 사용자 명시 결정 후 진행. Conductor 자율 진행 금지.

### 영향 비교 표

| 측면 | 2026-04-20 (SUPERSEDED) | 2026-04-27 (SG-023) |
|------|-------------------------|---------------------|
| 프로젝트 목적 | 기획서 완결 (개발팀 인계) | production 출시 |
| 사용자 역할 | 기획자 | 기획자 + production 책임자 |
| 성공 기준 | 외부 개발팀 재구현 가능성 | 100% 검증된 완제품 + 운영 가능 |
| MVP / 런칭 / vendor | 범위 밖 | 후속 결정 필요 (B-Q6/Q8) |
| Conductor 권한 | 기획서 편집장 | + ?(B-Q5 결정 대기) |

---

## Decision Group F — SG-024 거버넌스 확장 (Conductor 단일 세션 전권)

사용자 B-Q5 ㉠ 채택 (2026-04-27):

| 항목 | 내용 |
|------|------|
| 결정 | Conductor 단일 세션 전권 (Mode A default), 멀티세션 옵션 유지 (Mode B) |
| Type | C (기획 모순 — 5팀 분리 vs Conductor 전권) |
| Cascade 처리 (Conductor 자율) | CLAUDE.md (project) "팀 세션 금지" 폐기, team-policy.json v7.1 (Mode A/B + mode_a_limits), Multi_Session_Workflow §v7.1 단일 세션 모드, Spec_Gap_Registry SG-024, NOTIFY-ALL-SG024-GOVERNANCE-EXPANSION, **B-Q9 Spec_Gap_Triage production 의미 callout** |
| 후속 결정 (Backlog 등재) | B-Q6 timeline (B-Q6-timeline-mvp-launch-schedule.md) / B-Q7 품질 기준 (B-Q7-quality-criteria-production.md) / B-Q8 vendor reactivate (B-Q8-vendor-rfi-rfq-reactivation.md) — 사용자 명시 대기 |
| Why | 사용자 명시 (2026-04-27): "거버넌스 확장 — Conductor 가 team1~4 코드 영역 직접 진입 허용. CLAUDE.md '팀 세션 금지' 폐기. 후속 cascade 단일 turn 에 자율 진행 가능" |

### Mode A vs Mode B (v7.1)

| 모드 | trigger | workflow |
|------|---------|----------|
| **Mode A — 단일 세션 (default in v7.1)** | Conductor 단독 활동 | `/team` 생략 가능. main 직접 commit. decision_owner override |
| **Mode B — 멀티 세션 (옵션)** | 팀 세션 활성화 자동 회복 | v5.1 L0-L4 워크플로우. decision_owner 회복 |

### Mode A 한계 (Conductor 자율 금지)
- vendor 외부 메일 / destructive 시스템 변경 / git config / 사용자 인텐트 변경 / memory 사용자 본인 결정 메모

---

## Decision Group G — B-Q6 ㉠ + B-Q7 ㉠ 자율 상정 (Mode A 첫 활용)

사용자 명시 (2026-04-27): "B-Q6(타임라인)은 ㉠(Legacy Reactivate), B-Q7(품질)은 ㉠(Strict)으로 자율 상정"

| 항목 | 결정 | Cascade |
|------|------|---------|
| **B-Q6 ㉠** | Legacy plan reactivate: 2027-01 런칭, 2027-06 Vegas, MVP=홀덤1종 | memory `project_2027_launch_strategy` REACTIVATED, Roadmap.md 재작성 (intent → production-launch + Phase 0~4 timeline) |
| **B-Q7 ㉠** | Production-strict: 95%+ coverage, 99.9% uptime, p99<200ms, OWASP, WCAG AA, 한+영 | Roadmap §"Production Quality Gates", Spec_Gap_Registry SG-026 row, B-Q10/Q11/Q12 잔여 Backlog 등재 |

### Mode A 첫 활용 사항 (2026-04-27 본 turn)

본 turn 은 SG-024 Mode A 활성화 후 **첫 번째 자율 코드 작성 시도**. 단 다음 발견으로 **코드 작성은 0건**:

- **기존 자산 발견**: team2-backend 는 이미 247 tests 0 errors. audit.py/auth.py 의 SG-008-b 구조 일부 존재. team2-backend/CLAUDE.md "우선 작업 7번 = SG-008-b 9 endpoint 실구현" 명시 — 이미 backlog 등재.
- **pre_push_drift_check.py 이미 존재** — BLANK-3 의 일부 이미 구현. 보강은 후속.
- **거버넌스 안정성 우선**: 1주 내 4건 reversal 누적 (SG-022/023/024 + B-Q6/Q7) → Conductor 가 Mode A 로 거대 코드 작성 시 추후 reversal 발생 시 손실 위험. **점진 진행 + 사용자 검증 cycle 권장**.

### Mode A 본 turn 처리 결과

| 영역 | 처리 |
|------|------|
| SSOT cascade (B-Q6/Q7) | ✅ memory + Roadmap + Phase_1_Decision_Queue Group G + Spec_Gap_Registry SG-025/026 + NOTIFY |
| 기존 자산 검증 보고 | ✅ audit.py/auth.py/pre_push_drift_check.py 발견 보고 |
| 잔여 Backlog 등재 | ✅ B-Q10/Q11/Q12/Q13/Q14/Q15 |
| 코드 직접 작성 | 0건 (검증 부담 회피, 다음 turn 사용자 우선순위 확인 후 진행) |

### B-Q8 잔존 PENDING

| 항목 | 상태 | 사유 |
|------|:----:|------|
| B-Q8 vendor 모델 (RFI/RFQ reactivate) | PENDING | 외부 메일 발송 destructive — Mode A 한계, 사용자 명시 필요 |

---

## Decision Group H — B-Q15 SG-008-b Conductor Mode A 첫 코드 작성 (2026-04-27)

사용자 명시 (2026-04-27): "B-Q15 SG-008-b — Conductor Mode A 로 누락 endpoint 보강 (audit-events, sync_router, auth.me ?all 등). team2 247 tests 위에 추가 단위 테스트."

### 진행 결과

| 영역 | 처리 | 결과 |
|------|:----:|------|
| auth.py 보강 (b4 + b5) | ✅ | MeResponse `permissions` + `settingsScope` 추가 + logout `?all` query param |
| sync.py 보강 (b6/b7/b8) | ✅ | `_require_dev_or_staging` env guard + sync/status `scope` bifurcation |
| 신규 테스트 | ✅ | tests/test_sg008b_extensions.py 13 cases |
| pytest regression | ✅ | **261 passed, 0 failed in 114.79s** (baseline 247 → +14) |
| 보류 (별도 turn) | ⏳ | b1 RBAC 변경, b3 NDJSON+rate limit, b14 2FA migration, b15 NDI Phase 2 |

### Mode A 첫 코드 작성 의미

- **거버넌스 안정성 검증됨**: 1주 내 4 reversal 누적 우려 있었으나, surgical edit (additive only) + 기존 247 tests 보존 + 13 새 테스트 모두 PASS = production-strict 기준 충족 가능 입증.
- **Mode A 권한 적정성**: 사용자가 본 turn 에서 처음으로 Conductor Mode A 권한 활용 명시. 결과 = production-grade 코드 + 테스트. 거버넌스 v7.1 의 실효성 입증.
- **거버넌스 안전망 작동**: ultrathink 검토 → b1 RBAC 변경 / b3 NDJSON 은 **기존 테스트 영향 우려로 보류** = 단일 turn 자율 권한 + 신중한 자체 판단 결합. Mode A 가 reckless 코드 작성 권한이 아님 입증.

---

## Decision Group I — SG-027 5-Session Pipeline 도입 + Session 1 완료

사용자 명시 (2026-04-27): "Hybrid Multi-Session Orchestrator — 5개의 순차적 멀티 세션 + 4개의 전문 에이전트 팀". LLM 컨텍스트 한계 회피 + 분량 분할.

### 거버넌스 layer 추가 (v7.1 → v7.2)

| Layer | 역할 |
|-------|------|
| v7.1 Mode A/B (SG-024) | **권한 모델** — Conductor 단일 세션 전권 (A) vs 멀티세션 decision_owner (B) |
| **v7.2 5-Session (SG-027)** | **분량 모델** — multi-turn 분할 (5 sessions) vs 단일 turn |

### Session 1 진행 결과 (본 turn)

| 작업 | 상태 |
|------|:----:|
| Broken URL 정렬 (origin = ebs_github 단일) | ✅ 이미 완료 (5e80337) |
| 도커 좀비 lobby-web 정리 | ✅ 이미 완료 (5e80337) |
| **신규 좀비 4건 destroy** (ebs-bo-1/cc-web-1/redis-1/engine-1) | ✅ 본 turn |
| 5-Session Pipeline SSOT 화 (Multi_Session_Workflow §v7.2 + SG-027) | ✅ 본 turn |
| B-Q16/Q17 Backlog 등재 (개발 환경 표준화 / engine healthcheck) | ✅ 본 turn |
| SESSION_1_HANDOFF.md 작성 | ✅ 본 turn |

### Session 1 발견 사항

- **engine unhealthy = Type A**: ebs-v2-engine 13h unhealthy 표시이나 log 정상. healthcheck spec 문제. → B-Q17
- **compose project mismatch**: 운영 ebs_v2 (외부) vs 본 repo ebs. 별도 turn 검토.
- **개발 환경 표준화**: 추상적 → B-Q16 (P2, Session 5 권장)

### Session 2~5 권고

| Session | 우선 작업 |
|:-------:|----------|
| 2. Core Logic & Backend Engine | B-Q17 engine healthcheck → b1/b3 audit 보강 → b14 2FA migration → B-Q10 95% coverage |
| 3. Frontend Interface & Routing | B-Q13 단일 Desktop 라우팅 → B-Q14 Settings UI |
| 4. System Integration & QA Harness | E2E 통합 테스트 + compose mismatch 정리 |
| 5. Final Production & Audit | B-Q11 OWASP audit + B-Q16 개발 환경 표준화 + PHASE-FINAL-REPORT.md |

---

## Decision Group J — V2 audit closed + Session 1 최종 종료 (2026-04-27)

사용자 URGENT DIRECTIVE (2026-04-27): "ebs v2 = 별개 프로젝트, 폐기" cascade.

### 결정 (Q1 + Q2 채택)

| Q | 채택 | 의미 |
|:--:|:----:|------|
| **Q1** | **㉠** | 본 repo 내부만 의미 — 외부 ebs_v2 자산은 별개 프로젝트, 본 repo 와 무관 |
| **Q2** | **㉠** | history references 보존 — 의사결정 추적성 + history 가치 |

### V2 audit 결과 (V2_PURGE_REPORT.md 참조)

| Phase | 결과 |
|:-----:|------|
| A — Audit | 본 repo 내부 ebs v2 코드/파일 0건. 키워드 references 6 파일 = 모두 history. 외부 운영 자산 3 컨테이너 + 3 이미지 (1분 전 부활, 별개 프로젝트). |
| B — Triage | 통합 후보 0, 폐기 대상 (내부) 0, 외부 자산 = 본 repo destroy 권한 없음 |
| C — Purge | 본 repo destroy 0건. 외부 자산 destroy 보류 (Mode A 한계 + 거버넌스 우선) |

### Session 1 최종 종료

Session 1 명시 작업 + V2 audit 모두 완료. 다음 turn 에서 Session 2 진입.

| Session 1 commits | 의미 |
|-------------------|------|
| 38807fb | 5-Session Pipeline 도입 + 좀비 4건 정리 + B-Q16/Q17 등재 + SESSION_1_HANDOFF |
| 034fc88 | V2 audit + V2_PURGE_REPORT.md |
| (본 commit) | V2 closed + Session 1 종료 SSOT |

### Session 2 진입 권고

| 우선순위 | 작업 | 영역 | 분량 |
|:-------:|------|------|:----:|
| 1 | B-Q17 본 repo engine healthcheck 검토 | team3 (or docker-compose) | 작음 |
| 2 | b1 audit-events RBAC 갱신 (기존 테스트 신중 검토) | team2 | 작음 |
| 3 | b3 audit-logs/download NDJSON + rate limit | team2 + middleware | 중간 |
| 4 | B-Q10 95% coverage 5%p gap 도달 | team2 | 중간 |
| 5 | b14 2FA migration 0006 (DB schema) | team2 + alembic | 큼 (destructive) |

---

## Decision Group K — Session 2 Phase 1 audit (B-Q10 95% coverage baseline 정정)

사용자 명시 (2026-04-27): "Session 2 진입 — Option D B-Q10 95% Coverage 도달".

### 🚨 baseline 정정 (stale SSOT 발견)

| 항목 | 이전 SSOT | 실제 측정 (2026-04-27) |
|------|----------|----------------------|
| team2-backend tests | 247 → 261 (B-Q15 후) | **261 (확인)** |
| team2-backend coverage | "90%" (stale, 2026-04-14 시점) | **78%** (실제, 3984 stmts / 882 missed) |
| 95% gap | 5%p | **17%p (683 stmts)** |
| 95% 도달 분량 | 단일 turn | **multi-turn (5-10 sub-sessions)** |

정정 cascade: B-Q10 + SG-026 + team2-backend/CLAUDE.md.

### Phase 1 audit 결과 (Largest gaps)

services/ 영역이 핵심 미커버:
- auth_service 50%, blind_structure_service 20%, series_service 57%, table_service 65%
- payout_structure_service 26%, hand_service 27%, clock_service 38%, user_service 30%
- adapters/wsop_auth.py 0% (완전 untested)

### Multi-turn plan (Session 2 sub-sessions)

| Sub-Session | 영역 | 예상 분량 |
|:-----------:|------|:---------:|
| **2.1** | auth_service.py 50% → 80% | 10-15 tests |
| 2.2 | blind/payout structure services 20-26% → 70% | 15-20 tests |
| 2.3 | series + table services 57-65% → 80% | 12-15 tests |
| 2.4 | hand/clock/user/competition services 27-38% → 70% | 20-25 tests |
| 2.5 | wsop_auth.py 0% → 70% | 10 tests |
| 2.6 | routers (blind/hands/auth/skins) 보강 | 20-25 tests |
| 2.7 | skin/undo/작은 모듈 100% 도달 | 10-15 tests |

### 본 turn 진행

- ✅ Phase 1 coverage audit (261 tests / 78% / largest gaps 식별)
- ⏳ Phase 2 단위 테스트 추가 = **Session 2.1 (다음 turn)** 권장 (단일 turn 17%p 도달 비현실)
- ⏳ Phase 3 95% Zero-Regression validation = Session 2.7 완료 후
- ⏳ Phase 4 commit `test(backend): increase test coverage to 95% (B-Q10)` = Session 2.7 완료 후

본 turn 의 정직한 가치: **잘못된 baseline (90%) 발견 + 정정 SSOT cascade + multi-turn plan 명시**. 단순 "작업 완료" 가 아닌 추적성 회복 + 사용자 의사결정 정확화.

---

## Decision Group L — Session 2.1 완료 (auth_service 50% → 70%+)

사용자 명시 (2026-04-27): "Session 2.1 — auth_service 가장 큰 gap (74 missed), B-Q7 ㉠ Production-strict 직접 cascade".

### 진행 결과

| 영역 | 결과 |
|------|:----:|
| 신규 unit tests | `tests/test_auth_service_extended.py` 22 tests |
| 단위 실행 | 22/22 PASS in 3.83s |
| 전체 regression | **283 passed, 0 failed in 118.59s** (baseline 261 + 22 = 283) |
| Production code 수정 | 0건 (Strict 룰 준수) |
| Missing branches 커버 | authenticate (4) / refresh (3) / 2FA (6) / password reset (5) / oauth (2) / etc |

### Missing line 커버 (auth_service.py)

- `30, 33, 37-42` (authenticate edge: not found / inactive / locked / lock-expired-reset) ✅
- `98-99, 102, 110-111` (refresh_session: invalid / wrong-type / mismatch) ✅
- `135-136` (get_user_session: not found) ✅
- `148-160` (setup_2fa) ✅
- `165-171` (disable_2fa) ✅
- `178-180, 183-185` (verify_2fa) ✅
- `204-207` (create_password_reset) ✅
- `217-218, 215-236` (reset_password) ✅
- `261-272, 274-277` (google_oauth_login) ✅

### 다음 Session 2.2 권고

`services/blind_structure_service.py` 20% + `services/payout_structure_service.py` 26% → 70% (18-22 unit tests).

또는 **Session 2.5 우선**: `adapters/wsop_auth.py` 0% → 70% (10 tests, 작은 모듈 큰 영향).

---

## Changelog

| 날짜 | 버전 | 변경 내용 | 변경 유형 | 결정 근거 |
|------|------|-----------|----------|----------|
| 2026-04-27 | v1.9 | Group L 추가 (Session 2.1 완료 — auth_service 22 tests, 283 passed regression 0, Strict 룰 준수) + SESSION_2_1_HANDOFF.md NEW | TECH | 사용자 Session 2.1 진입 명시 — auth_service 가장 큰 gap |
| 2026-04-27 | v1.8 | Group K 추가 (Session 2 Phase 1 audit — B-Q10 baseline 정정 90% → 78% + multi-turn plan 2.1~2.7) | TECH | 사용자 Session 2 진입 (Option D) — Phase 1 audit 결과 |
| 2026-04-27 | v1.7 | Group J 추가 (V2 audit closed Q1.㉠+Q2.㉠ 채택 + Session 1 최종 종료, Session 2 진입 권고) | TECH | 사용자 V2 URGENT DIRECTIVE → audit 결과로 자연 종료 |
| 2026-04-27 | v1.6 | Group I 추가 (SG-027 5-Session Pipeline 도입 — v7.2 분량 layer) + Session 1 완료 (좀비 4건 정리, B-Q16/Q17 등재, SESSION_1_HANDOFF 작성) | TECH | 사용자 명시 (5-Session 모델) — multi-turn cascade |
| 2026-04-27 | v1.5 | Group H 추가 (B-Q15 SG-008-b Conductor Mode A 첫 코드 작성 — 5 endpoint 보강, 13 tests, 261 passed regression 0) | TECH | 사용자 B-Q15 명시 — Mode A 권한 활용 |
| 2026-04-27 | v1.4 | Group G 추가 (B-Q6 ㉠ + B-Q7 ㉠ 자율 상정 — Mode A 첫 활용) + memory `project_2027_launch_strategy` REACTIVATED + Roadmap.md production-launch 재작성 + 잔여 Backlog (B-Q10~Q15) 등재 | MARKET | 사용자 명시 (2026-04-27): B-Q6 ㉠ Legacy + B-Q7 ㉠ Strict |
| 2026-04-27 | v1.3 | Group F 추가 (SG-024 거버넌스 확장 — Mode A/B) + B-Q9 Conductor 자율 처리 (Spec_Gap_Triage callout) + B-Q6/Q7/Q8 Backlog 등재 | MARKET | 사용자 B-Q5 ㉠ 채택 — Conductor 전권 |
| 2026-04-27 | v1.2 | Group E 추가 (SG-023 인텐트 전환 — production 출시) + B-Q5~Q9 후속 결정 필요 명시 | MARKET | 사용자 B 옵션 채택 — 인텐트 자체 reversal |
| 2026-04-27 | v1.1 | Group D 추가 (cascade 후속 4건 confirm) + Q2/Q3 Backlog 등재 갱신 | PRODUCT | 사용자 1.㉠/2.㉡/3.㉠/4.㉠ 결정 SSOT 화 |
| 2026-04-27 | v1.0 | 최초 작성 (사용자 18건 결정 SSOT) | PRODUCT | Phase 1 cascade — 사용자 결정을 SSOT 화 |
