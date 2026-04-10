# EBS Contracts — 계약 관리

> 이 디렉토리는 Conductor(Team 0)가 단독 소유합니다. 팀 세션에서 직접 수정 금지.

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-10 | 신규 작성 | 5팀 구조 재설계 — contracts/ 도입 |

## 구조

| 디렉토리 | 내용 | 파일 수 |
|----------|------|---------|
| `api/` | API 계약 (API-01~06) | 7 |
| `data/` | 데이터 스키마 (DATA-01~06 + PRD) | 8 |
| `specs/` | 행동 명세 (BS-00~07) | 8 dirs |

## 소유권 규칙

- **Conductor만 수정 가능** — 모든 팀은 읽기 전용
- 변경 필요 시 CCR(Contract Change Request) 프로세스 따름

## CCR 프로세스

1. 팀이 계약 변경 필요 발견
2. `docs/05-plans/CCR-{NNN}-{제목}.md` 작성
3. Conductor 검토 + 영향받는 팀 통보
4. 영향팀 승인 후 contracts/ 수정
5. Edit History 테이블 업데이트
6. commit message에 `[CCR-NNN]` 포함

## 참조 방식

각 팀의 CLAUDE.md에서 1줄 포인터로 참조:
```
계약 참조: ../../contracts/api/ (읽기 전용)
```

별도 스텁 파일(api-refs 등) 생성 금지 — drift 방지.
