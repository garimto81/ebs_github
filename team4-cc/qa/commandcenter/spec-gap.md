# Team 4 CC — Spec Gaps

> team4-cc/CLAUDE.md §Spec Gap 규칙:
> 구현 중 기획 문서에 명시되지 않은 판단이 필요하면 여기에 `GAP-CC-{NNN}` 항목으로
> 기록하고, 임시 구현을 문서화한 뒤, 기획 보강 또는 CCR 재제출로 RESOLVED 처리.

## OPEN

### GAP-CC-001 · API-05 MessagePack format negotiation 미기재
- **발견일**: 2026-04-10
- **심각도**: Medium
- **관련 문서**: `contracts/api/API-05-websocket-events.md`, `docs/05-plans/ccr-inbox/promoting/CCR-023-api05-messagepack.md`
- **누락 내용**:
  CCR-023이 API-05 JSON envelope 정의까지만 반영되었고, `?format=msgpack`
  query parameter 협상 섹션(직렬화 선택, Fallback 정책, 타입 매핑 상세)이
  문서화되지 않았다. 현재 API-05는 JSON envelope만 정의하므로 Flutter CC가
  MessagePack 직렬화를 활성화할 수 있는 계약 근거가 없다.
- **임시 구현**:
  - `lib/foundation/configs/features.dart` 에 `enableMsgpack = false` 유지
  - `bo_websocket_client.dart` 는 JSON만 송수신
  - WSOP Fatima.app의 MessagePack 자산은 Phase 2에서 재활용 예정
- **기획 보강 요청 / CCR 재제출안**:
  1. Team 2 FastAPI에서 `msgpack` 라이브러리 통합 PoC 수행
  2. Dart `messagepack` 패키지로 상호 운용성 테스트
  3. 위 2개 통과 시 `CCR-DRAFT-team4-YYYYMMDD-api05-msgpack-negotiation-reapply.md` 제출하여 API-05 §직렬화 협상, §MessagePack 스키마, §Fallback 정책 섹션 보강
  4. 승인 후 `Features.enableMsgpack = true`로 flip
- **Phase 1 영향**: 없음 (JSON envelope로 기능 달성 가능). Phase 2 페이로드 최적화 시 이득.

## RESOLVED

_현재 RESOLVED 항목 없음_
