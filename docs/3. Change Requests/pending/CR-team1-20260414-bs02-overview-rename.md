---
title: CR-team1-20260414-bs02-overview-rename
owner: team1
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-team1-20260414-bs02-overview-rename
---

# CCR-DRAFT: BS-02-lobby.md → BS-02-00-overview.md rename 외부 참조 갱신

- **제안팀**: team1
- **제안일**: 2026-04-14
- **영향팀**: [team2, conductor]
- **변경 대상 파일**: contracts/api/API-01-backend-api.md, contracts/api/API-05-websocket-events.md, contracts/api/API-06-auth-session.md, team2-backend/specs/back-office/BO-02-sync-protocol.md, team2-backend/specs/back-office/BO-03-operations.md
- **변경 유형**: modify (path rewrite only)
- **변경 근거**: `team1-frontend/specs/BS-02-lobby/BS-02-lobby.md` 를 `BS-02-00-overview.md` 로 rename 완료. 사유 — (a) BS-03-00-overview·BS-08-00-overview 와 명명 관례 정렬, (b) `ui-design/UI-01-lobby.md` 와 동일 "lobby" 이름으로 인지적 충돌 발생. 사용자 승인 후 team1 세션에서 rename 실행 완료, 외부 참조만 잔존하므로 본 CCR 로 위임.
- **리스크 등급**: LOW (path rewrite only, anchor slug 미변경)

## 변경 요약

team1 세션에서 이미 rename 완료. 외부 참조 7건 / 5파일을 path rewrite 만 하면 됨.

## Mapping (정확)

| 파일 | 라인 | 구 | 신 |
|------|:----:|---|---|
| `contracts/api/API-01-backend-api.md` | 45 | `BS-02-lobby.md` | `BS-02-00-overview.md` |
| `contracts/api/API-05-websocket-events.md` | 19 | `BS-02-lobby.md §활성 CC 모니터링` | `BS-02-00-overview.md §활성 CC 모니터링` |
| `contracts/api/API-06-auth-session.md` | 260 | `BS-02-lobby.md §세션 저장 데이터` | `BS-02-01-auth-session.md §세션 저장 데이터` (2026-04-14 추가 분리: 로그인·세션 콘텐츠를 BS-02-01 로 이관) |
| `contracts/api/API-06-auth-session.md` | 393 | `BS-02-lobby.md §화면 0: 로그인` | `BS-02-01-auth-session.md §화면 0: 로그인` (2026-04-14 추가 분리) |
| `team2-backend/specs/back-office/BO-02-sync-protocol.md` | 62 | `BS-02-lobby.md §장애 시 기능 축소 매트릭스` | `BS-02-00-overview.md §장애 시 기능 축소 매트릭스` |
| `team2-backend/specs/back-office/BO-02-sync-protocol.md` | 273 | `BS-02-lobby.md` | `BS-02-00-overview.md` |
| `team2-backend/specs/back-office/BO-03-operations.md` | 332 | `BS-02-lobby.md` | `BS-02-00-overview.md` |

## Anchor 보증

본 rename 은 파일명만 변경. H2 제목/슬러그(`§활성 CC 모니터링`, `§세션 저장 데이터`, `§화면 0: 로그인`, `§장애 시 기능 축소 매트릭스`)는 모두 보존되었음. 따라서 외부 참조의 `§...` anchor 부분은 그대로 유효.

## Diff 초안 (자동화)

bash 일괄 적용 가능 (Conductor 세션에서):

```bash
cd C:/claude/ebs
# 단순 path rewrite (anchor slug 보존)
find contracts/ team2-backend/ -name "*.md" -exec sed -i \
  's|`BS-02-lobby\.md|`BS-02-00-overview.md|g' {} +

# 검증
grep -rn "BS-02-lobby\.md" contracts/ team2-backend/ --include="*.md"
# 기대: 0 hit
```

수동 적용 시: 각 파일 grep 위치에서 `BS-02-lobby.md` 를 `BS-02-00-overview.md` 로 치환. 앞뒤 공백·anchor 부분 변경 금지.

## 영향 분석

- **Team 2 (BO 문서)**: BO-02·BO-03 가 BS-02 §장애 매트릭스·§감사 로그 항목을 anchor 참조 중. path 만 변경되므로 영향 없음.
- **Contracts API**: API-01·05·06 가 BS-02 §모니터링·§세션·§로그인 anchor 참조 중. path 만 변경.
- **Team 1 (자기)**: 이미 INDEX.md + Edit History 갱신 완료.
- **Team 4**: BS-02 직접 참조 0건 확인 (이전 critic 조사 결과는 anchor 가 아닌 도메인 인용).
- **마이그레이션**: 없음. 단순 path rewrite.

## 대안 검토

1. **파일명 유지 + UI 쪽 rename**: UI-01-lobby.md → UI-01-lobby-screens.md 등. 기각 사유 — UI-0X 시리즈는 모두 단순 도메인 이름(UI-03-settings, UI-04-graphic-editor)이라 suffix 추가가 관례 깨짐. 또한 외부 참조 양이 BS 쪽이 더 많으므로 변경 비용 비대칭이 BS rename 이 유리.
2. **이중 파일 유지 (symlink/redirect)**: Markdown 에 redirect 메커니즘 없음. 기각.
3. **방치**: 인지적 충돌 + BS-03/08 관례 불일치 누적. 기각.

## 검증 방법

```bash
# 1. 외부 잔존 참조 0 확인
grep -rn "BS-02-lobby\.md" contracts/ team2-backend/ --include="*.md"

# 2. 신규 경로 참조 7 확인
grep -rn "BS-02-00-overview\.md" contracts/ team2-backend/ --include="*.md" | wc -l
# 기대: 7
```

## 승인 요청

- [ ] Conductor 자동화 sed 명령 실행 또는 수동 7건 갱신
- [ ] Team 2 검토 (BO-02·BO-03 anchor 정상 동작 확인)
