---
title: Docker lobby-web 컨테이너/이미지 정리 (SG-022 cascade)
owner: conductor
tier: internal
status: DONE
resolved: 2026-04-27
resolved-by: conductor
type: backlog-deferred-decision
linked-sg: SG-022
decision-owner: user
due-date: 2026-05-04
last-updated: 2026-04-27
confluence-page-id: 3819078306
confluence-parent-id: 3184328827
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819078306/EBS+Docker+lobby-web+SG-022+cascade
mirror: none
---

## 개요

SG-022 결정 (단일 Desktop 바이너리, Lobby 포함) 의 운영 자산 cascade. Docker compose 의 `lobby-web` 서비스와 런타임 컨테이너/이미지를 정리해야 한다. **사용자 명시 승인 대기 중**.

## 배경

- 2026-04-22 γ 하이브리드 정책 (Lobby Web + CC Desktop 분리) 채택 시 `lobby-web` 컨테이너 도입.
- 2026-04-22 좀비 컨테이너 사건 (`ebs-lobby-web` 1차) 의 그 컨테이너.
- 2026-04-27 SG-022 결정으로 γ 하이브리드 폐기 → `lobby-web` 운영 자산 obsolete.
- Docker_Runtime.md 규칙: "compose 에서 제거하고 런타임 살려두기 = 좀비 원인 1순위" → compose 정리 시 런타임 동시 정리 필수.

## 처리 대상

| 자산 | 위치 | 작업 |
|------|------|------|
| compose 서비스 정의 | `docker-compose.yml` (또는 `docker-compose.web.yml`) | `lobby-web` 서비스 블록 제거 |
| 런타임 컨테이너 | Docker daemon | `docker compose --profile web stop lobby-web && rm -f` |
| 이미지 | Docker daemon | `docker rmi ebs-lobby-web:latest` (latest 외 태그 확인 필수) |
| Docker_Runtime.md | `docs/4. Operations/Docker_Runtime.md` | 컨테이너 맵에서 `lobby-web` 제거 |
| 좀비 사건 history | Docker_Runtime.md §사건 이력 | "2026-04-22 ebs-lobby-web 1차" 항목 보존 (역사 기록) |

## 처리 후보 시나리오

| 시나리오 | 장점 | 단점 |
|----------|------|------|
| (a) team1 세션 합류 시 B-Q3 와 함께 처리 | 빌드 자산 + 런타임 동시 정리, 컨텍스트 일치 | team1 합류 시점 불확실 |
| (b) Conductor 가 사용자 명시 승인 후 즉시 처리 | 좀비 위험 즉시 제거 | team1 빌드 자산 (B-Q3) 과 분리되어 부분 cleanup |
| (c) 별도 운영 PR | 독립 추적, 정확한 롤백 가능 | 추가 PR 비용 |

> **현재 권장**: (a) — 사용자 결정 2.㉡ (team1 세션 위임). team1 다음 활동 시 같이 처리.

## 위험 / 에스컬레이션

- **현재 위험**: compose 에서 제거되었거나 deprecated 상태일 가능성 → 좀비 위험 잔존 가능
- **에스컬레이션 조건**: 2026-05-04 까지 team1 세션 미합류 시 사용자에게 처리 방식 확정 요청 (시나리오 (b) 또는 (c) 로 전환)
- **블로커 신호**: 다른 좀비 사건 발생 시 즉시 escalate

## 검증 (Pass 조건)

- [ ] `docker compose --profile web config --services` 출력에 `lobby-web` 부재
- [ ] `docker ps -a --format "table {{.Names}}" | grep lobby-web` 0건
- [ ] `docker images | grep lobby-web` 0건 (또는 의도적 보존 시 명시)
- [ ] Docker_Runtime.md 컨테이너 맵 갱신
- [ ] `git status` 에 untracked Docker 자산 0건

## Resolution Log (2026-04-27, Conductor)

사용자 명시 task 1 (Phase 2 시작 메시지) 으로 즉시 처리 진행.

| 단계 | 결과 | 비고 |
|------|:----:|------|
| Docker 컨테이너 stop+rm: `ebs-v2-lobby-web` | ✅ | healthy 6h 운영 중이었으나 graceful shutdown |
| Docker 컨테이너 stop+rm: `ebs-lobby-web-1` | ✅ | exited 상태 |
| Docker 이미지 rmi: `ebs-v2-lobby-web:latest` | ✅ | sha256:a52ccda8fe50 |
| Docker 이미지 rmi: `ebs-lobby-web:latest` | ✅ | sha256:ab8c511f9744 |
| `docker-compose.yml` `lobby-web` 서비스 블록 제거 (marker 보존) | ✅ | line 89-113 → SG-022 REMOVED 마커 |
| `Docker_Runtime.md` 컨테이너 맵 갱신 | ✅ | line 22 row + "중요 정정 2026-04-22" SUPERSEDED |
| team1-frontend `Dockerfile` Web 빌드 단계 | ⏳ | **B-Q3 위임** (team1 결정 대기) |
| team1-frontend `web/` 폴더 정리 | ⏳ | **B-Q3 위임** + `web/README.md` deprecation 마커 추가 |

## Verification

- `docker ps -a | grep lobby-web` → 0건 ✓
- `docker images | grep -E "ebs-lobby-web\|ebs-v2-lobby-web"` → 0건 ✓
- `grep -n "lobby-web:" docker-compose.yml` → 서비스 정의 0건 ✓ (marker 만 존재)
- 보존된 lobby 관련 이미지 (`claude-lobby`, `ebs-lobby-dev`, `ebs_lobby-lobby`) → 별도 결정 대상 (SG-022 직접 명시 없음, scope 초과 차단 검증 후 보존)

## 참조

- `docs/4. Operations/Phase_1_Decision_Queue.md` (Decision Group A + Q2 보류)
- `docs/4. Operations/Spec_Gap_Registry.md` (SG-022)
- `docs/4. Operations/Docker_Runtime.md` (운영 SSOT)
- `docs/4. Operations/Conductor_Backlog/B-Q3-team1-frontend-web-build-assets.md` (paired)
- `team1-frontend/web/README.md` (deprecation 마커, Conductor 추가 2026-04-27)
- MEMORY `project_ebs_runtime_infrastructure.md`
