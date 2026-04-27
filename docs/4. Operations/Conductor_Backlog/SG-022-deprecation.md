---
type: governance_decision
gap_id: SG-022 (deprecation cascade)
status: DONE
date: 2026-04-27
owner: conductor
decision_owner: user
supersedes: SG-022 single-desktop-binary intent (2026-04-27 morning)
---

# SG-022 폐기 cascade — Multi-Service Docker SSOT 채택

## 결정

> **SG-022 (단일 Desktop 바이너리 — Lobby/CC/Overlay 통합) 인텐트를 공식 폐기한다.**
> **Multi-Service Docker 아키텍처가 EBS 배포 SSOT 다.**

- Lobby (team1) 와 CC (team4) 는 단일 앱이 아니며, 각각 독립된 Flutter 프로젝트로 존재한다.
- Docker 격리 컨테이너 (`lobby-web` :3000, `cc-web` :3001) 가 `ebs-net` bridge 네트워크에서 BO/Engine 과 협력한다.
- 각 팀의 세션 독립성을 보장하되, `docker compose --profile web up -d` 레벨에서 통합 검증이 가능하다.

## 결정자 / 일시

- **사용자** (Conductor + Architect 권한 위임 directive 로 명시): 2026-04-27
- 본 결정은 사용자 인텐트 변경 (Mode A 한계 항목) 에 해당하므로 **사용자 명시 결정** 필수 — directive 자체가 그 명시 결정.

## 사유

| 항목 | SG-022 (단일 Desktop) | Multi-Service Docker |
|------|------------------------|---------------------|
| 기획-운영 정합 | 기획만 정렬 (LAN 배포 / 멀티 세션 운영 미반영) | 운영 요구 (LAN, 멀티 클라이언트, 핫픽스) 충족 |
| 4팀 병렬성 | 통합 .exe 라이프사이클 → 충돌 빈발 | 팀별 Dockerfile 분리 → 독립 빌드 |
| 운영자 워크플로우 | 단일 화면에 Lobby + CC 혼재 | Lobby (대시보드) ↔ CC (액션 입력) 분리 |
| 핫픽스 | 전체 .exe 재배포 | 영향받은 서비스만 재빌드 |
| Type 분류 (Spec_Gap_Triage) | C (기획 모순 — 기획 SSOT vs 운영 요구) | 해소 |
| 2026-04-22 사건 호환 | "Desktop only" 확대 해석 → ebs-lobby-web 컨테이너 destroy 사건 재발 위험 | 본 SSOT 가 명시적으로 Web 단독 배포 인정 → 재발 차단 |

## 적용된 변경 (commit 단위)

1. **`docker-compose.yml`**
   - `lobby-web` 서비스 active 복원 (REMOVED 주석 폐기)
   - `cc-web` 서비스 multi-stage build 로 전환 (port 3100 → 3001)
   - `ebs-net` bridge 네트워크 명시 + 모든 서비스 attach
   - `BO_URL`, `ENGINE_URL`, `LOBBY_URL`, `CC_URL` 환경 변수 주입 (default = service-name DNS)
2. **`team4-cc/docker/cc-web/`** 신규
   - `Dockerfile` (multi-stage Flutter SDK build → nginx alpine, port 3001)
   - `nginx.conf` (SPA fallback + cache + healthz, Rive `.riv` 캐시 정책 추가)
   - `compose.snippet.yaml` (참조용)
3. **`team1-frontend/docker/lobby-web/`** 보존 (자산 파기 금지 directive)
4. **`team1-frontend/CLAUDE.md` §"배포 형태"** — Multi-Service Docker 정렬, "Docker Web 단독" → 명시적 multi-service 구조
5. **`team4-cc/CLAUDE.md` §"배포 형태"** — 신규 섹션 추가 (이전엔 배포 정보 부재)
6. **`docs/4. Operations/MULTI_SESSION_DOCKER_HANDOFF.md`** 신규 — 본 cascade 의 SSOT 운영 가이드
7. **`docs/4. Operations/Conductor_Backlog/SG-022-deprecation.md`** (본 파일) — 결정 기록

## 영향받는 다른 결정

| 결정 | 이전 상태 | 새 상태 |
|------|-----------|---------|
| SG-022 (Spec_Gap_Registry) | DONE — A 채택 (단일 Desktop) | **SUPERSEDED** — 본 cascade 가 폐기. 후속 SG-XXX 또는 본 파일 참조 |
| B-Q2 (Conductor_Backlog) | DONE — Docker lobby-web destroy 2026-04-27 | **REACTIVATED** — lobby-web 복원 (본 cascade) |
| B-Q3 (Conductor_Backlog) | PENDING — team1 Web 빌드 자산, due 2026-05-04 | **DONE** — Multi-Service Docker 채택으로 자산 active 복원 |
| memory `project_decision_2026_04_27_phase1.md` §A | SG-022 = 단일 Desktop | SUPERSEDED 라벨 추가, MULTI_SESSION_DOCKER_HANDOFF 참조 |
| memory `feedback_web_flutter_separation.md` | [SUPERSEDED 2026-04-27] | **REACTIVATED** — Multi-Service 채택으로 정합 |

## Mode A 한계 검증

본 결정은 사용자 인텐트 변경 (Mode A 한계 항목) — 사용자 directive 가 명시 결정으로 작용. Conductor 자율 진행 OK. 추가 메일/배포 등 외부 액션 없음 (코드 + 문서 변경만).

## 후속 작업 (Backlog)

- [ ] team1/team4 세션이 본 directive 반영 후 첫 빌드 — `docker compose --profile web build && up -d` 실행 후 healthz 검증
- [ ] BO 의 `launch-cc` 응답 (REST/WS URL) 이 새 포트 (3001) 로 업데이트되는지 점검
- [ ] integration-tests (`integration-tests/*.http`) 의 베이스 URL 상수에 lobby-web/cc-web 추가
- [ ] (선택) Spec_Gap_Registry.md SG-022 행에 SUPERSEDED 마크 + 본 파일 참조 (Conductor 후속 turn)

## 금지

- SG-022 부활 시도 ("Lobby + CC 단일 .exe 통합") — 사용자 명시 결정 필수
- `MULTI_SESSION_DOCKER_HANDOFF.md` 와 본 파일 외 다른 곳에 SG-022 후속 SSOT 분산 작성 금지 (Single Source of Truth)
