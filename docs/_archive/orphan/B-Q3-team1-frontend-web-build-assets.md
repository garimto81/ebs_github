---
title: team1-frontend Flutter Web 빌드 자산 처리 (SG-022 cascade)
owner: team1
tier: internal
status: PENDING
type: backlog-deferred-decision
linked-sg: SG-022
decision-owner: team1
due-date: 2026-05-04
last-updated: 2026-04-27
confluence-page-id: 3819176685
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819176685/EBS+team1-frontend+Flutter+Web+SG-022+cascade
---

## 개요

SG-022 결정 (단일 Desktop 바이너리, Lobby 포함) 의 코드 자산 cascade. team1-frontend 의 Flutter Web 빌드 관련 코드/스크립트를 정리해야 한다. **team1 세션 위임**.

## 배경

- 2026-04-22 γ 하이브리드 정책 채택 시 team1 이 `flutter build web` 빌드 파이프라인 구축.
- 2026-04-27 SG-022 결정으로 Web 배포 폐기 → 관련 자산 obsolete.
- 사용자 결정 2.㉡: team1 세션 합류 시 처리.

## 처리 대상 (team1 세션 자체 판단)

| 자산 후보 | 추정 위치 | 처리 옵션 |
|-----------|-----------|----------|
| `web/` 폴더 (index.html, manifest 등) | `team1-frontend/web/` | 삭제 또는 README 에 "Phase 2 옵션" 명시하며 보존 |
| Flutter Web 빌드 스크립트 | `team1-frontend/scripts/build_web.*`, `Makefile`, `package.json` 등 | 삭제 또는 deprecated 마커 |
| CI/CD Web 빌드 단계 | GitHub Actions / Docker build | Web 단계 비활성화 |
| README Web 배포 가이드 | `team1-frontend/README.md` | "Desktop 전용" 으로 갱신 |
| Flutter pubspec.yaml | Web platform 의존성 | platform: web 항목 제거 (선택) |

## 처리 옵션 (team1 결정)

| 옵션 | 처리 |
|------|------|
| (a) 즉시 삭제 | web/, build script, CI 단계 모두 제거. 가장 깔끔 |
| (b) 보존 + 명시 | "Phase 2 옵션, EBS 범위 밖" README 에 명시. 후속 운영 요구 대비 |
| (c) Conductor 위임 | team1 자체 처리 어려울 시 Conductor 에 재위임 |

> **현재 권장**: team1 합류 시 (a) 또는 (b) 자체 결정. B-Q2 와 함께 처리.

## 의존 / 차단

- **B-Q2 와 동시 처리 권장** — Docker `lobby-web` 컨테이너가 Web 빌드 산출물에 의존했으므로 빌드 자산 정리 시 컨테이너도 함께 제거되어야 일관성 유지.
- **차단**: team1 이 현재 다른 작업 (예: D3 Settings UI 매핑) 중일 시 우선순위 협의 필요.

## 위험 / 에스컬레이션

- **현재 위험**: team1 합류 지연 시 `lobby-web` 좀비 위험 (B-Q2) 과 결합되어 운영 위험 증가.
- **에스컬레이션 조건**: 2026-05-04 까지 team1 세션 미합류 시 Conductor 가 옵션 (c) 평가.

## 검증 (Pass 조건 — team1 결정에 따라 달라짐)

- [ ] team1 합류 후 처리 옵션 (a/b/c) 결정 및 commit
- [ ] 처리 옵션 (a) 선택 시: `team1-frontend/web/` 폴더 부재 + Web 빌드 스크립트 부재
- [ ] 처리 옵션 (b) 선택 시: README "Phase 2 옵션" 명시 + 빌드 시 Web 단계 자동 skip
- [ ] team1-frontend/CLAUDE.md 갱신 (Desktop 전용 명시)
- [ ] B-Q2 (Docker) 와 처리 일관성 확인

## 참조

- `docs/4. Operations/Phase_1_Decision_Queue.md` (Decision Group A + Q3 보류)
- `docs/4. Operations/Spec_Gap_Registry.md` (SG-022)
- `docs/4. Operations/Conductor_Backlog/B-Q2-docker-lobby-web-cleanup.md` (paired)
- `team1-frontend/CLAUDE.md` (team1 세션 진입점)
