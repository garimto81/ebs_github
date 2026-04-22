---
id: NOTIFY-team4-cc-web-unhealthy
title: "ebs-cc-web-1 컨테이너 2일간 unhealthy 상태 — 진단/재빌드 요청"
status: OPEN
created: 2026-04-22
from: team1 (Docker Runtime 프로토콜 적용 중 발견)
target: team4
priority: P2 (CC Web 데모 환경 영향)
---

# NOTIFY → team4: ebs-cc-web-1 unhealthy

## 발견 맥락

2026-04-22 Docker Runtime 운영 지침 (`docs/4. Operations/Docker_Runtime.md`) 신설 직후 Step 1 좀비 스캔 수행 중:

```
ebs-cc-web-1   ebs-cc-web   Up 2 days (unhealthy)
```

compose 정의 (`docker-compose.yml`):
```yaml
cc-web:
  image: nginx:alpine
  ports:
    - "3100:80"
  volumes:
    - ./team4-cc/src/build/web:/usr/share/nginx/html:ro
  profiles:
    - web
  healthcheck:
    # (정의 확인 필요)
```

그러나 실행 중 이미지는 `ebs-cc-web` — compose 의 `nginx:alpine` 과 다른 **별도 태그된 이미지**. 과거 세션이 `docker compose build` 로 생성한 이미지로 추정.

## team4 조사 요청

1. **이미지 정합성**:
   - 현재 이미지 `ebs-cc-web` 이 compose 현 정의와 일치하는지
   - 또는 과거 `team4-cc/src/Dockerfile` 기반 custom build 인지
   - `docker history ebs-cc-web` 로 COPY 경로 + 빌드 시각 확인
2. **healthcheck 실패 원인**:
   - `docker logs ebs-cc-web-1 --tail 100`
   - `docker inspect ebs-cc-web-1 --format '{{json .State.Health}}'`
3. **최신 `team4-cc/src/build/web` 반영 여부**:
   - `flutter build web --release` 재수행 + volume 마운트 정합성
   - 또는 이미지 재빌드: `docker compose --profile web build --no-cache cc-web`

## 수락 기준

- [ ] `ebs-cc-web-1` 상태 = **healthy** 전환
- [ ] 이미지 빌드 시각 = 최신 main commit 이후
- [ ] `http://10.10.100.115:3100/` 접속 시 최신 team4 CC Web 서빙 확인
- [ ] Naming_Conventions.md v2 준수 검증 — 혹시 옛 snake_case 코드 서빙 중인지 확인

## 선행 맥락

- 2026-04-22 `ebs-lobby-web` 좀비 사건 (team1-frontend Desktop 전환 후 옛 컨테이너 서빙) 해소 과정에서 발견
- `docs/4. Operations/Docker_Runtime.md` Step 1 좀비 스캔 프로토콜 첫 적용 결과

## 관련

- SSOT: `docs/4. Operations/Docker_Runtime.md` (운영 지침)
- 메모리: `~/.claude/projects/C--claude-ebs/memory/project_ebs_runtime_infrastructure.md`
- 선행 사건: 2026-04-22 ebs-lobby-web stop + rm + rmi 완료
