---
id: NOTIFY-conductor-B088-PR2bis
title: "B-088 PR-2-bis — service/router 레이어 Pydantic 응답 타입 적용 (B-089 23 failure 근본 해결)"
status: OPEN
created: 2026-04-21
from: conductor (critic review 결과)
target: team2
priority: P1 (B-089 baseline 복구 전제)
---

# NOTIFY → team2: B-088 PR 2-bis — Service/Router Layer Pydantic 응답

## 배경

PR-2 (Pydantic `alias_generator=to_camel` + `EbsBaseModel`) 는 **schema 정의만** 수정했다. 그러나 서비스/라우터 코드는 여전히 Python `dict` 를 직접 반환하고 있어 `alias_generator` 가 동작하지 않는다.

### 증거 (2026-04-21 critic review)

- PR-2 commit `9027616` 추가 범위: Pydantic `BaseModel` 서브클래스 + config
- 실제 라우터/서비스: `return {"event_flight_id": ..., "table_count": ...}` 형태 (dict) 반환
- 결과: 응답 JSON 은 여전히 snake_case → 테스트가 camelCase 기대 시 실패
- **B-089 23 failure** 의 근본 원인 — test 만 수정해서는 해결 불가

## 수락 기준

- [ ] team2 router 전수 점검: `return {...}` dict 반환 → Pydantic 응답 모델로 변환
- [ ] Service layer 동일: dict 생성 함수를 response model 반환으로 교체
- [ ] SQLAlchemy ORM 객체 → Pydantic (`from_attributes=True`) 자동 직렬화 경로 확인
- [ ] 수동 `jsonable_encoder(...)` 호출이 남아있으면 by_alias=True 확인
- [ ] pytest 재실행 후 `--format=camelCase` 응답 검증

## 범위 (실측 필요)

```bash
# dict 반환 패턴 탐색 (near-miss detect)
grep -rn "return {" team2-backend/src/routers/ | grep -v "#"
grep -rn "return {" team2-backend/src/services/ | grep -v "#"
```

예상: router 20+ 엔드포인트, service 10+ 함수.

## 관련 PR

- 상위: `B-088-naming-convention-camelcase-migration.md` PR-2
- B-089 baseline: B-089 23 failure 는 이 PR-2-bis 완료 후 재평가

## 테스트 전략

1. Response model 강제: FastAPI `response_model=SomeEbsBaseModel` 명시
2. `TestClient` 응답 JSON 키가 camelCase 인지 assert
3. round-trip: snake_case DB → camelCase API → snake_case client 처리

## 선행 의존

- PR-2 완료 (DONE, commit `9027616`) — EbsBaseModel 존재

## Critic Counter-Evidence 주의

- "response_model 을 지정하지 않아도 Pydantic 모델 인스턴스를 반환하면 자동 직렬화된다" — True. 그러나 dict 를 반환하면 bypass 되므로 **dict 사용 전면 금지** 가 실질 규칙
- SQLAlchemy 객체 직접 반환은 `from_attributes=True` 와 `response_model` 조합 필수
