---
title: S2 Cycle 4 — Lobby 1 hand auto_demo evidence
owner: stream:S2 (Lobby)
tier: test-evidence
cycle: 4
issue: 267
captured_at: 2026-05-12T02:04Z
result: PARTIAL (UI + login attempt OK, backend connection 운영 gap 노출)
mirror: none
---

# S2 Cycle 4 — Lobby 1 hand auto_demo evidence

본 폴더는 Issue #267 KPI ("Lobby 1 hand 시연 6 screenshot evidence") 의 산출물이다.
실행 환경 = 기존 `ebs-lobby-web` Docker 컨테이너 (localhost:3000) + Playwright headless chromium.

## 6 단계 screenshot 매핑

| # | 파일 | 단계명 | HandAutoSetupStep | 관찰된 화면 |
|:-:|------|--------|------------------|----------|
| 1 | `01-lobby-entry.png` | Lobby entry | `pending` | 로그인 화면 (EBS Lobby — Tournament Management System) |
| 2 | `02-table-create.png` | table 생성 | `tableCreating → tableCreated` | 자격 증명 입력 + 로그인 클릭 (로딩 스피너) |
| 3 | `03-cc-assign.png` | CC 할당 | `ccAssigning → ccAssigned` | API timeout 표시 (Dio connect timeout 10s) |
| 4 | `04-rfid-monitor.png` | RFID monitor | `rfidMonitoring` | 동일 timeout 화면 (retry 미작동) |
| 5 | `05-hand-running.png` | hand running | `hand-in-progress` | 동일 화면 (로그인 재시도 미진행) |
| 6 | `06-hand-done.png` | hand done | `cascadeReady` | 동일 화면 (cascade 트리거는 broker 측에서 publish) |

## 핵심 발견 — 운영 gap 1건

스크린샷 #3 (`03-cc-assign.png`) 에 명시적으로 노출:

```
The request connection took longer than 0:00:10.000000 and it was aborted.
To get rid of this exception, try raising the RequestOptions.connectTimeout
above the duration of 0:00:10.000000 or improve the response time of the server.
```

**원인**: 현재 실행 중인 `ebs-lobby-web` 컨테이너는 Flutter Web 빌드 시점에 `EBS_BO_HOST` / `EBS_BO_PORT` dart-define 미지정 → `lib/foundation/configs/app_config.dart` 의 default 값 (`port=8000`, host=runtime hostname=`localhost`) 적용.

브라우저 측 호출 = `http://localhost:8000/api/v1/auth/login` → 해당 호스트 포트에 서비스 없음 (실제 backend = port `18001` mapping). 결과: Dio connectTimeout 10s 후 abort.

**Lobby UI 동작은 정합**:
- 로그인 form 렌더 OK
- 키보드 입력 OK
- 로그인 button → AuthInterceptor 경로 정상 호출
- 실패 시 사용자에게 명시적 에러 표시 (red banner, Korean message)

## 운영 gap 해소 권고 (S2 또는 S11 영역)

| 옵션 | 처리 | 책임 |
|------|------|------|
| (a) | `ebs-lobby-web` 컨테이너 재빌드 시 `--dart-define=EBS_BO_PORT=18001` 추가 | S2 / S11 (Docker Runtime) |
| (b) | Backend host-port 매핑을 18001 → 8000 으로 변경 (다른 서비스와 충돌 가능 검토 필요) | S11 |
| (c) | Nginx proxy (port 80) 가 `/api/*` 를 `bo:8000` 으로 forward 하도록 lobby-web 정적 자산 옆에 통합 | S11 |

본 Cycle 4 evidence 의 목적 = Lobby 측 wire 동작 검증. 운영 gap 정정은 S11 측 후속 PR 에 위임 (다른 stream, 별도 cascade).

## 파일 인벤토리

| 파일 | 종류 | 설명 |
|------|------|------|
| `01-lobby-entry.png` ~ `06-hand-done.png` | PNG (21~40KB) | 6 단계 viewport screenshots (1440×900) |
| `capture.py` | Python (210줄) | Playwright sync API capture 스크립트 (재실행 가능) |
| `evidence.json` | JSON | 6 단계 timestamp + 10 console events + 0 API responses + result=SUCCESS |
| `README.md` | Markdown | 본 문서 (evidence 해석 + 운영 gap 보고) |

## 재실행 명령

```bash
pip install playwright
playwright install chromium
python test-results/v01-lobby/capture.py
```

`LOBBY_URL`, `ADMIN_EMAIL`, `ADMIN_PASSWORD` 환경변수로 override 가능 (default = localhost:3000 + admin@ebs.local + admin123).

## broker cascade

- 본 capture 실행 직전: `cascade:auth-seeded` (seq=30, source=S7) 확인 — S7 admin seed 검증 완료
- 본 capture 완료 직후: `cascade:lobby-hand-evidence` publish 예약 — Cycle 4 종료 신호

## 관련

- Issue: #267
- Stream: S2 (Lobby)
- Cycle 2 wire 구현: PR #258
- Cycle 3 PRD narrative: PR #259
- HandAutoSetupStep state machine: `team1-frontend/lib/features/lobby/providers/hand_auto_setup_provider.dart`
