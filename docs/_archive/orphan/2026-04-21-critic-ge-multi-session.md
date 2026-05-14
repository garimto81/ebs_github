---
title: "Critic — GE 멀티 세션 분리 적합성 (Lobby 탭 종속 전제)"
owner: conductor
tier: internal
last-updated: 2026-04-21
critic-mode: balanced-1-critic + self-rebuttal
relates-to:
  - docs/4. Operations/Reports/2026-04-21-critic-graphic-editor-team5-separation.md
  - docs/4. Operations/Conductor_Backlog/B-076-ge-team5-separation-decision.md
  - docs/3. Change Requests/done/CR-conductor-20260421-ge-scope-expansion.md
confluence-page-id: 3818881588
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818881588/EBS+Critic+GE+Lobby
---

# Critic Report — GE 멀티 세션 분리 적합성

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-21 | 신규 작성 | 사용자 후속 질문 ("Lobby 탭 종속이지만 기능 볼륨 커서 멀티 세션 처리") critic |

---

## 1. 검토 요청

> "lobby 의 탭으로 종속되어 있지만 기능의 볼륨이 커서 멀티 세션으로 처리하는게 좋을거 같은데 critic mode 로 검토"

**선결정 (변경 불가)**: GE owner=team1, 위치=Lobby 탭, scope=BS-08-05/06/07 확장 (B-076 / CR-20260421).

**이번 검토 범위**: 위 결정의 **작업 처리 방식** — 별도 worktree 또는 별도 Claude 세션으로 분리할 것인가.

---

## 2. 핵심 구분 (CRITICAL — 사용자 표현 명확화)

| 차원 | 의미 | 정책 영향 |
|------|------|----------|
| 별도 팀 (team5) | 거버넌스 변경 | 폐기됨 (B-076) |
| **별도 worktree** (`ebs-team1-ge/`) | 물리적 격리 | team-policy 변경 0건 — Workflow v3.0 §Hybrid Support 표준 |
| **별도 Claude 세션** | 동일 worktree 의 두 인스턴스 | active-edits L2 충돌 완화 |
| 별도 브랜치 namespace | `work/team1-ge/<slug>` | 정책 패턴 변경 필요 |

사용자 "멀티 세션" = (b) 또는 (c). 정책 변경 없이 즉시 가능.

---

## 3. 양측 핵심 논거 (balanced-critic 발굴)

### 3.1 찬성 (멀티 세션 분리)

| # | 논거 |
|:-:|------|
| 1 | scope 확장 (DSL parser / schema mapping / plugin interface) 은 team1 다른 작업 (Settings/Quasar/Chip/features) 과 **사고의 결이 다름** |
| 2 | team1 우선 6건 중 (a) skin-editor drafts 5, (b) features 정렬 — 같은 디렉토리 공유로 git 충돌 위험 → 멀티 세션이면 충돌 명시화 |
| 3 | Multi_Session_Workflow v3.0 §Hybrid 가 5 worktree 동시 표준화 — 정책 변경 0건 |
| 4 | `/team` v3.0 매-호출-완결 트랜잭션 모델과 정합 |

### 3.2 반대 (단일 세션 유지)

| # | 논거 |
|:-:|------|
| 1 | **격리 착시 리스크** (Workflow §리스크 1 명시) — Lobby 탭 종속 GE 는 `lib/foundation/router.dart`, `lib/features/lobby/` 와 본질적 결합. worktree 가 git 충돌 회피 안 함 |
| 2 | "기획서 완결 프로토타입" 의도 — 1주 PRD 작업의 worktree setup·해체 비용 > 격리 이득 |
| 3 | **B-077 blocked-by 5 confirm** — 어느 세션이든 동일 stuck. 멀티 세션이 해결 안 함 |
| 4 | Conductor 통합 부담 증가 (team1 worktree 2개) |
| 5 | subdir 모델 + Backlog 우선순위로 직렬화 가능 (Workflow §"세션 자주 재시작 → Subdir") |

---

## 4. 자기반박

**찬성 #3 의 약점**: "정책 호환 = 옳음" 이 아님. Workflow 자체가 §리스크 1·3 으로 worktree 남발 경고. 정책 호환은 필요조건이지 충분조건 아님.

**반대 #2 의 약점**: 사용자가 "기능 볼륨이 커서" 명시 — 1주 PRD 가 아닌 **장기 비전 (Visual Studio급 IDE)** 인식 신호. 1주 ROI 계산은 근시안. 단, 그 비전 자체의 정합성은 별도 critic 영역 (이번 범위 밖).

**격리 착시 vs 명시화**: 반대 #1 의 격리 착시는 사실이지만, 찬성 #2 의 git 충돌 명시화 효과는 부정 안 됨. **공유 자산 (router/foundation) 충돌 + GE 고유 자산 (features/graphic_editor/*) 격리** 의 hybrid 효과 가능 — 이 부분 양측 critic 모두 회피.

---

## 5. 권고 옵션 3종

| Option | 비용 | 이득 | 리스크 | Conductor 권고도 |
|--------|------|------|--------|:-------:|
| 1. 즉시 worktree 분리 (`ebs-team1-ge/`) | 디스크 ×1 + hook bootstrap + 두 세션 동기화 | 인지 격리, GE 고유 자산 git 격리 | 격리 착시 (공유 자산 충돌 동일), B-077 blocked-by 해결 안됨, idle worktree | △ |
| **2. 단계적 — PRD 단일, PoC 시 worktree** | PRD 단계 0, PoC 시점 분리 | 사용자 confirm 5 해소 후 실제 볼륨 확정 시 분리 결정. 조기 over-engineering 회피 | 분리 시점 판단 모호 → 미루다 단일 세션 관성 | ✅ **권고** |
| 3. 단일 세션 유지 (Lobby ↔ GE 본질 결합 인정) | 0 | subdir + Backlog 우선순위로 직렬화 | team1 6 우선 + GE 확장 동시 진행 시 컨텍스트 스위칭 부담, skin-editor/features 정렬과 충돌 | △ |

---

## 6. Conductor 종합 판정 — Option 2 (조건부)

**근거**:
1. balanced-critic 권고와 일치
2. B-077 5 blocked-by 가 본질적 stuck 요인 — 분리해도 해결 안 됨
3. PRD 단계 (3 .md 작성) 는 단일 세션이 명세 일관성·교차 참조에 유리
4. PoC 구현 단계 진입 시 — 즉 "DSL parser/schema mapping 이 1주+ 코드 작업" 확정될 때 — worktree 의 격리 효익 명확

**Option 2 의 약점 보강 (자기반박 #1 대응)**:
PoC 진입 트리거를 **명시적으로 정의** 해야 미루기 방지:

| 트리거 조건 | worktree 분리 여부 |
|-------------|:------------------:|
| BS-08-05/06/07 PRD 작성 단계 | ❌ 단일 세션 (현행 Conductor 또는 team1 subdir) |
| 사용자 confirm 5 해소 후 PoC 코드 1 파일 추가 | ❌ 아직 단일 세션 |
| GE 코드 작업이 `lib/features/graphic_editor/` 5+ 파일 동시 편집 추정 | ✅ worktree 신설 (`ebs-team1-ge/`) |
| GE PoC 가 trigger DSL parser 본격 구현 (예: lexer + parser + AST) | ✅ worktree 신설 |
| team1 다른 우선 작업 (Settings 5탭, Quasar 정리) 과 동시 진행 필요 | ✅ worktree 신설 |

**즉시 실행 액션**:
- `team5-graphic_editor/` 빈 디렉토리 처분 (B-076 BLOCKED 항목 해소 — 사용자 confirm 후 삭제 권고)
- B-077 frontmatter 에 "PoC 진입 시 worktree 재평가" 메모 추가
- Conductor_Backlog 에 PoC 진입 게이트 항목 신설

---

## 7. 사용자 confirm 필요 (auto mode 한계)

worktree 분리는 사용자 작업 환경 결정이므로 auto 채택 불가. 다음 응답 필요:

1. **Option 1/2/3 선택** — Conductor 권고는 Option 2
2. (Option 2 채택 시) **PoC 진입 트리거** 위 5개 중 어떤 것을 자동 분리 신호로 합의?
3. (Option 1 즉시 분리 시) `ebs-team1-ge/` worktree 신설 위치 — 기본 sibling-dir 채택 OK?
4. **`team5-graphic_editor/` 처분** — 즉시 삭제 OK? (`.claude/` junction + `.gitignore` 만, 손실 0)
