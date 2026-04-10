# Google Docs 대용량 변환 수정 검증 계획

## 목표

수정된 `converter.py`와 `cli.py`가 PRD-0004 (3977개 batchUpdate 요청)를 100% Google Docs에 업로드하는지 검증하고, 수정사항을 git commit으로 보존한다.

## 배경

Google Docs API는 batchUpdate 요청 수에 제한이 있어, 대용량 마크다운 변환 시 요청을 분할 배치로 처리해야 한다.

### 수정 내용

1. **converter.py**: batchUpdate를 300개 단위 배치로 자동 분할
   - `create_google_doc()`: 300개 단위로 requests 리스트 분할
   - `update_google_doc()`: 각 배치를 순차 실행

2. **cli.py**: Windows 콘솔 출력 개선
   - `line_buffering=True` 설정으로 실시간 출력 보장

## 구현 범위

| 항목 | 상세 |
|------|------|
| 대상 파일 | `C:/claude/lib/google_docs/converter.py`, `C:/claude/lib/google_docs/cli.py` |
| 테스트 대상 문서 | `C:/claude/ebs/docs/01_PokerGFX_Analysis/PRD-0004-EBS-Server-UI-Design.md` |
| Google Docs 대상 | `1y_g_h-5aso4aQgw_C5YcE8g9c5kFXYB-78mfFd5aDdk` |

## 영향 파일

### 수정됨
- `C:/claude/lib/google_docs/converter.py` — 배치 분할 로직
- `C:/claude/lib/google_docs/cli.py` — line_buffering 추가

### 테스트 대상
- `C:/claude/ebs/docs/01_PokerGFX_Analysis/PRD-0004-EBS-Server-UI-Design.md` (3977개 콘텐츠 요청)

## 위험 요소

1. **Google API 토큰 만료**: 배치 처리 중 토큰 재인증 필요 가능
   - 완화: 토큰 갱신 로직은 기존 인증 모듈에서 처리

2. **배치 간 인덱스 추적 오류**: 각 배치의 현재_인덱스 초기화 실패 시 위치 이동 오류 발생
   - 완화: 배치 실행 전 인덱스 검증 로직 확인

3. **부분 실패 감지 어려움**: 14개 배치 중 일부만 실패 시 탐지 어려움
   - 완화: 각 배치 결과 로그 출력 (현재 구현)

## 검증 단계

### Step 1: git commit (수정 파일 보존)

```powershell
cd C:/claude
git add lib/google_docs/converter.py lib/google_docs/cli.py
git commit -m "fix: batchUpdate 300개 단위 분할 + line_buffering 추가"
```

**성공 기준**: 커밋 메시지 확인

### Step 2: PRD-0004 업로드 실행

```powershell
cd C:/claude
python -m lib.google_docs update `
  1y_g_h-5aso4aQgw_C5YcE8g9c5kFXYB-78mfFd5aDdk `
  C:/claude/ebs/docs/01_PokerGFX_Analysis/PRD-0004-EBS-Server-UI-Design.md
```

**시간 목표**: 3~5분 (14개 배치 × 평균 200ms/배치)

### Step 3: 배치 진행률 출력 확인

기대 출력:
```
배치 1/14 완료 (콘텐츠 300 요청)
배치 2/14 완료 (콘텐츠 300 요청)
...
배치 14/14 완료 (콘텐츠 77 요청)
```

**성공 기준**: 모든 배치 메시지 표시 확인

### Step 4: 최종 메시지 확인

기대 출력:
```
콘텐츠 추가됨: 3977 요청
문서 ID: 1y_g_h-5aso4aQgw_C5YcE8g9c5kFXYB-78mfFd5aDdk
URL: https://docs.google.com/document/d/1y_g_h-5aso4aQgw_C5YcE8g9c5kFXYB-78mfFd5aDdk/edit
```

**성공 기준**: 3977개 요청 모두 처리됨을 명시하는 메시지 출력

### Step 5: Google Docs 최종 확인 (수동)

- Google Docs URL 접속
- 콘텐츠 끝부분 스크롤 확인
- "콘텐츠 추가됨" 마크 표시 확인

## 성공 기준 (Acceptance Criteria)

| # | 항목 | 판정 기준 |
|---|------|----------|
| 1 | 배치 분할 로직 | 14개 배치가 모두 실행됨 (출력에 "배치 N/14" 메시지 14회 표시) |
| 2 | 요청 수 일치 | "콘텐츠 추가됨: 3977 요청" 정확히 출력 |
| 3 | Google Docs 반영 | URL 열람 가능 + 콘텐츠 추가됨 마크 표시 |
| 4 | git 보존 | `git log` 에서 커밋 확인 |

## 커밋 전략

**Conventional Commit**:
```
fix: 대용량 batchUpdate 300개 단위 배치 분할

- converter.py: create_google_doc/update_google_doc 배치 처리
- cli.py: Windows line_buffering=True 추가로 실시간 출력 보장
- PRD-0004 (3977 요청) 100% 업로드 검증 완료

Closes: #gdocs-batch-limit
```

---

**Version**: 1.0.0 | **Updated**: 2026-02-23
