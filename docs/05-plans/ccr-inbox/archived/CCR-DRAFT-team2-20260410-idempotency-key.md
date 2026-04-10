# CCR-DRAFT: 모든 Mutation API에 Idempotency-Key 헤더 표준 도입

- **제안팀**: team2
- **제안일**: 2026-04-10
- **영향팀**: [team1, team4]
- **변경 대상 파일**: contracts/api/API-01-backend-endpoints.md, contracts/api/API-05-websocket-events.md, contracts/api/API-06-auth-session.md
- **변경 유형**: add
- **변경 근거**: WSOP LIVE Confluence 검토 결과(`Chip Master.md`의 2-phase confirmation, `Waiting API.md`의 seat draw 재시도 케이스) — 네트워크 재시도·운영자 더블 클릭·클라이언트 크래시 후 재전송 시 동일 요청이 중복 적용되어 좌석/칩/토큰 상태가 불일치하는 사고를 방지하려면 멱등성 계약이 필수. 현재 API-01~06 계약에는 관련 헤더/응답이 없음.

## 변경 요약

POST/PUT/PATCH/DELETE 계열 mutation 엔드포인트는 모두 `Idempotency-Key` 헤더를 수용한다. Backend는 24h TTL로 요청/응답을 캐싱하고, 동일 키로 재요청 시 원본 응답을 재생한다. 동일 키·상이한 바디면 `409 Conflict` 반환.

## Diff 초안

```diff
## 공통 요청 헤더

+| 헤더 | 필수 | 설명 |
+|------|------|------|
+| `Authorization` | 예 | `Bearer <JWT>` |
+| `Idempotency-Key` | 조건부 | mutation(POST/PUT/PATCH/DELETE)에 권장. UUIDv4 또는 ULID. 클라이언트가 생성. 24h 유지. |
+| `X-Request-ID` | 선택 | 분산 추적용 correlation ID. 서버 로그·응답 헤더에 echo. |

## 공통 응답 (멱등성 관련)

+### 멱등성 동작
+
+- **최초 요청**: 정상 처리 + 응답 캐싱 (키당 24h)
+- **동일 키 + 동일 바디 재요청**: 캐시된 응답 재생 (status/body/headers 동일), 응답 헤더에 `Idempotent-Replayed: true`
+- **동일 키 + 상이한 바디 재요청**: `409 Conflict` + `{"error": "idempotency_key_reused", "original_hash": "sha256:..."}`
+- **키 누락**: mutation은 정상 처리되지만 재시도 안전성 보장 없음. 4xx 아님.

+### 409 Conflict (Idempotency)
+
+```json
+{
+  "error": "idempotency_key_reused",
+  "message": "Key 'abc-123' already used with different payload",
+  "original_hash": "sha256:...",
+  "original_created_at": "2026-04-10T12:34:56Z"
+}
+```
```

API-05(WebSocket) 영향: 클라이언트→서버 command 메시지에도 `idempotency_key` 필드 권장 (별도 섹션).

## 영향 분석

- **Team 2 (자기)**: FastAPI 미들웨어 1개 신설 (`IdempotencyMiddleware`). Redis `idem:{key}` 저장소 + DB `idempotency_keys` 테이블 백업. 약 8시간.
- **Team 1 (Lobby 웹 — API-01 구독자)**: mutation 호출 시 UUIDv4 생성 헤더 부착. Zustand action 래퍼 유틸 1개. 약 2시간.
- **Team 4 (CC — API-05 WebSocket 구독자, API-01도 부분 호출)**: Flutter HTTP 인터셉터 + WS command wrapper에 UUID 필드. 약 3시간.
- **DATA-04 연계**: `idempotency_keys` 테이블 신설 필요 → **별도 CCR-DRAFT-team2-20260410-data-idempotency-audit.md 로 분리**.
- **마이그레이션**: 없음 (옵션 헤더, 기존 클라는 영향 없음).

## 대안 검토

1. **서버 측 요청 해시만 사용** — 클라이언트가 키를 관리하지 않으므로 간단하나, 정상 UI 재전송(사용자가 한번 더 눌렀을 때)과 네트워크 재시도를 구분하지 못함. 탈락.
2. **데이터베이스 unique constraint만** — 자원별 unique 제약으로 중복 방지. 하지만 응답 재생이 불가능해 클라이언트가 "정말로 성공했나"를 다시 조회해야 함. 탈락.
3. **분산 트랜잭션 (2PC)** — 과도한 복잡도. 탈락.
4. **Idempotency-Key 헤더 (채택)** — RFC 초안(draft-ietf-httpapi-idempotency-key-header) 준수, Stripe 등 업계 표준.

## 검증 방법

- **단위**: `IdempotencyMiddleware` 테스트 — 동일 키 재요청 시 캐시된 응답, 상이한 바디 시 409
- **통합**: `POST /tables/{id}/seat/assign` 을 동일 UUID로 2회 호출 → 한 번만 좌석 할당되고 두 번째는 캐시 응답
- **부하**: Redis 장애 시 DB fallback 동작, p95 오버헤드 <5ms

## 승인 요청

- [ ] Conductor 승인
- [ ] Team 1 기술 검토 (Lobby 호출부)
- [ ] Team 4 기술 검토 (CC HTTP/WS 래퍼)
- [ ] 종속 CCR (`data-idempotency-audit`) 동시 승인
