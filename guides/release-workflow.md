# 릴리즈 워크플로우

## 전체 흐름

```
기획자가 main에 선별/완성된 기획 문서를 넣음
        │
        ▼
/kickoff vX.Y.Z 실행
        │
        ▼
working/vX.Y.Z 브랜치 생성
+ backlogs/ 에 Epic/Story 생성
        │
        ▼
협업자 작업 + 피드백
(피드백에 따른 문서 수정도 working 브랜치에서)
        │
        ▼
/deliver vX.Y.Z 실행
        │
        ▼
release/vX.Y.Z (확정본 + published/vX.Y.Z/)
```

## /kickoff 스킬

```
/kickoff v0.1.0
```

### 스킬이 하는 일

1. main에서 `working/v0.1.0` 브랜치 생성
2. 저장소의 모든 기획 문서를 탐색
3. 문서 내용을 분석하여 `backlogs/`에 Epic/Story 백로그 생성
4. 백로그 인덱스(`backlogs/README.md`) 생성
5. 결과 보고

### 주의사항

- main 브랜치에서 실행해야 함
- 이미 존재하는 버전은 생성 불가
- 기존 backlogs/가 있으면 덮어쓰지 않고 확인 요청

## /deliver 스킬

```
/deliver v0.1.0
```

### 스킬이 하는 일

1. `working/v0.1.0` 브랜치에서 실행 확인
2. 백로그 존재 여부 등 검증
3. `published/v0.1.0/`에 확정 문서 정리
4. `release/v0.1.0` 브랜치 생성
5. 결과 보고

### 주의사항

- working 브랜치에서만 실행 가능
- 이미 존재하는 release 버전은 생성 불가
