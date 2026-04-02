# 브랜치 전략

이 저장소는 **문서 저장소**입니다. 코드 배포가 아닌 **문서 확정 → 일감 생성 → 딜리버리** 흐름을 따릅니다.

## 브랜치 구조

```
main
  ├─ working/v0.1.0
  ├─ working/v0.2.0
  ├─ release/v0.1.0
  └─ foundation/...
```

## main

- 기획자가 선별/완성된 기획 문서를 넣는 곳
- 기획 문서 원본이 관리되는 브랜치

## working/vX.Y.Z

- `/kickoff vX.Y.Z` 스킬로 main에서 분기
- `backlogs/` 디렉토리에 Epic/Story 일감이 생성됨
- 협업자들이 이 브랜치를 보고 작업 + 피드백
- 피드백에 따른 문서 수정도 이 브랜치에서 진행
- `/deliver vX.Y.Z` 스킬로 release 브랜치로 전환

## release/vX.Y.Z

- `/deliver` 스킬로 working 브랜치에서 전환
- 딜리버리 완료된 확정본
- `published/vX.Y.Z/` 디렉토리에 확정 문서 스냅샷 포함

## foundation/

- 협업 기반 구조, 도구, 설정 등의 작업용 브랜치

## 동시 진행

- 여러 working 브랜치가 동시에 존재할 수 있음
- 딜리버리 순서는 버전 순서와 무관 (v0.2.0이 먼저 완료될 수 있음)
