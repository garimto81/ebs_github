# CCR-022: API-03 RFID HAL 에러 복구 및 생명주기 시나리오 보강

| 필드 | 값 |
|------|-----|
| **상태** | APPLIED (2026-04-10) |
| **제안팀** | team4 |
| **제안일** | 2026-04-10 |
| **처리일** | 2026-04-10 |
| **영향팀** | team2 |
| **변경 대상** | `contracts/api/API-03-rfid-hal-interface.md` |
| **변경 유형** | modify |

## 변경 근거

현재 API-03는 IRfidReader 인터페이스, 이벤트 카탈로그, Mock HAL 전용 API까지 프로덕션 준비 수준으로 정의되어 있으나(상세도 ⭐⭐⭐⭐⭐), **리더 생명주기 중 장애 복구 시나리오**가 빈약하다. 특히 다음 항목이 필요: (1) 시리얼 UART 연결 끊김 감지 및 자동 재연결 정책, (2) 안테나 튜닝 실패 시 재시도 절차, (3) ST25R3911B → ST25R3916 마이그레이션 경로 참조, (4) 펌웨어 버전 mismatch 감지, (5) 동시 다중 리더 시 충돌 해결. 이는 라이브 방송 환경에서 RFID 리더 장애가 **즉시 방송 중단**으로 이어질 수 있기 때문에 CRITICAL한 계약 공백이다.

## 적용된 파일

- `contracts/api/API-03-rfid-hal-interface.md`

## 원본 Draft

`docs/05-plans/ccr-inbox/archived/CCR-DRAFT-team4-20260410-api03-hal-lifecycle.md` 참조

## 체크리스트

- [x] contracts/ 편집 완료
- [ ] 영향팀(team2) 개별 확인
- [ ] 통합 테스트 업데이트 (`integration-tests/`)
- [ ] git commit `[CCR-022] API-03 RFID HAL 에러 복구 및 생명주기 시나리오 보강`
