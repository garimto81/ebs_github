# Lobby Web 빌드 자산 — DEPRECATED (SG-022, 2026-04-27)

> ⚠️ **본 폴더의 Flutter Web 빌드 산출물 (favicon, index.html, manifest.json, icons) 은 더 이상 사용되지 않습니다.** team1 세션 합류 시 처리 옵션을 결정하여 정리 또는 명시 보존하세요.

## 폐기 사유

SG-022 결정 (2026-04-27, 사용자): EBS = **단일 Flutter Desktop 바이너리**. Lobby + Command Center + Overlay 모두 단일 바이너리 내부 라우팅으로 통합. Web 별도 배포 정책 폐기.

## 운영 자산 cascade 처리 결과 (2026-04-27 Conductor)

| 자산 | 상태 |
|------|:----:|
| Docker 컨테이너 `ebs-v2-lobby-web` (healthy 6h) | ✅ destroy |
| Docker 컨테이너 `ebs-lobby-web-1` (exited) | ✅ destroy |
| Docker 이미지 `ebs-v2-lobby-web:latest` | ✅ rmi |
| Docker 이미지 `ebs-lobby-web:latest` | ✅ rmi |
| `docker-compose.yml` `lobby-web` 서비스 블록 | ✅ 제거 (marker 보존) |
| `team1-frontend/web/` 폴더 내용 | **⏳ team1 결정 대기** (아래 옵션 참조) |
| `team1-frontend/Dockerfile` Web 빌드 단계 | **⏳ team1 결정 대기** |

## 처리 옵션 (team1 결정)

| 옵션 | 처리 | 비고 |
|:----:|------|------|
| (a) 즉시 삭제 | `web/` 폴더 + `Dockerfile` Web 단계 + 빌드 스크립트 제거 | 가장 깔끔 |
| (b) 보존 + 명시 | "Phase 2 옵션, EBS 범위 밖" README 만 유지 (현재 상태) | 향후 운영 요구 대비 |
| (c) Conductor 위임 | team1 자체 처리 어려울 시 Conductor 에 재위임 | escalate |

> **due-date: 2026-05-04** (B-Q3 명시). team1 합류 시 옵션 선택 + commit.

## B-Q2 와 동시 처리 권장

`B-Q2-docker-lobby-web-cleanup.md` 의 Docker 자산 정리는 Conductor 가 2026-04-27 에 완료. **단** `team1-frontend/Dockerfile` 의 Flutter Web 빌드 단계는 보존됨 — team1 결정에 따라 정리.

## 참조

- `docs/4. Operations/Phase_1_Decision_Queue.md` (Decision Group A)
- `docs/4. Operations/Spec_Gap_Registry.md` (SG-022)
- `docs/4. Operations/Conductor_Backlog/B-Q3-team1-frontend-web-build-assets.md` (본 백로그)
- `docs/4. Operations/Conductor_Backlog/B-Q2-docker-lobby-web-cleanup.md` (paired Docker 정리, Conductor 처리 완료)
- `docs/2. Development/2.5 Shared/BS_Overview.md` §1 (단일 Desktop 바이너리 SSOT)
- 폐기된 정책: MEMORY `feedback_web_flutter_separation` (2026-04-22 γ 하이브리드, SUPERSEDED)
