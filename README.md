# EBS 문서 아키텍처

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-02 | 신규 작성 | v3 전면 재설계 — 페르소나 순서, Confluence 동일 구조 |

---

## 구조 원칙

- **Confluence = 로컬 동일 번호** — 폴더 번호가 곧 Confluence 폴더 번호
- **페르소나 순서** — 운영자의 방송 하루 흐름대로 문서 배치
- **WSOP LIVE 문서 표준** 준수 — `C:\claude\wsoplive\docs\confluence-mirror\` 참조

---

## 전체 구조

```
docs/
├── 00-reference/                    Confluence: 00_Reference
├── 01-strategy/                     Confluence: 01_Strategy
├── 02-behavioral/                   Confluence: 02_Behavioral Specs
│   ├── BS-01-auth/                      ① 로그인
│   ├── BS-02-lobby/                     ② 테이블 설정
│   ├── BS-03-settings/                  ③ 방송 준비
│   ├── BS-04-rfid/                      ④ 덱 등록
│   ├── BS-05-command-center/            ⑤ 게임 진행
│   ├── BS-06-game-engine/               ⑥ 내부 처리
│   └── BS-07-overlay/                   ⑦ 화면 출력
├── 03-ui-design/                    Confluence: 10_UI Design
├── 04-rules-games/                  Confluence: 08_Rules
├── 05-plans/                        실행 계획서
├── 06-reports/                       완료 보고서
├── 07-archive/                      Confluence 미발행 (로컬 참조용)
├── impl/                            구현 가이드 (이관 대상)
├── api/                             API 명세 (이관 대상)
├── data/                            데이터 모델 (이관 대상)
├── testing/                         테스트 (이관 대상)
├── back-office/                     BO 명세 (이관 대상)
├── qa/                              QA (이관 대상)
└── images/                          이미지
```

---

## 폴더별 상세

### 00-reference/ — 참조 자료

PokerGFX 역설계 참조. 직접 편집하지 않음.

| Confluence | Page ID |
|-----------|---------|
| `00_Reference` | 3668901894 |

> 현재 Confluence 이름: `00_PokerGFX 분석` — UI에서 `00_Reference`로 리네임 필요

---

### 01-strategy/ — 전략 문서

| 파일 | 용도 | Confluence | Page ID |
|------|------|-----------|---------|
| `PRD-EBS_Foundation.md` | **SSOT** — EBS Core 기획서 (v38.0.0) | EBS 기초 기획서 | 3625189547 |
| `EBS-Kickoff-2026.md` | 전략 실행서 — 5-Phase / 2-시스템 | EBS Ecosystem 킥오프 기획서 | 3637936298 |
| `visual/` | Foundation 도해 HTML 5개 | — | — |

| Confluence | Page ID |
|-----------|---------|
| `01_Strategy` | 3671097416 |

> 현재 Confluence 이름: `05_Documents` — UI에서 `01_Strategy`로 리네임 필요

---

### 02-behavioral/ — 행동 명세

기능별 모든 경우의 수 + 페르소나 유저 스토리. 상세: `02-behavioral/README.md`

| 폴더 | 페르소나 여정 | Confluence | Page ID |
|------|-------------|-----------|---------|
| `BS-01-auth/` | ① 로그인한다 | BS-01 Auth | 3726868546 |
| `BS-02-lobby/` | ② 테이블을 설정한다 | BS-02 Lobby | 3726901296 |
| `BS-03-settings/` | ③ 방송을 준비한다 | BS-03 Settings | 3724443935 |
| `BS-04-rfid/` | ④ 덱을 등록한다 | BS-04 RFID | 3726901315 |
| `BS-05-command-center/` | ⑤ 게임을 진행한다 | BS-05 Command Center | 3724280058 |
| `BS-06-game-engine/` | ⑥ 시스템이 내부 처리한다 | BS-06 Game Engine | 3726901334 |
| `BS-07-overlay/` | ⑦ 시청자가 화면을 본다 | BS-07 Overlay | 3725197552 |

| Confluence | Page ID |
|-----------|---------|
| `02_Behavioral Specs` | 3726147739 |

별도 정의서:

| 파일 | 용도 | Confluence | Page ID |
|------|------|-----------|---------|
| `BS-00-definitions.md` | 용어/상태/트리거 총괄 정의 | BS-00 Definitions | 3726901277 |

---

### 04-rules-games/ — 게임 규칙

| 파일 | 용도 | Confluence | Page ID |
|------|------|-----------|---------|
| `games/PRD-GAME-01-flop-games.md` | Flop Games 12종 | [EBS] Flop Games 계열 | 3714154757 |
| `games/PRD-GAME-02-draw.md` | Draw 7종 | [EBS] Draw 계열 | 3719364859 |
| `games/PRD-GAME-03-seven-card-games.md` | Seven Card 3종 | [EBS] Seven Card Games 계열 | 3719200984 |
| `games/PRD-GAME-04-betting-system.md` | 베팅 완전 가이드 | [EBS] 베팅 완전 가이드 | 3718774893 |
| `games/references/` | WSOP 공식 PDF 4개 | — | — |
| `games/visual/` | 게임 시각화 HTML + 스크린샷 | — | — |

| Confluence | Page ID |
|-----------|---------|
| `08_Rules` | 3714548018 |

---

### 03-ui-design/ — UI 설계

설계 자산은 팀 폴더에 통합됨: `team4-cc/ui-design/reference/`, `team1-frontend/ui-design/reference/`

| ebs_ui 프로젝트 | Confluence | Page ID |
|----------------|-----------|---------|
| `ebs-action-tracker/` | EBS UI Design Action Tracker | 3702325397 |
| `ebs-console/` | EBS UI Design - Console | 3646783501 |
| `ebs-skin-editor/` | EBS UI Design - Skin Editor | 3688988850 |
| — | EBS 방송 화면 애니메이션 레퍼런스 | 3653238942 |

| Confluence | Page ID |
|-----------|---------|
| `10_UI Design` | 3669426180 |

---

### 07-archive/ — 아카이브

Confluence 미발행. 로컬 참조용.

| 하위 폴더 | 내용 | 파일 수 |
|----------|------|:------:|
| `00-prd-archive/` | Feature Catalog, Milestones, DB Schema 등 | 5 |
| `01-pokergfx-analysis/` | PokerGFX 역설계 전체 (PRD-0004 시리즈 포함) | 3,593 |
| `02-design/` | Console UI Design v9.7.0, 목업 | 17 |
| `03-plans/` | 실행 계획서 14개 | 14 |
| `04-reports/` | 완료 보고서 | 8 |
| `05-phase-prds/` | Phase 2/3 PRD | 2 |
| `06-operations/` | 운영 문서, 이메일, 브리핑 | 22 |
| `07-legacy/` | 구버전 아카이브 | 2 |

---

## 번호 체계

| 번호 | 역할 | 비고 |
|:----:|------|------|
| 00 | 참조 | 읽기 전용 |
| 01 | 전략 | Foundation SSOT |
| 02 | 행동 명세 | 개발팀 핵심 |
| 03 | UI 설계 | ebs_ui 레포 |
| 04 | 게임 규칙 | Confluence 발행 |
| 05 | 실행 계획 | .plan.md |
| 06 | 보고서 | 완료 보고 |
| 07 | 아카이브 | 로컬 참조용 |
| — | impl, api, data, testing, back-office, qa | 구현 레포 이관 대상 |

---

## 통합 레포 구조

모든 EBS 관련 코드/문서가 이 레포에 통합됨 (2026-04-10).

| 폴더 | 역할 |
|------|------|
| `contracts/` | API/Data/Spec 계약 (Conductor 소유) |
| `team1-frontend/` | React 19 + Vite (Login/Lobby/Settings) |
| `team2-backend/` | FastAPI BO (REST/WS/DB) |
| `team3-engine/` | Pure Dart Game Engine |
| `team4-cc/` | Flutter CC + Overlay + Graphic Editor |
| `docs/07-archive/legacy-repos/` | 이전 외부 레포 아카이브 |

---

## Confluence UI 수동 처리 필요

| # | 작업 | 현재 | 변경 |
|:-:|------|------|------|
| 1 | 리네임 | `00_PokerGFX 분석` | `00_Reference` |
| 2 | 리네임 | `05_Documents` | `01_Strategy` |
| 3 | 삭제 | `20_BO` (id=3668869134) | — |
| 4 | 삭제 | `30_Production Automation` (id=3668934662) | — |
| 5 | 삭제 | `40_OTT Automation` (id=3669000197) | — |
