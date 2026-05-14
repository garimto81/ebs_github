---
title: Phase 1 설계 정렬 완료 — Phase 2 진입 허용 (전체 팀 broadcast)
owner: conductor
tier: internal
type: notify-broadcast
recipients: [team1, team2, team3, team4]
broadcast-date: 2026-04-27
linked-sg: SG-022
linked-commit: f0ec249
status: ACTIVE
last-updated: 2026-04-27
confluence-page-id: 3819242133
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819242133/EBS+Phase+1+Phase+2+broadcast
---

## 공식 선언

> **Phase 1 설계 정렬 완료.** 모든 개발팀은 확정된 SSOT (`f0ec249` `feat(spec): SG-022 + Phase 1 18-item cascade` 기준) 에 의거하여 **코딩 세션 진입을 허용함**. 단, 구현 중 기획 충돌 발생 시 **Phase 1 수정 루프를 즉시 재가동**할 것.

## 1. 확정된 SSOT (Single Source of Truth)

| 항목 | 위치 |
|------|------|
| 결정 SSOT | `docs/4. Operations/Phase_1_Decision_Queue.md` |
| 최상위 commit | `f0ec249` `feat(spec): SG-022 + Phase 1 18-item cascade` (ebs_github/main 에 push 완료) |
| 결정 근거 | 사용자 (기획자) 2026-04-27 결정 18건 |
| Spec Gap Registry | `docs/4. Operations/Spec_Gap_Registry.md` (SG-022 + SG-008-b1~9/14/15 + SG-003/017/021/020 = DONE) |

## 2. Phase 2 진입 조건 (모두 충족)

- [x] 18건 spec 결정 SSOT 화 완료 (`Phase_1_Decision_Queue.md`)
- [x] 14 파일 cascade 동기화 완료 (`f0ec249`)
- [x] Foundation §5.0 / §6.4 + BS_Overview §1 + Settings/Overview + Multi_Session_Workflow 정렬 완료
- [x] Spec_Gap_Registry 8건 DONE 갱신
- [x] MEMORY [SUPERSEDED] 마킹 + 신규 결정 메모 등재
- [x] ebs_github push 자동 완료 (자동 rebase 파이프라인)

## 3. 팀별 진입 가능 작업

### Team 1 (Frontend)
- **즉시 가능**: SG-022 단일 Desktop 바이너리 기준 Lobby/CC/Overlay 라우팅 구현
- **C.1 적용**: Settings 5-level scope (Global/Series/Event/Table/User) UI/State 구현 — 현재 `settings_scope_provider.dart` 기반
- **C.2 적용**: Rive Manager Validate UI — `.riv` 단일파일 + 표준 메타 (Custom Property `skin_name`/`skin_version`, Text Run `player.name.{seat_id}`/`pot.total`, State Machine `deal/fold/win/lose`) 검증 로직
- **B-Q3 합류 시 처리**: `team1-frontend/web/` 폴더 + Flutter Web 빌드 자산 정리 (옵션 a/b/c 자체 결정)

### Team 2 (Backend)
- **즉시 가능**: SG-008-b 11건 endpoint 구현
  - audit-events RBAC=Admin only / audit-logs 별도 리소스 / NDJSON+100req/min download
  - auth.me 확장 필드 / logout current+all options
  - sync mock seed/reset env-guard (dev/staging only) / sync trigger Admin only / sync status Public+Admin bifurcation
- **C.4 적용**: pre-push hook 신규 작성 (`/.claude/hooks/pre_push_conflict_check.py` 권고)
- **Settings 키 b14/b15**: `twoFactorEnabled` (User scope) / `fillKeyRouting` (NDI param)

### Team 3 (Game Engine)
- **즉시 가능**: API-04 OutputEvent 발행 — C.3 100ms 전체 파이프라인 SLA 기여 구간 측정 가능 상태로 구현
- **본 cascade 영향 없음** (engine 코드 직접 수정 없음). 단 Foundation §6.4 분해 SLA 정의를 측정 기준으로 채택.

### Team 4 (Command Center)
- **즉시 가능**: SG-022 단일 Desktop 환경에서 RFID HAL + Overlay Rive 렌더링 통합
- **C.2 메타 적용**: Rive 메타데이터 추출 경로 (Custom Property + Text Run + State Machine) 사용해 overlay 데이터 바인딩

## 4. 기획 충돌 시 즉시 행동 (Phase 1 재가동 트리거)

구현 중 다음 발생 시 **즉시 코딩 중단** 후 conductor 에 escalate:

| 트리거 | 처리 |
|--------|------|
| Type B (기획 공백 발견) | conductor 에 ping → 기획 보강 PR 후 재개 |
| Type C (기획 모순 발견) | conductor 에 ping → 기획 정렬 PR 후 재개 |
| Type D (기획-구현 drift, 코드가 진실인 경우) | conductor 와 합의 → registry 갱신 후 재개 |

> 자세한 분류: `docs/4. Operations/Spec_Gap_Triage.md` §7.2.1

## 5. 보류 항목 (사용자 후속 결정 대기 — Phase 2 차단 아님)

| ID | 내용 | decision_owner | due-date |
|----|------|----------------|----------|
| **B-Q2** | Docker `lobby-web` 컨테이너/이미지 정리 (좀비 위험) | 사용자 | 2026-05-04 |
| **B-Q3** | team1-frontend Flutter Web 빌드 자산 처리 | team1 | 2026-05-04 |

> 두 항목은 **Phase 2 코딩을 차단하지 않음**. 단, team1 합류 시 B-Q3 + B-Q2 동시 처리 권장.

## 6. 후속 SSOT 진화 규칙

Phase 2 진행 중 새 spec 결정이 필요해지면:

1. **추가 전용 (additive)** 원칙 — 기존 SSOT 무손실 보강
2. **decision_owner notify** — 커밋 메시지 또는 active-edits 레지스트리
3. **Spec_Gap_Registry 신규 row 추가** — Type 분류 + 결정 근거 명시
4. **Phase_1_Decision_Queue 갱신 금지** — 본 문서는 2026-04-27 시점 SSOT. 이후 결정은 `Phase_2_Decision_Queue.md` 또는 신규 SG entry.

## 7. 검증 (broadcast 도착 확인)

각 팀 세션은 합류 시 다음 체크리스트 수행:

- [ ] 본 NOTIFY 파일 읽기 완료
- [ ] `Phase_1_Decision_Queue.md` 18건 결정 검토 완료
- [ ] `Spec_Gap_Registry.md` 자기 팀 관련 항목 확인
- [ ] 본 NOTIFY 의 §3 자기 팀 작업 진입 조건 검토
- [ ] 충돌 시 §4 트리거 인지

## 참조

- `docs/4. Operations/Phase_1_Decision_Queue.md` (18건 결정 SSOT)
- `docs/4. Operations/Spec_Gap_Registry.md` (SG-022 + 관련 항목)
- `docs/4. Operations/Spec_Gap_Triage.md` (Type 분류)
- `docs/4. Operations/Conductor_Backlog/B-Q2-docker-lobby-web-cleanup.md`
- `docs/4. Operations/Conductor_Backlog/B-Q3-team1-frontend-web-build-assets.md`
- commit `f0ec249` (`git show f0ec249` 으로 cascade 전체 검토)

## Changelog

| 날짜 | 버전 | 변경 내용 | 결정 근거 |
|------|------|-----------|----------|
| 2026-04-27 | v1.0 | broadcast 발행 (Phase 2 진입 허용) | 사용자 ㉡ ㉣ + Phase 1 cascade 완료 검증 |
