# Team 1 Frontend 문서 인덱스

> 목적: 22개 문서를 일일이 열지 않고도 "무엇이 어디 있는지" 한 화면에서 파악. 탐색 치트시트로 O(1) 점프.
> 최종 갱신: 2026-04-14 (qa/ 폴더 삭제 반영)

## 한눈 지도

| 범주 | 파일 | 라인 | 1줄 존재 이유 |
|------|------|:---:|--------------|
| 팀 경계 | `CLAUDE.md` | 169 | 팀 범위·금지·Hook 스코프 가드 입력 |
| TOC/Setup | `README.md` | 156 | 기술 스택·setup·dir 구조·빌드 명령 |
| 아키텍처 | `ui-design/UI-A1-architecture.md` | 930 | 구현 아키텍처 SSOT (Router/Pinia/API/WS/Mock/i18n) |
| 디자인 | `ui-design/UI-00-design-system.md` | 574 | 디자인 토큰·Quasar 컴포넌트 매핑·WCAG |
| Lobby 화면 | `ui-design/UI-01-lobby.md` | 1420 | 3계층 + Player 독립 레이어 화면 설계 SSOT |
| Settings 화면 | `ui-design/UI-03-settings.md` | 497 | 6탭 와이어프레임 (Team 1/4 경계) |
| GE 화면 | `ui-design/UI-04-graphic-editor.md` | 887 | Graphic Editor 허브 와이어프레임 (CCR-011) |
| Lobby 행동 | `specs/BS-02-lobby/BS-02-00-overview.md` | 1212 | Lobby 행동 명세 SSOT (FSM·불변식) — BS-03/08 관례 정렬 (2026-04-14 rename) |
| └ | `BS-02-02-event-flight.md` | 135 | EventFlightStatus enum (0/1/2/4/5/6) |
| └ | `BS-02-03-table.md` | 138 | TableFSM 5상태 × is_pause 축 |
| Settings 행동 | `specs/BS-03-settings/BS-03-00-overview.md` | 156 | 6탭 아키텍처 총괄 + 글로벌 원칙 |
| └ | `BS-03-01-outputs.md` | 146 | 해상도·Pipeline(NDI/RTMP/SRT/DIRECT)·Mode |
| └ | `BS-03-02-gfx.md` | 251 | 배치·카드·애니메이션·Active Skin·시각 asset 메타 (CCR-025) |
| └ | `BS-03-03-display.md` | 121 | 수치 형식 (Blinds·Precision·Mode) |
| └ | `BS-03-04-rules.md` | 146 | 게임 규칙 (Bomb Pot·Straddle·Sleeper)·BlindDetailType enum |
| └ | `BS-03-05-stats.md` | 138 | Equity·Outs·Leaderboard·Score Strip |
| └ | `BS-03-06-preferences.md` | 108 | Table 인증·진단·Export 폴더 |
| GE 행동 | `specs/BS-08-graphic-editor/BS-08-00-overview.md` | 142 | 허브 역할·페르소나·UC (CCR-011) |
| └ | `BS-08-01-import-flow.md` | 137 | .gfskin ZIP 업로드 FSM (GEI-01~08) |
| └ | `BS-08-02-metadata-editing.md` | 125 | 메타데이터 편집 필드 (GEM-01~25) |
| └ | `BS-08-03-activate-broadcast.md` | 191 | Activate + skin_updated WS 계약 (GEA-01~06) |
| └ | `BS-08-04-rbac-guards.md` | 157 | Admin/Operator/Viewer 게이트 (GER-01~05) |

총 **22개 문서**. 파편화는 의도적(도메인×계층). 문서가 많아 보일 때 이 인덱스만 먼저 읽을 것.

## 탐색 치트시트

구현 중 "어디를 봐야 하나" 자주 걸리는 포인트.

| 찾는 것 | 가야 할 곳 |
|---------|-----------|
| Settings GFX 탭의 상태 전환 규칙 | `specs/BS-03-settings/BS-03-02-gfx.md` |
| Table FSM 전환 조건 + is_pause 처리 | `specs/BS-02-lobby/BS-02-03-table.md` |
| Event/Flight 상태값 (enum 0/1/2/4/5/6) | `specs/BS-02-lobby/BS-02-02-event-flight.md` |
| Blind 레벨 구조·BlindDetailType enum | `specs/BS-03-settings/BS-03-04-rules.md` §5 |
| `.gfskin` ZIP 업로드 FSM | `specs/BS-08-graphic-editor/BS-08-01-import-flow.md` |
| GE Activate + WS broadcast 포맷 | `specs/BS-08-graphic-editor/BS-08-03-activate-broadcast.md` |
| RBAC Admin/Operator/Viewer 게이트 | `specs/BS-08-graphic-editor/BS-08-04-rbac-guards.md` |
| Pinia store 구조 (authStore 등 5개) | `ui-design/UI-A1-architecture.md` §3 |
| Idempotency-Key 자동 주입 위치 (CCR-019) | `ui-design/UI-A1-architecture.md` §4.1 / `src/boot/axios.ts` |
| WS seq validation + replay (CCR-021) | `ui-design/UI-A1-architecture.md` §5 |
| Mock server (MSW) 토글 방법 | `ui-design/UI-A1-architecture.md` §6 / `README.md` |
| i18n locale 추가 (ko/en/es) | `ui-design/UI-A1-architecture.md` §7 |
| 디자인 토큰·WCAG 준수 체크 | `ui-design/UI-00-design-system.md` |
| Lobby 3계층 (Series→Event→Flight→Table) 흐름 | `ui-design/UI-01-lobby.md` |
| Settings 6탭 중 어느 탭에 뭐가 있나 | `ui-design/UI-03-settings.md` (화면) + `specs/BS-03-settings/BS-03-00-overview.md` (행동) |
| GE 허브 3-Zone 배치 | `ui-design/UI-04-graphic-editor.md` |
| 팀 경계 (뭘 하면 안 되나) | `CLAUDE.md` §금지 |

## 상태 (2026-04-14)

- **qa/ 폴더 삭제됨** — QA 계층은 BS 행동명세에 흡수 방침. 검증 항목 신규 추가 시 각 BS-0X 하단 `§검증` 섹션에 기재.
- **Dead link 정리 완료** — 구 경로 `contracts/specs/BS-0X-.../` 는 팀 상대경로 `specs/BS-0X-.../` 로 일괄 갱신 (팀 내부 22건).
- **외부 dead link** — `contracts/api/API-07`, `contracts/data/DATA-07`, `team4-cc/`, `docs/backlog/_aggregate.md` 등 110건은 `CCR-DRAFT-team1-20260414-deadlink-cleanup.md` 로 Conductor 위임.
- **문서 압축 검토**: 공격적안(22→7) 기각 (대형문서 규칙 위반 + UI/BS 계층 붕괴). 중간안(22→10) 보류 — WSOP LIVE 레포 실재 확인 후 재평가 (backlog B-WSOP-LIVE-REPO).

## 유지보수 규칙

- 파일 추가/삭제/rename 시 본 INDEX.md 의 테이블·치트시트 동시 갱신 (drift 방지).
- contracts/ 직접 참조는 금지 — 팀 소유 specs/ 는 팀 내부 경로만 사용. 외부 계약은 `../contracts/api/` 등 상위 경로로만.
- 신규 문서는 기존 도메인(Lobby/Settings/GE) 중 하나에 흡수하거나, 새 도메인이면 INDEX 에 범주 신설.
