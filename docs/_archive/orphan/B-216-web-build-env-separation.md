---
id: B-216
title: "B-216 — Lobby/CC web build 환경 분리 (localhost vs LAN)"
owner: team1
tier: internal
status: PENDING
type: backlog
severity: MEDIUM
blocker: false
source: docs/4. Operations/Plans/E2E_Verification_Report_2026-05-10.md
last-updated: 2026-05-10
---

## 개요

E2E 검증 중 발견: `team1-frontend/production.example.json`이 `EBS_BO_HOST=api.ebs.local` (LAN 도메인 가정)으로 되어 있어 localhost 환경에서 docker compose up 시 즉시 connection timeout.

team4 cc-web Dockerfile도 동일 패턴 (`production.json` 부재 시 `engine.ebs.local`/`api.ebs.local` inline 생성).

## 영향

- 개발자가 매번 수동 `production.json` 작성 후 `docker compose build --no-cache lobby-web cc-web` 필요
- 신규 onboarding 시 즉시 차단 (console errors 4건)
- E2E 보고서 v1.0의 PASS 판단 정확성 영향

## 작업 범위

1. 환경별 ENV 파일 신규:
   - `team1-frontend/production.localhost.json` (EBS_BO_HOST=localhost, PORT=8000)
   - `team1-frontend/production.lan.json` (EBS_BO_HOST=api.ebs.local, PORT=80) — 기존 production.example.json 대체
   - `team4-cc/src/production.localhost.json`, `production.lan.json` 동일 분리
2. Docker Compose에 build-arg로 ENV_FILE 선택 가능:
   ```yaml
   lobby-web:
     build:
       args:
         ENV_FILE: ${LOBBY_ENV_FILE:-production.localhost.json}
   ```
3. README/Docker_Runtime.md에 환경 분기 가이드:
   ```bash
   # localhost (default)
   docker compose --profile web up -d
   # LAN
   LOBBY_ENV_FILE=production.lan.json CC_ENV_FILE=production.lan.json docker compose --profile web up -d
   ```

## 대안 (런타임 주입)

빌드 시점이 아닌 nginx startup 시점에 `envsubst` 또는 `sed`로 main.dart.js 내 placeholder URL 치환. 빌드 결정성은 떨어지지만 환경별 재빌드 불필요.

## 완료 기준

- [ ] localhost 환경에서 `docker compose --profile web up -d` (no extra args) → 즉시 동작 (console errors 0)
- [ ] LAN 환경 override 명시적 가이드
- [ ] B-Q3 (team1 frontend web build assets)와 정합

## 참조

- E2E 보고서: §5 발견 제약 #1
- B-Q3 (team1 frontend web build assets)
- Docker_Runtime.md §1 정규 컨테이너 맵
