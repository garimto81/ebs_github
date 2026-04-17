---
id: B-085
title: "Flutter 모델 required 필드 BO 응답 매칭 감사"
status: DONE
completed: 2026-04-17
branch: work/team1/20260417-api-alignment
source: docs/2. Development/2.1 Frontend/Backlog.md
---

# B-085 — tools/audit_model_nullability.py 작성 + Skin 모델 방어화

## 배경

Flutter `required bool/int/String` 필드가 BO 응답에서 null/missing으로 오면 `TypeError: minified:C5 is not a subtype of type X` 발생. 로그인 후 Lobby Dashboard에서 실제 이 에러 발생 확인(스크린샷 04b-dashboard-10s 빨간 에러 박스).

## 완료 내역

### tools/audit_model_nullability.py 신규

- 모든 `lib/models/entities/*.dart`에서 required 필드 추출
- 실제 BO 응답(seed 기반)과 대조
- 응답에 없거나 null인 필드를 위험 목록으로 출력
- 15개 엔티티 × 99개 required 필드 검증

### 감사 결과 (Pre-fix)

| 모델 | 이슈 | 조치 |
|------|------|------|
| skin.dart | 5개 필드 BO 응답에 없음 (version/status/metadata/fileSize/uploadedAt) | @Default 또는 nullable |
| skin_metadata.dart | title/description required인데 metadata 자체가 nullable | @Default('') + empty() 팩토리 |
| 그 외 13개 엔티티 | 위험 0개 | — |

### 코드 변경

- `skin.dart`: version/status `@Default`, metadata/uploadedAt nullable, `safeMetadata` getter
- `skin_metadata.dart`: title/description `@Default('')`, `SkinMetadata.empty()` 팩토리
- `ge_detail_screen.dart`, `ge_hub_screen.dart`, `test/integration/model_parse_test.dart` — `skin.metadata` → `skin.safeMetadata` 치환
- 추가: `uploadedAt` nullable fallback `?? '—'`

## 검증

- `flutter analyze` — No issues found
- 스크립트 재실행: 위험 0개
