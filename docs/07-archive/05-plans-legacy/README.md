# 05-plans-legacy — 구식 Plan 문서 아카이브

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 아카이빙 | 5팀 구조(v4.0.0) 전환으로 구식 참조 포함 plan 3개 이동 |

## 아카이빙 사유

아래 plan 문서들은 **Phase 9 레포 통합**(commit `b0e57c8`)과 **5팀 구조 전환**(CLAUDE.md v4.0.0, 2026-04-10) 이전의 아키텍처를 기준으로 작성되었다. 현재 유효한 참조 경로·레포 구조·팀 할당과 맞지 않아 활성 `docs/05-plans/`에서 제외하고 역사적 기록으로 보존한다.

| 파일 | 구식 참조 내용 |
|------|---------------|
| `ebs-implementation-roadmap.plan.md` | `ebs_ui\ebs-console\`, `ebs_ui\ebs-action-tracker\`를 live 경로로 참조. 현재는 `team1-frontend/ui-design/reference/console/` 및 `team4-cc/ui-design/reference/action-tracker/`에 통합됨. |
| `QA-EBS-Master-Plan.md` | `ebs_reverse (역설계)`를 active testing authority로 명시. 현재 `ebs_reverse`는 `docs/07-archive/legacy-repos/ebs_reverse/`에 아카이빙됨. QA는 `team1~4/qa/`로 분산. |
| `ebs-lobby-12items.plan.md` | `ebs_shared` / `ebs_server` / `ebs_lobby_web` / `ebs_app` 4-레포 sibling 구조 전제. 현재는 단일 레포 내 `team1-frontend/`, `team2-backend/`, `team3-engine/`, `team4-cc/`로 통합됨. |

## 재활용 지침

이 문서들은 **그대로 실행해서는 안 된다**. 다음 경우에만 참고한다:

1. 과거 설계 의도/맥락 복원 (why 추적)
2. 기능 스코프 역참조 (어떤 항목이 어느 단계에서 고려되었는지)
3. 5팀 구조 신규 plan 작성 시 누락 항목 대조

신규 plan은 CLAUDE.md v4.0.0의 5팀 구조 및 `contracts/` 계약 경로를 따라 `docs/05-plans/`에 작성한다.

## 관련 문서

| 문서 | 경로 |
|------|------|
| Conductor CLAUDE.md | `C:\claude\ebs\CLAUDE.md` |
| Foundation PRD (현행) | `docs/01-strategy/PRD-EBS_Foundation.md` |
| 통합 commit | `git show b0e57c8` (Phase 9 consolidate) |
| 5팀 구조 commit | `git show 347be60` (React → Quasar tech stack 명시) |
