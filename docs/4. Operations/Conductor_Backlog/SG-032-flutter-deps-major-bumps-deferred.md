---
id: SG-032
title: Flutter dependency major bumps (rive 0.14, file_picker 11) — migration deferred
owner: team1
tier: backlog
status: deferred
created: 2026-05-04
related-prs: [117, 118]
---

# SG-032 — Flutter major dep bumps deferred

## 발견 경로

2026-05-04 PR 적체 처리 중 dependabot 자동 PR 2건이 main 머지 불가로 확인됨:

| PR | 패키지 | 변경 | 차단 사유 |
|----|--------|------|-----------|
| #117 | rive | 0.13.20 → 0.14.6 | `RiveFile` getter / `Rive(artboard:)` 위젯 API 변경 |
| #118 | file_picker | 8.3.7 → 11.0.2 | `Member not found: 'platform'` (3 major version skip) |

dart2js 컴파일 실패로 Docker Compose Build Verification gate 차단. team1-frontend `flutter build web` 빌드 깨짐.

## 영향 범위

### rive 0.14
- `team1-frontend/lib/features/graphic_editor/widgets/rive_preview.dart`
- Graphic Editor 미리보기 기능 (GE 프리뷰 전용 사용)

### file_picker 11
- team1-frontend 내 `FilePicker` 사용처 전수 audit 필요
- 데스크톱/Web 플랫폼별 API 분기 변경

## 차단 근거

EBS governance Mode A 한계 — "거대 dependency" 자율 제외 영역.
- 단순 패치/마이너 업데이트는 자율 머지
- breaking API change 동반 major bump 는 마이그레이션 plan 필요
- 사용자 또는 team1 세션에서 명시적 작업 필요

## 마이그레이션 plan (작업 시 참조)

### rive 0.14 마이그레이션
1. rive 0.14 changelog 확인 (RiveFile / Rive 위젯 새 API)
2. `rive_preview.dart` 재작성
3. Graphic Editor 화면에서 미리보기 동작 검증
4. team1 단위 테스트 통과
5. Docker Compose Build Verification 통과 확인

### file_picker 11 마이그레이션
1. file_picker 11 changelog 확인 (`platform` 접근자 변경)
2. `FilePicker.platform.pickFiles()` 호출 사용처 전수 grep
3. 새 API 패턴으로 재작성 (web/desktop 분기 반영)
4. 데스크톱에서 실제 파일 선택 플로우 수동 테스트
5. Docker Compose Build Verification 통과 확인

## 처리 흐름

```
2026-05-04 PR #117/#118 close (현재)
    ↓
team1 세션이 마이그레이션 plan 채택
    ↓
별도 PR 로 코드 + 의존성 함께 변경
    ↓
SG-032 close
```

## 관련

- 닫힌 PR #117 https://github.com/garimto81/ebs_github/pull/117
- 닫힌 PR #118 https://github.com/garimto81/ebs_github/pull/118
- governance Mode A 한계: `docs/2. Development/2.5 Shared/team-policy.json` `mode_a_limits`
