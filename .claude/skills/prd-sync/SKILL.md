---
name: prd-sync
version: 1.0.0
description: >
  This skill should be used when the user needs to synchronize PRD documents between Google Docs and local repository.
triggers:
  keywords:
    - "/prd-sync"
    - "PRD 동기화"
    - "Google Docs 동기화"
    - "문서 동기화"
    - "prd sync"
---

# /prd-sync — PRD 동기화 (Google Docs → 로컬)

Google Docs 마스터 문서에서 로컬 캐시(`docs/00-prd/`)로 동기화합니다.

## 실행 단계

### Step 1: 인증 확인

```bash
cd C:\claude && python -m lib.google_docs status
```
- `authenticated: true` → Step 2 진행
- `authenticated: false` → 사용자에게 OAuth 로그인 안내 후 중단

### Step 2: 동기화 실행

| 사용자 요청 | 실행 명령 |
|-------------|----------|
| `/prd-sync PRD-NNNN` | `cd C:\claude && python scripts/prd_sync.py pull --project PRD-NNNN` |
| `/prd-sync --all` | `cd C:\claude && python scripts/prd_sync.py pull --force` |
| `/prd-sync --list` | `cd C:\claude && python scripts/prd_sync.py list` |

### Step 3: 결과 확인

동기화된 캐시 파일(`tasks/prds/PRD-NNNN.cache.md`)의 `Last Synced` 타임스탬프 확인.
실패 시 에러 메시지 출력 + 원인 안내.

## 필수/금지 행동

| 필수 | 금지 |
|------|------|
| `cd C:\claude &&` 접두사 | 캐시 파일 직접 수정 |
| 인증 상태 선행 확인 | 인증 없이 동기화 시도 |
| 에러 시 상세 안내 | 조용한 스킵 |

## /auto 통합 동작

`/auto --gdocs` 실행 시 Step 2.0 (옵션 처리)에서 실행:

1. prd-syncer teammate (executor-high) 생성
2. 인증 확인 → 동기화 실행
3. Google Docs PRD → `docs/00-prd/` 로컬 동기화
4. 동기화된 PRD를 Phase 1 계획에 반영

**옵션 실패 시: 에러 출력, 절대 조용히 스킵 금지.**

## 관련 파일

| 파일 | 용도 |
|------|------|
| `.prd-registry.json` | PRD 메타데이터 레지스트리 |
| `tasks/prds/PRD-NNNN.cache.md` | 로컬 캐시 (읽기 전용) |
| `scripts/prd_sync.py` | PRD 동기화 스크립트 |
| `lib/google_docs/` | Google Docs API 모듈 |
| `.claude/commands/prd-sync.md` | 커맨드 파일 (상세 흐름도) |
