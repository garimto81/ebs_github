# Team 1: Frontend Web — CLAUDE.md

## Role

Login UI + Lobby + Settings (Game/Statistics/Output 라우팅)

**기술 스택**: React / Next.js (TBD)

> Graphic Editor(Skin/Overlay 편집)는 Flutter 기반 → Team 4 소속.
> 이 팀의 Settings는 비시각 설정(Game/Stats/Output 라우팅)만 담당.

## 소유 경로

| 경로 | 내용 |
|------|------|
| `qa/lobby/` | Lobby QA 전략, 체크리스트, spec-gap |
| `ui-design/` | UI-00 (디자인 시스템), UI-01 (Lobby), UI-03 (Settings) |
| `src/` | React/Next.js 소스 코드 |

## 계약 참조 (읽기 전용 — 수정 금지)

- 행동 명세: `../../contracts/specs/` (BS-01-auth, BS-02-lobby, BS-03-settings)
- API 계약: `../../contracts/api/` (API-01, API-05 ws/lobby 채널, API-06 Auth)
- 데이터 스키마: `../../contracts/data/` (DATA-02 Entities)
- 공유 정의: `../../contracts/specs/BS-00-definitions.md`

## Settings 범위 (Team 1)

- **Game**: blind 구조, 타이머, 기본 규칙 설정
- **Statistics**: 통계 표시 옵션
- **Output**: NDI/HDMI 포트 라우팅 기본 설정

> Overlay/Skin 시각 편집은 Team 4 Graphic Editor 담당 (Flutter/Rive 렌더링 필요)

## API 경계

- 모든 HTTP 호출은 Backend (Team 2)로만 전송
- CC, Game Engine과의 직접 통신 금지
- WebSocket `ws://[host]/ws/lobby` — 모니터링 전용 (write 명령 없음)

## Spec Gap

`qa/lobby/QA-LOBBY-03-spec-gap.md` — 형식: `GAP-L-{NNN}`

## 금지

- `../../contracts/` 파일 수정 금지 (CCR 프로세스 경유)
- `../team2-backend/`, `../team3-engine/`, `../team4-cc/` 접근 금지
- Overlay/Skin 관련 구현 금지 (Team 4 영역)

## Build

> 추후 React/Next.js 프로젝트 설정 시 업데이트
