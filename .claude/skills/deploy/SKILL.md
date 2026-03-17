---
name: deploy
version: 1.1.0
description: >
  This skill should be used when the user requests version updates, Docker rebuilds, or deployment workflows.
triggers:
  keywords:
    - "deploy"
    - "/deploy"
    - "배포"
    - "버전 업데이트"
    - "docker rebuild"
---

# /deploy - Version Update & Docker Rebuild

버전 업데이트와 Docker 컨테이너 리빌드를 단일 워크플로우로 실행한다.

## Usage

```
/deploy                        # Interactive mode
/deploy patch                  # Bump patch + rebuild
/deploy minor                  # Bump minor + rebuild
/deploy major                  # Bump major + rebuild
/deploy 2.3.4                  # Set version + rebuild
/deploy --docker-only          # Skip version, rebuild only
/deploy --version-only         # Version only, skip Docker
/deploy patch --no-cache       # Rebuild without cache
```

## 옵션

| 옵션 | 설명 |
|------|------|
| `--docker-only` | 버전 업데이트 스킵, Docker 리빌드만 |
| `--version-only` | 버전 업데이트만, Docker 스킵 |
| `--no-cache` | Docker build without cache |
| `--no-commit` | 버전 커밋 스킵 |

## Semantic Versioning

| Bump | 사용 시점 | 예시 |
|------|----------|------|
| **patch** | 버그 수정 | 1.0.0 -> 1.0.1 |
| **minor** | 새 기능 | 1.0.0 -> 1.1.0 |
| **major** | Breaking changes | 1.0.0 -> 2.0.0 |

## 워크플로우

### Step 1: Version Update (`--docker-only` 아닌 경우)
1. 프로젝트 파일에서 현재 버전 감지
2. 입력 기반 새 버전 계산
3. 모든 관련 파일 업데이트: `package.json`, `pyproject.toml`, `CLAUDE.md` 등
4. 버전 커밋 (`--no-commit` 아닌 경우): `chore(release): bump version to X.Y.Z`

### Step 2: Docker Rebuild (`--version-only` 아닌 경우)
1. `docker-compose down --remove-orphans` (컨테이너 중지/제거)
2. `docker-compose build [--no-cache]` (이미지 리빌드)
3. `docker-compose up -d` (컨테이너 시작)
4. `docker-compose ps` (헬스 체크)

### Step 3: Summary
- 버전 변경 사항 출력
- 컨테이너 상태 표시
- 이슈 리포트

## 안전 규칙

- **major 버전 범프**: 실행 전 확인 요청
- **커밋 전**: diff 표시
- **컨테이너 재시작 후**: 헬스 체크 필수
- **미저장 데이터 경고**: 컨테이너에 unsaved data 존재 시 경고

상세: `.claude/commands/deploy.md`
