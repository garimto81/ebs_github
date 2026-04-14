# docs/ — Conductor 문서

> Conductor(Team 0) 소유. 상위 전략/계획/보고/백로그만. 행동 명세·API·Data는 `../contracts/` 에 있다.

## 구조

```
docs/
├── 00-reference/          외부 레퍼런스 (PokerGFX, WSOP 프로덕션)
├── 01-strategy/           PRD-EBS_Foundation.md (SSOT)
├── 05-plans/              실행 계획 + ccr-inbox/
├── 06-reports/            완료 보고서
├── backlog/               팀별 백로그 (conductor/team1~4)
├── mockups/, images/      공유 그래픽 자산
```

## 온보딩 읽기 순서

1. **전체 규칙**: `../CLAUDE.md` — 팀 구조, CCR 프로세스, WSOP LIVE 정렬 원칙
2. **SSOT**: `01-strategy/PRD-EBS_Foundation.md` (v41.0.0)
3. **용어/계약**: `../contracts/README.md` → `contracts/specs/BS-00-definitions.md`
4. **담당 팀 진입**:
   - Lobby/Frontend → `../team1-frontend/CLAUDE.md`
   - Backend/BO → `../team2-backend/CLAUDE.md`
   - Game Engine → `../team3-engine/CLAUDE.md`
   - Command Center → `../team4-cc/CLAUDE.md`

## 참고 자료

- `00-reference/WSOP-Production-Structure-Analysis.md` — 19종 그래픽 데이터 소스 분류
- `00-reference/PokerGFX-User-Manual.md`는 용량상 `C:/claude/ebs-archive-backup/07-archive/vendor-manuals/` 로 이동 예정 (Phase F)
- PokerGFX 역설계: `C:/claude/ebs-archive-backup/07-archive/legacy-repos/ebs_reverse/`

## 문서 표준

모든 문서는 WSOP LIVE Confluence 표준을 따른다 (Edit History + 개요 + 상세 + 검증/예외). 상세: `../CLAUDE.md > 문서 표준`.
