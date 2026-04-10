# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository

| 레포 | 원격 | 역할 | 작업 범위 |
|------|------|------|----------|
| **`C:/claude/ebs/`** | `garimto81/ebs` | **기획 레포** — 독립적 PRD, 운영 도구, 업체 관리 | 

## Key Documents

| 문서 | 경로 | 용도 |
|------|------|------|
| **Foundation PRD** | `docs/01-strategy/PRD-EBS_Foundation.md` | EBS Core(3입력→오버레이) + API 계층구조 기획서 (v38.0.0) |
| **프로덕션 구조 분석** | `docs/00-reference/WSOP-Production-Structure-Analysis.md` | EBS 범위 정의 근거 — 프로덕션 3단계 + Graphics 3계층 |
| **Production Plan V2** | `docs/00-reference/2026-WSOP-Production-Plan-V2.pdf` | WSOP 방송 프로덕션 원본 (136p, Graphics Package p.48-76) |
| Production Plan Graphics | `docs/00-reference/production-plan-graphics/` | PDF에서 추출한 그래픽 SAMPLE 이미지 22종 |
| **행동 명세** | `docs/02-behavioral/` | 기능별 모든 경우의 수 + 유저 스토리 (BS-00~07) |
| 게임 PRD | `docs/04-rules-games/games/PRD-GAME-01~04.md` | 22종 게임 규칙 가이드 (Confluence 발행) |
| 역설계 문서 | `C:\claude\ebs_reverse\docs\02-design\pokergfx-reverse-engineering-complete.md` | pokerGFX 역설계 문서 |

> 아카이빙: `docs/07-archive/` — Console UI, DB Schema, 분석, 계획서, 보고서 등
> UI 설계: `C:\claude\ebs_ui\` — Action Tracker, Console, Skin Editor 상세 설계

## 문서 작성 표준 — WSOP LIVE 동일 준수 (CRITICAL)

**모든 EBS 문서는 WSOP LIVE Confluence 문서 표준을 정확히 따른다.**
표준 원본: `C:\claude\wsoplive\docs\confluence-mirror\` (1,361페이지 미러)

### 필수 구조

1. **Edit History 테이블** — 문서 최상단 필수
   ```markdown
   | 날짜 | 항목 | 내용 |
   |------|------|------|
   | 2026-04-02 | 신규 작성 | 초기 버전 |
   ```
2. **개요** — 1~3줄 목적 요약
3. **상세 내용** — 기능별/화면별 분리, 최대 3단계 헤더 (`# ## ###`)
4. **검증/예외** — 유효성 규칙, 예외 케이스, 에러 메시지

### 상세도 규칙

- 기능 설명은 **모든 경우의 수** 열거 (경우의 수 매트릭스 테이블 필수)
- 조건부 로직은 중첩 목록 또는 "if-else" 구조로 명시
- 상태값은 반드시 **테이블로 정의** (상태명 + 설명 + 전환 조건)
- 트리거는 **발동 주체 명시** — CC 수동 / RFID 자동 / 게임 엔진 자동 구분
- UI에 노출되는 텍스트는 **영문 우선** + 한글 설명 병행
- 수치/규칙은 정확히 기술 (예: "8~20자", "99.5% 이상")

### 표기법

| 요소 | 형식 |
|------|------|
| 중요 용어/상태값 | **굵게** |
| API 필드명/코드 | `백틱` |
| 폐기된 내용 | ~~취소선~~ + Edit History 기록 |
| 참고/주의 | `> 참고:` 또는 `> 주의:` blockquote |
| 예시 | `예:` 또는 `예시:` 로 시작 |
| 미정 항목 | `TBD` 명시 |
| 테이블 | 최대 4열 ("항목-내용-조건-참고" 구조) |

### 날짜/버전

- 날짜: `YYYY-MM-DD` 형식
- Edit History 항목: "범주 → 섹션 → 소제목" (최대 3단계)
- 변경 동사: "추가/수정/삭제/변경" 명시

### 이미지

- 기능 기획서에 스크린샷/목업 **필수** 포함
- 파일명: `{문서명}-{기능명}.png`
- 이미지 없으면 텍스트 대체 설명 (빈 참조 금지)

## Spec Gap 프로세스 (CRITICAL)

구현 중 기획 문서(BS/API/DATA)에 명시되지 않은 판단이 필요한 경우, **임의 구현 금지**. 다음 절차를 따른다:

1. `docs/qa/{앱}/QA-{앱}-03-spec-gap.md`에 Gap 항목 추가
2. 항목 형식: `GAP-{앱 약자}-{번호}` (예: GAP-L-001, GAP-CC-001)
3. 임시 구현(workaround) 수행 + 문서에 workaround 내용 명시
4. Status: **OPEN** (기획 보강 필요) 또는 **RESOLVED** (확인 완료)

### 필수 기록 항목

| 항목 | 설명 |
|------|------|
| **발견일** | YYYY-MM-DD |
| **심각도** | Critical / Medium / Low |
| **관련 문서** | 누락이 발견된 BS/API/DATA 문서 + 섹션 |
| **누락 내용** | 기획 문서에 없는 구체적 시나리오/조건/흐름 |
| **발생한 버그** | 임의 구현으로 인해 발생한 실제 문제 (있을 경우) |
| **임시 구현** | workaround 코드/로직 설명 |
| **기획 보강 요청** | 어떤 문서의 어떤 섹션에 무엇을 추가해야 하는지 |

### Gap 문서 위치

| 앱 | 경로 |
|---|------|
| Lobby | `docs/qa/lobby/QA-LOBBY-03-spec-gap.md` |
| Command Center | `docs/qa/commandcenter/QA-CC-03-spec-gap.md` |
| Graphic Editor | `docs/qa/graphic-editor/QA-GE-03-spec-gap.md` |

### 금지

- 기획 문서에 없는 edge case를 묵시적으로 구현 금지
- Gap 문서 없이 workaround 코드 커밋 금지
- RESOLVED 처리 시 관련 기획 문서 업데이트 없이 종료 금지

## Games PRD 규칙

`docs/00-prd/games/` 문서는 Confluence 업로드 대상이다.

- Markdown 링크 `[text](url)`, 앵커 링크 `[text](#anchor)` 금지
- 다른 문서명(파일명, 문서 제목) 언급 금지
- 참조가 필요한 내용은 이 문서 안에서 직접 설명으로 대체
- 각 문서는 다른 문서의 존재를 모르더라도 이해 가능해야 함

