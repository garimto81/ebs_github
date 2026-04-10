# UI 설계 문서 — 네비게이션

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | UI 설계 문서 7종 초기 버전 |

---

## 개요

EBS UI 설계 문서. 3개 앱(Lobby, Command Center, Overlay)과 Settings 다이얼로그의 화면 구성, 와이어프레임, 컴포넌트를 정의한다.

## 문서 목록

| # | 문서 | 내용 | 대상 앱 |
|:-:|------|------|---------|
| 00 | [UI-00-design-system.md](UI-00-design-system.md) | 색상, 타이포, 간격, 토큰 | 전체 |
| 01 | [UI-01-lobby.md](UI-01-lobby.md) | Lobby 6화면 와이어프레임 | Lobby (웹) |
| 02 | [UI-02-command-center.md](UI-02-command-center.md) | CC 8화면 와이어프레임 | CC (Flutter) |
| 03 | [UI-03-settings.md](UI-03-settings.md) | Settings **6탭** 와이어프레임 | Settings (Lobby 하위) |
| 04 | [UI-04-overlay-output.md](UI-04-overlay-output.md) | 10개 오버레이 요소 배치 | Overlay (Flutter+Rive) |
| 05 | [UI-05-component-library.md](UI-05-component-library.md) | 재사용 컴포넌트 목록 | 전체 |
| 06 | [UI-06-skin-editor.md](UI-06-skin-editor.md) | SE 메인 + GE 8종 모드 | Lobby 내 /editor |

## 참조 관계

| 참조 문서 | 경로 |
|----------|------|
| Foundation PRD Ch.8 | `docs/01-strategy/PRD-EBS_Foundation.md` |
| BS-00 정의서 | `docs/02-behavioral/BS-00-definitions.md` |
| BS-02 Lobby | `docs/02-behavioral/BS-02-lobby/` |
| BS-03 Settings | `docs/02-behavioral/BS-03-settings/` |
| BS-05 Command Center | `docs/02-behavioral/BS-05-command-center/` |
| BS-07 Overlay | `docs/02-behavioral/BS-07-overlay/` |
| 기존 HTML 목업 | `docs/mockups/ebs-lobby-*.html`, `ebs-flow-*.html` |
