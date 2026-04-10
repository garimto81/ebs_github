# /checklist - YAML 체크리스트 관리

프로젝트별 체크리스트를 YAML로 관리하고 서브 에이전트 작업을 추적합니다.

## Usage

```
/checklist                  현재 상태 확인
/checklist init             새 프로젝트에 checklist.yaml 생성
/checklist add <task>       작업 추가
/checklist done <id>        작업 완료 처리
/checklist assign <id> <agent>  에이전트 할당
/checklist stats            통계 출력
```

---

## 워크플로우

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  /checklist  │────▶│ YAML 확인   │────▶│ 작업 할당    │
└──────────────┘     └──────────────┘     └──────┬───────┘
                                                  │
                                                  ▼
                                          ┌──────────────┐
                                          │ 서브에이전트 │
                                          │ 작업 수행    │
                                          └──────┬───────┘
                                                  │
                                                  ▼
                                          ┌──────────────┐
                                          │ YAML 업데이트│
                                          └──────────────┘
```

---

## 명령어 상세

### /checklist (기본)

현재 프로젝트의 체크리스트 상태를 확인합니다.

**수행 작업:**
1. 현재 디렉토리에서 `checklist.yaml` 찾기
2. 진행 중/대기 중/완료 작업 표시
3. 통계 출력

**출력 형식:**
```
## 📋 Checklist: {project}

### 🔄 In Progress
- [TASK-001] 작업 제목 (python-dev)

### 📝 Pending (3)
- [TASK-002] 다음 작업 (high)
- [TASK-003] 또 다른 작업 (medium)

### ✅ Completed (5)
└─ 최근: [TASK-000] 완료된 작업

### 📊 Stats
Total: 9 | Done: 5 | Progress: 1 | Pending: 3
```

---

### /checklist init

새 프로젝트에 체크리스트를 초기화합니다.

**수행 작업:**
1. `.claude/templates/checklist.yaml` 복사
2. 프로젝트명, 타임스탬프 설정
3. `{project}/checklist.yaml` 생성

---

### /checklist add <task>

새 작업을 추가합니다.

**예시:**
```
/checklist add "사용자 인증 기능 구현"
/checklist add "테스트 커버리지 80% 달성" --priority high --category test
```

**수행 작업:**
1. 새 ID 생성 (TASK-NNN)
2. `pending` 목록에 추가
3. `stats.total`, `stats.pending` 업데이트

---

### /checklist done <id>

작업을 완료 처리합니다.

**예시:**
```
/checklist done TASK-001
```

**수행 작업:**
1. `current_task` 또는 `pending`에서 작업 찾기
2. `completed` 목록으로 이동
3. 결과 정보 기록 (files_changed, commits)
4. `agent_logs`에 로그 추가
5. 통계 업데이트

---

### /checklist assign <id> <agent>

작업에 에이전트를 할당합니다.

**예시:**
```
/checklist assign TASK-001 python-dev
/checklist assign TASK-002 test-engineer
```

**에이전트 매핑:**
| 키워드 | 에이전트 |
|--------|----------|
| python | python-dev |
| ts, typescript | typescript-dev |
| test | test-engineer |
| review | code-reviewer |
| docs | docs-writer |
| debug | debugger |
| security | security-auditor |
| db, database | database-specialist |

---

## 자동 동작

### 서브 에이전트 실행 시

Task tool로 서브 에이전트 실행 전:
1. `current_task` 업데이트
2. `agent_logs`에 시작 로그

### 서브 에이전트 완료 시

서브 에이전트 결과 반환 후:
1. 결과를 YAML에 기록
2. 성공 시 `completed`로 이동
3. 실패 시 `current_task` 유지 + 에러 로그

---

## 파일 위치

| 항목 | 경로 |
|------|------|
| 템플릿 | `.claude/templates/checklist.yaml` |
| 프로젝트별 | `{project}/checklist.yaml` |

---

## YAML 구조

```yaml
version: "1.0"
project: "project-name"
updated_at: "2025-12-19T15:00:00"

current_task:
  id: "TASK-001"
  title: "작업 제목"
  status: "in_progress"
  agent: "python-dev"

pending:
  - id: "TASK-002"
    title: "대기 작업"
    priority: "high"

completed:
  - id: "TASK-000"
    title: "완료 작업"
    agent: "python-dev"
    result:
      success: true
      files_changed: ["src/main.py"]

agent_logs:
  - timestamp: "2025-12-19T15:00:00"
    agent: "python-dev"
    task_id: "TASK-001"
    action: "작업 완료"
    status: "success"

stats:
  total: 5
  completed: 2
  in_progress: 1
  pending: 2
```

---

## Best Practices

1. **작업 시작 전**: `/checklist`로 현재 상태 확인
2. **작업 추가 시**: 우선순위와 카테고리 명시
3. **에이전트 할당**: 작업 유형에 맞는 에이전트 선택
4. **완료 처리**: 변경 파일과 커밋 정보 포함
5. **세션 종료 전**: `/checklist stats`로 진행 상황 확인
