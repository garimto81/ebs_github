---
id: B-218
title: "B-218 — CC Connect 후 2개 버그 (auth prefix + engine host)"
owner: team4
tier: internal
status: IMPLEMENTED
type: backlog
severity: HIGH
blocker: false
source: docs/4. Operations/Plans/E2E_Verification_Report_2026-05-10.md
last-updated: 2026-05-10
implemented-at: 2026-05-10
implemented-by: conductor (E2E v1.3)
---

## 개요

E2E v1.2 검증 중 발견. CC Connect 폼에 admin@ebs.local + admin123 + Table ID 1 입력 후 `Connect` 클릭 시 두 개의 별개 버그.

## 버그 1 — Auth URL prefix `/api/v1` 누락

**증상**: 콘솔 에러
```
GET http://localhost:8000/auth/login 404 (Not Found)
```

**원인**: BO는 v9.5에서 auth router를 `/api/v1/auth/*`로 이전했음. CC의 BoApiClient는 여전히 `/auth/login` 호출 (root 기준).

**Lobby와의 차이**: Lobby는 동일 변경 후 `apiBase=http://...:8000/api/v1` + relative `/auth/login` 결합으로 `http://...:8000/api/v1/auth/login`. 정상.

CC는 baseUrl 또는 path 결합 패턴이 달라서 root 직행.

## 버그 2 — Engine URL이 LAN 도메인으로 빌드됨

**증상**: 콘솔 에러 3건
```
GET http://engine.ebs.local/engine/health  net::ERR_NAME_NOT_RESOLVED
```

**원인**: cc-web Dockerfile의 `production.json` 기본값이 `ENGINE_URL=http://engine.ebs.local`. 우리가 `team4-cc/src/production.json`에 `localhost:8080`로 설정했으나 빌드 context가 `team4-cc/`라서 `src/production.json`이 적용 안 됨 (또는 inline 생성으로 override).

## 작업 범위

1. **버그 1 — auth path**: `team4-cc/src/lib/data/remote/bo_api_client.dart`에서 baseUrl 결합 또는 path 정정. Lobby의 패턴 참조.
2. **버그 2 — engine host**: cc-web Dockerfile의 production.json 위치 통일 (B-216과 정합). `team4-cc/production.json`에 두고 build context 정합.
3. **회귀 테스트**: Connect 후 `localhost:8000/api/v1/auth/login` 200 + `localhost:8080/health` 200 확인.

## 완료 기준

- [ ] CC Connect 클릭 시 `localhost:8000/api/v1/auth/login` 200 응답
- [ ] CC engine health 호출 `localhost:8080/health` 200 응답
- [ ] Connect 후 status `Disconnected` → `Connected` 전환

## 참조

- E2E 보고서 §1, §3.9 (스크린샷 19), Changelog v1.2
- B-216 (web build env 분리)
- Lobby 동등 동작은 정상 (E2E 보고서 §4.2)
