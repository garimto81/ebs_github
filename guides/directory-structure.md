# 디렉토리 구조

## main 브랜치

```
planning_ebs/
  ├── 05_Documents/    # 제품 스펙 (PoC → MVP → ...)
  ├── 08_Rules/        # 포커 규칙 (범용)
  ├── guides/          # 일하는 방식 가이드
  └── ...              # 기획자가 추가하는 기타 문서 폴더
```

## working 브랜치

```
planning_ebs/
  ├── 05_Documents/
  ├── 08_Rules/
  ├── guides/
  ├── backlogs/        # 협업 일감 (Epic/Story) — working 브랜치에서 생성
  └── ...
```

## release 브랜치

```
planning_ebs/
  ├── 05_Documents/
  ├── 08_Rules/
  ├── guides/
  ├── backlogs/
  ├── published/
  │     └── v0.1.0/    # 딜리버리 확정 문서 스냅샷
  │           ├── 05_Documents/
  │           ├── 08_Rules/
  │           ├── backlogs/
  │           └── ...
  └── ...
```

## 각 디렉토리 역할

### 기획 문서 (05_Documents/, 08_Rules/, ...)

- 기획자가 작성하는 컨셉/규칙/스펙 문서
- 폴더 구조는 기획자가 자유롭게 추가 가능
- 05, 08은 현재 존재하는 폴더일 뿐, 고정된 것이 아님

### backlogs/

- `/kickoff` 스킬로 생성되는 협업 일감
- Epic/Story 구조
- Jira에 업로드하여 관리
- **working 브랜치에서만 존재** (main에는 없음)

### guides/

- 이 저장소에서 일하는 방식에 대한 가이드
- 브랜치 전략, 릴리즈 워크플로우, 디렉토리 구조 등
