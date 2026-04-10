# EBS 문서 가이드 — 온보딩 읽기 순서

## 문서 구조

```
docs/
├── 00-reference/      WSOP 프로덕션 분석
├── 01-strategy/       전략/PRD (Foundation PRD, Feature Catalog)
├── 02-behavioral/     행동 명세 BS-00~07 (운영자 하루 순서)
├── 03-ui-design/      UI 와이어프레임 (Lobby, CC, Settings, Overlay)
├── 04-rules-games/    게임 PRD + engine-spec
├── 05-plans/          실행 계획/로드맵
├── 06-reports/        완료 보고서
├── 07-archive/        레거시 (참조하지 않음)
│
│── impl/              기술 구현 설계 (IMPL-00~10)
│── api/               API 계약 (API-01~06)
│── data/              DB 스키마/엔티티 (DATA-01~06)
│── testing/           테스트 전략 (TEST-01~05)
│── back-office/       백오피스 관리 (BO-01~11)
│── qa/                QA 마스터 플랜
│
├── mockups/           HTML 와이어프레임
└── images/            이미지 에셋
```

## 온보딩 읽기 순서

### 1단계: 전체 이해 (1시간)
1. **`01-strategy/PRD-EBS_Foundation.md`** — Part I(포커 기초), Part II Ch.1~3(EBS 정의)
2. **`02-behavioral/README.md`** — 행동 명세 체계 이해

### 2단계: 담당 영역 (30분)
- **Lobby 개발자**: `02-behavioral/BS-02-lobby/` → `03-ui-design/UI-01-lobby.md`
- **CC 개발자**: `02-behavioral/BS-05-command-center/` → `03-ui-design/UI-02-command-center.md`
- **Overlay 개발자**: `02-behavioral/BS-07-overlay/` → `03-ui-design/UI-04-overlay-output.md`
- **게임 엔진**: `04-rules-games/games/engine-spec/BS-06-00-REF-game-engine-spec.md`
- **BO 개발자**: `back-office/BO-01-overview.md` → `api/API-01-backend-endpoints.md`

### 3단계: 기술 설계 (필요 시)
- `impl/IMPL-00-dev-setup.md` — 개발 환경 셋업
- `impl/IMPL-01-tech-stack.md` — 기술 스택 근거
- `api/` — API 계약 상세
- `data/` — DB 스키마

## 핵심 참조 문서

| 문서 | 용도 |
|------|------|
| `02-behavioral/BS-00-definitions.md` | **SSOT** — 모든 용어/상태/트리거 정의 |
| `01-strategy/EBS-Feature-Catalog.md` | 144개 기능 ID 카탈로그 |
| `04-rules-games/games/engine-spec/BS-06-00-REF-game-engine-spec.md` | 게임 엔진 Enum/Data Model |

## 문서 표준

모든 문서는 WSOP LIVE Confluence 표준을 따른다. 상세: `CLAUDE.md > 문서 작성 표준`
