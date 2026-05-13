---
id: B-Q21
title: "bo healthcheck 가 redis 의존성 silent failure 마스킹 — dependency-aware probe 필요"
status: PENDING
type: backlog
priority: P2
created: 2026-05-03
discovered-during: NOTIFY-team4-cc-web-unhealthy 자율 점검 (Conductor Mode A)
owner: team2 (or conductor Mode A)
linked: NOTIFY-team4-cc-web-unhealthy.md, docker-compose.yml
last-updated: 2026-05-03
---

## 발견

2026-05-03 cc-web NOTIFY 자율 점검 중:

```
ebs-bo     running  Health=healthy  StartedAt=2026-05-01T12:57:22Z
ebs-redis  exited   ExitCode=255    FinishedAt=2026-05-01T12:57:17Z
```

bo 가 redis Exited 5초 전부터 healthy 로 보고. 이유: bo healthcheck (`docker-compose.yml`):

```yaml
healthcheck:
  test: ["CMD", "python", "-c", "import httpx; httpx.get('http://localhost:8000/health')"]
```

→ HTTP `/health` endpoint 만 hit. Redis 연결 verify 없음. 결과로 redis 가 죽어 있어도 bo 는 39시간 healthy 보고.

## Type 분류

**Type B (기획 공백)** — Production-strict 운영 모델 (B-Q7 ㉠) 명시한 99.9% uptime SLA + 0.1% 에러율 목표가 dependency-aware healthcheck 없이는 불가능. 문서가 healthcheck 의 dependency probe 의무를 명시 안 함.

## 영향

- redis-backed 기능 (session, pub-sub, idempotency cache) 이 silent fail
- 운영자 dashboard 가 잘못된 healthy 신호 표출 → 실제 장애 인지 지연
- 본 사례: 2일간 dependency outage, 사용자 미인지

## 처리 옵션

### Option 1 (권장) — bo `/health` endpoint 강화

`team2-backend/src/routers/health.py` 에:

```python
@router.get("/health")
async def health(db: Session = Depends(get_db)):
    # DB ping
    db.exec(select(1))
    # Redis ping
    from src.app.redis_client import get_redis
    r = get_redis()
    r.ping()
    return {"status": "ok"}
```

dependency 실패 시 500 → docker healthcheck 가 unhealthy 인식.

### Option 2 — 별도 `/health/deep` endpoint

`/health` 는 fast (200 즉시), `/health/deep` 가 dependency probe. compose healthcheck 가 deep 호출.

### Option 3 — compose `depends_on` `service_healthy` 만 의존

startup 만 보장. runtime dependency loss 미감지. **거부**.

## 우선순위

P2 — 즉시 production blocker 아니나, B-Q7 ㉠ production-strict (99.9% uptime) 와 직접 충돌. SG-027 multi-session pipeline 안정성 전제 조건.

## 처리 작업

1. Option 1 적용 — bo `/health` 에 redis + db ping 추가
2. healthcheck timeout 5s → 7s 상향 (deep probe 시간 마진)
3. compose 에 `start_period: 30s` 유지 (warm-up 충분)
4. 회귀 테스트: redis 강제 종료 시 bo healthy → unhealthy 전환 시간 측정 (목표 <30s)

## 참조

- `NOTIFY-team4-cc-web-unhealthy.md` (2026-05-03 RESOLUTION)
- `docs/4. Operations/Docker_Runtime.md` (운영 SSOT)
- B-Q7 ㉠ Production-strict (99.9% uptime)
