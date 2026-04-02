---
name: deliver
description: "딜리버리 — working 브랜치를 release 브랜치로 전환하고 확정 문서를 published/에 정리하는 스킬. /deliver vX.Y.Z 형태로 실행. 사용자가 딜리버리, 배포, 완료, deliver를 언급할 때 트리거."
---

# /deliver

working 브랜치의 협업이 완료되면, release 브랜치로 전환하고 확정 문서를 `published/`에 정리합니다.

## 사용법

```
/deliver v0.1.0
```

## 실행 순서

### Step 1. 현재 브랜치 확인

- `working/vX.Y.Z` 브랜치에서 실행해야 함
- working 브랜치가 아닌 경우 사용자에게 경고 후 확인
- 인자 버전과 현재 working 브랜치 버전이 일치하는지 확인

### Step 2. 검증

- `backlogs/` 디렉토리가 존재하는지 확인
- 동일 버전의 release 브랜치가 이미 존재하지 않는지 확인

### Step 3. published 디렉토리 생성

`published/vX.Y.Z/` 디렉토리를 생성하고 확정 문서를 정리합니다:
- 기획 문서 폴더들을 `published/vX.Y.Z/` 하위에 복사
- `backlogs/`도 포함
- `guides/`, `.claude/` 등 메타 파일은 제외

```
published/v0.1.0/
  ├── 05_Documents/
  ├── 08_Rules/
  ├── backlogs/
  └── ...
```

### Step 4. release 브랜치 생성

```bash
git checkout -b release/{version}
```

### Step 5. 결과 보고

- published 디렉토리에 포함된 문서 목록
- 릴리즈 버전 정보
- 포함된 문서 버전 요약

## 주의사항

- working 브랜치에서만 실행 가능
- 이미 존재하는 release 버전은 생성 불가
- published 디렉토리 생성 전 사용자에게 포함할 문서 목록 확인
