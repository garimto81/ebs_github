# 네이밍 규칙

## 파일/폴더

| 대상 | 규칙 | 예시 |
|------|------|------|
| 기획 문서 폴더 | 자유 (기획자 재량) | `05_Documents`, `08_Rules`, `Design` |
| 기획 문서 파일 | 자유 (기획자 재량) | `PRD-GAME-01-flop-games.md`, `poc-scenario.prd.md` |
| 백로그 파일 | `epic-{슬러그}.md` | `epic-broadcast-setup.md` |
| 가이드 파일 | `kebab-case.md` | `branch-strategy.md` |

## 브랜치

| 패턴 | 용도 | 예시 |
|------|------|------|
| `working/vX.Y.Z` | 협업 진행 중 | `working/v0.1.0` |
| `release/vX.Y.Z` | 딜리버리 완료 확정본 | `release/v0.1.0` |
| `foundation/{설명}` | 기반 구조 작업 | `foundation/init-collaboration` |
