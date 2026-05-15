---
title: CR-team1-20260410-tech-stack-ssot
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-team1-20260410-tech-stack-ssot
confluence-page-id: 3818914809
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818914809/EBS+CR-team1-20260410-tech-stack-ssot
mirror: none
---

# CCR-DRAFT: Tech Stack SSOT를 BS-00에 명시하고 team2 IMPL 시리즈 동기화

- **제안팀**: team1
- **제안일**: 2026-04-10
- **영향팀**: [team2, team3, team4]
- **변경 대상 파일**: `contracts/specs/BS-00-definitions.md`
- **변경 유형**: modify
- **변경 근거**: Quasar 전환 commit(`347be60 refactor: change frontend tech stack React → Quasar`, 2026-04-10 12:35)이 `contracts/specs/BS-00-definitions.md` §1 앱 아키텍처 용어 표의 Lobby row와 `team2-backend/specs/impl/IMPL-01~03`에 전파되지 않음. 결과적으로 BS-00 SSOT와 team2 내부 스펙이 모두 stale한 Next.js/Zustand 기준으로 남아 Team 1 critic revision 중 발견. **재발 방지**를 위해 BS-00을 Tech Stack SSOT로 명시하고 team2 IMPL 시리즈 동기화 cleanup을 동봉 요청.

---

## 변경 요약

1. **1차 변경 (contracts/ 범위)**: `contracts/specs/BS-00-definitions.md` §1 앱 아키텍처 용어 표의 Lobby row 기술 컬럼을 Quasar로 확정하고, 표 아래 "Tech Stack SSOT — 모든 팀 내부 스펙이 본 표를 참조한다" 문장 추가.
2. **2차 Related Cleanup (권한 밖 — Conductor/Team 2 조치 요청)**: `team2-backend/specs/impl/IMPL-01~03`의 Next.js/Zustand 잔재를 Quasar/Pinia 기준으로 재작성 또는 revert.

---

## 1차 변경 Diff 초안 — `contracts/specs/BS-00-definitions.md`

### A. §1 앱 아키텍처 용어 표 (Lobby row)

```diff
 | 용어 | 정의 | 기술 | 비고 |
 |------|------|------|------|
-| **Lobby** | 모든 테이블의 관제·설정 허브. 웹 브라우저 앱 | 웹 (React/Next.js TBD) | 구 WSOP LIVE Staff Page 대응 |
+| **Lobby** | 모든 테이블의 관제·설정 허브. 웹 브라우저 앱 | Quasar Framework (Vue 3) + TypeScript | 구 WSOP LIVE Staff Page 대응 |
 | **Command Center (CC)** | 게임 진행 커맨드 입력 화면. 테이블당 1개 인스턴스 | Flutter 앱 (별도 실행) | 구 PokerGFX Action Tracker |
```

### B. §1 하단에 Tech Stack SSOT 문장 추가

```diff
 > **금지**: "단일 Flutter 앱의 2개 화면" 표현. Lobby(웹)와 CC(Flutter)는 별도 앱이다.
+
+> **Tech Stack SSOT**: 본 §1 표는 EBS 3-앱 기술 스택의 **단일 출처(Single Source of Truth)** 다. `team*-*/specs/impl/IMPL-*.md`, `team*-*/CLAUDE.md`, `team*-*/ui-design/UI-*.md` 등 팀 내부 스펙은 본 표를 cross-reference 해야 한다. 기술 스택 변경은 반드시 본 표를 먼저 수정한 뒤 CCR 알림을 통해 모든 팀 내부 스펙을 동기화한다.
```

### C. Edit History 행 추가

```diff
 | 날짜 | 항목 | 내용 |
 |------|------|------|
 | 2026-04-08 | 신규 작성 | 모든 BS/BO/IMPL/API/DATA 문서의 용어 기반 확립 |
+| 2026-04-10 | Tech Stack SSOT | Lobby 기술 컬럼 React/Next.js TBD → Quasar (Vue 3) + TS 확정. 본 §1 표가 팀 내부 스펙의 SSOT임을 명시 (CCR-XXX) |
```

---

## 2차 Related Cleanup — `team2-backend/specs/impl/` (권한 밖)

Team 1 세션은 `team2-backend/` 경로에 쓰기 권한이 없어 직접 수정 불가 (Layered Scope Guard hook이 차단). 아래 3개 파일은 Conductor 또는 Team 2 세션이 처리해야 합니다.

### 항목 1 — `team2-backend/specs/impl/IMPL-01-tech-stack.md` (committed, stale)

**현재 상태 (commit 7285673 기준, 2026-04-10 11:29)**:
- L5 Edit History: `| 2026-04-09 | TBD 해소 | Lobby 프레임워크 Next.js 15, 상태 관리 Zustand, UI shadcn/ui 확정 |`
- §2.1 선정 기술 표: `프레임워크 Next.js 15`, `상태 관리 Zustand 5.x`, `UI 라이브러리 shadcn/ui`
- §2.2 선정 근거: React 경험 언급
- §2.3 대안 기각: Vue.js를 "팀 내 React 경험 풍부"로 기각
- §2.4 결정 완료: "React SPA vs Next.js → Next.js 15 확정"

**요청 변경**:
- §2.1 표 전체 재작성: `프레임워크 Quasar Framework (Vue 3) / 상태 관리 Pinia / UI 라이브러리 Quasar 내장 컴포넌트 + Tailwind CSS 또는 Quasar SASS variables`
- §2.2 선정 근거 재작성: Quasar 선정 이유 (CLI, SPA/SSR/PWA/Electron 동시 지원, TS 1급 지원, 컴포넌트 풍부)
- §2.3 대안 기각: Next.js/React를 "CC Flutter와의 기술 다양성 과다, Composition API의 관제 대시보드 적합성" 등으로 역전 기각 처리
- §2.4 결정 완료 블록을 "2026-04-10 Quasar 전환 결정 (commit 347be60)" 으로 업데이트
- Edit History에 `| 2026-04-10 | Quasar 전환 | commit 347be60 반영. Next.js 15/Zustand 5.x/shadcn-ui → Quasar Vue 3/Pinia/Quasar 컴포넌트. 근거·대안 기각 블록 재작성 |` 행 추가

### 항목 2 — `team2-backend/specs/impl/IMPL-02-project-structure.md` (uncommitted, stale)

**현재 상태**: `git status`가 unstaged M으로 보고. `git diff` 기준 단 1줄 변경:

```diff
 │   ├── services/
 │   │   ├── api.ts                # BO REST API 클라이언트
 │   │   └── websocket.ts          # WebSocket 연결 관리
-│   ├── store/                    # 상태 관리 (TBD)
+│   ├── store/                    # Zustand 5.x slices (auth/table/ws/ui)
 │   ├── types/                    # TypeScript 타입 정의
 │   └── utils/                    # 포매팅, 상수
```

**분석**: 이 수정은 commit 7285673 이후 ~ Quasar 전환 commit 347be60 이전(또는 이와 무관한 prior session)에 작성된 선행 작업의 uncommitted 잔여물로 추정. Quasar 전환으로 내용이 stale됨.

**요청 변경 (옵션 2가지)**:
- **옵션 A (권장)**: `git checkout HEAD -- team2-backend/specs/impl/IMPL-02-project-structure.md`로 revert 후, Team 2 세션이 Quasar 프로젝트 구조(`src/stores/` Pinia, `src/composables/`, `src/pages/`, `src/layouts/` Quasar 표준)로 신규 작성.
- **옵션 B**: 수정을 유지하되 `Zustand 5.x slices` → `Pinia stores (useAuthStore/useTableStore/useWsStore/useUiStore)`로 교체. 단, 이 경우 IMPL-01과 정합성 검증 필수.

### 항목 3 — `team2-backend/specs/impl/IMPL-03-state-management.md` (uncommitted, stale)

**현재 상태**: `git status`가 unstaged M으로 보고. `git diff` 기준 주요 변경 (약 20줄 추가):

```diff
 ## 개요
 
-이 문서는 EBS의 **상태 관리 전략**을 정의한다. Command Center(CC)는 Riverpod을 사용하고, Lobby(웹)는 TBD(React Context/Zustand)를 사용한다.
+이 문서는 EBS의 **상태 관리 전략**을 정의한다. Command Center(CC)는 Riverpod을 사용하고, Lobby(웹)는 **Zustand 5.x**를 사용한다 (IMPL-01 §2.4 확정).

 ## 5. Lobby — 웹 상태 관리
 
-> Lobby 상태 관리 라이브러리는 Phase 1 POC 이후 확정 (React Context / Zustand / Jotai 중 TBD).
+Lobby는 **Zustand 5.x**를 사용한다 (IMPL-01 §2.4). ...

+### 5.5 Zustand Slice 구조
+| Slice | 책임 | Store 키 예시 | persist 대상 | 저장 미들웨어 |
+|-------|------|---------------|--------------|--------------|
+| `authSlice` | 인증/토큰/사용자 프로필 | ... | 부분 (`user`만) | `persist` → SessionStorage |
+| `tableSlice` | 테이블 목록/상세/필터 상태 | ... | 아니오 (서버 캐시) | 없음 |
+| `wsSlice` | WebSocket 연결·이벤트 버퍼·구독 상태 | ... | 아니오 | 없음 |
+| `uiSlice` | 사이드바/모달/테마/토스트 | ... | 예 | `persist` → localStorage |
```

**요청 변경 (옵션 2가지)**:
- **옵션 A (권장)**: revert 후 Team 2 세션이 Pinia 기준으로 §5 재작성. 새 구조 예시:
  - `useAuthStore` (Composition API setup-style, persist: `sessionStorage`)
  - `useTableStore` (서버 캐시, persist 없음)
  - `useWsStore` (WebSocket 연결·이벤트 버퍼)
  - `useUiStore` (theme/sidebar/toasts, persist: `localStorage`)
- **옵션 B**: 수정을 유지하되 `authSlice/tableSlice/wsSlice/uiSlice` → `useAuthStore/useTableStore/useWsStore/useUiStore` Pinia store로 교체, `create()` 언급을 `defineStore()`로 교체.

---

## 영향 분석

| 팀 | 영향 | 추정 공수 |
|----|------|-----------|
| **Team 1** | 없음. `team1-frontend/CLAUDE.md`와 `ui-design/UI-00/01/03`은 2026-04-10 critic revision에서 Quasar로 이미 정렬됨. 추가 작업 없음. | 0 |
| **Team 2** | IMPL-01 committed 재작성 + IMPL-02/03 uncommitted revert 또는 재작성. `/auto` 세션 1회분. | 2~3시간 |
| **Team 3** | 기술 영향 없음 (Dart 엔진은 frontend 스택 무관). 알림 수신만. | 0 |
| **Team 4** | 기술 영향 없음 (Flutter+Rive). 알림 수신만. 단, BS-00을 참조하는 `team4-cc/ui-design/` 문서가 있다면 cross-reference 검증 필요. | 0~30분 |

---

## 마이그레이션 리스크

1. **IMPL-01 committed 재작성**: 역사 기록(Next.js 선정 경위)을 잃을 위험. 완화책 — Edit History에 "2026-04-09 Next.js 선정 근거는 git log commit 7285673에서 참조" 한 줄 메모 후 본문 재작성.
2. **IMPL-02/03 uncommitted 변경 revert**: 해당 변경의 원작성자(세션 미상)가 아직 완결하지 못한 작업이라면 작업 손실. 완화책 — Conductor가 revert 전 `git log --all --oneline`과 stash를 재확인하고, 필요 시 `git stash` 후 처리.
3. **cross-reference 누락**: team4의 UI 문서에 "React/Next.js" 잔재가 있을 수 있음. 완화책 — CCR 승격 시 Team 4 backlog에 grep 체크 알림 자동 추가.

---

## 대안 검토

| 대안 | 평가 |
|------|------|
| (1) BS-00 수정 없이 각 팀이 자율 동기화 | **기각** — 이번 사고의 재발 원인. SSOT 없이는 다음 스택 전환도 똑같이 누락될 것. |
| (2) 각 팀 `CLAUDE.md`에 tech stack 명시 (분산 SSOT) | **기각** — SSOT 원칙 위배, 드리프트 보장. |
| (3) `contracts/team-policy.json`에 `tech_stack` 필드 추가 | **조건부 기각** — JSON 정책은 machine-readable용. 사람 가독성 위해 BS-00 문서 우선. 추후 JSON 동기화는 후속 과제. |
| (4) **본 제안 — BS-00을 Tech Stack SSOT로 확정** | **채택** — 이미 BS-00이 모든 팀의 용어 SSOT로 기능 중이므로 일관성 있음. 재발 방지 효과 큼. |

---

## 검증 방법

### 승격 후 contracts/ 변경 검증 (Conductor)
1. `contracts/specs/BS-00-definitions.md` §1 Lobby row에 "Quasar Framework" 등장 확인.
2. Tech Stack SSOT 문장 존재 확인.
3. Edit History에 2026-04-10 행 확인.

### Related Cleanup 검증 (Team 2 세션)
1. Grep across repo (Edit History 외 본문):
   ```bash
   grep -rn "Next\.js\|Zustand\|shadcn" team2-backend/specs/impl/ \
     | grep -v "Edit History" | grep -v "git log"
   # 기대: 0건
   ```
2. `team2-backend/specs/impl/IMPL-01-tech-stack.md` Edit History에 2026-04-10 Quasar 전환 행 존재.
3. `git status` team2-backend/specs/impl/IMPL-02/03 unstaged M 해소.
4. Quasar 프로젝트 구조 (`src/stores/`, `src/composables/`) 참조가 IMPL-02에 등장.
5. `defineStore()` 참조가 IMPL-03에 등장 (Pinia 기준).

### Cross-reference 검증 (모든 팀)
```bash
grep -rn "React\|Next\.js\|Zustand" team*-*/specs/ team*-*/ui-design/ team*-*/CLAUDE.md \
  | grep -v "Edit History" | grep -v "critic revision" | grep -v "QA-LOBBY-0[245]"
# 기대: 0건 (QA DEPRECATED 문서 및 Edit History 역사 기록 제외)
```

---

## 승인 요청

- [ ] Conductor 승인 (BS-00 contracts/ 변경)
- [ ] Team 2 기술 검토 (IMPL-01 재작성 + IMPL-02/03 처리 옵션 선택)
- [ ] Team 4 기술 검토 (team4-cc cross-reference 확인)
- [ ] Team 3 알림 수신 확인 (기술 영향 없음, 형식적)

---

## 참고 사항

- **promote.py 검증 예상**: 본 draft는 `변경 대상 파일: contracts/specs/BS-00-definitions.md`로 1차 변경이 contracts/** 경로이므로 `ccr_promote.py` 필수 필드 검증을 통과해야 한다. Related Cleanup 섹션은 CCR 체크리스트 내부 문서로 취급.
- **제안 번호**: promote 시 `CCR-{NNN}-tech-stack-ssot-...` 형태로 할당 예상.
- **선행 CCR**: 같은 날 promote된 `CCR-016-wsop-live-parity-*` (team1 WSOP parity)의 후속 cleanup 성격이므로 Conductor가 함께 검토하면 효율적.
- **Scope Guard 준수**: 본 draft는 `docs/05-plans/ccr-inbox/CCR-DRAFT-team1-` prefix로 hook whitelist 경로에 작성. Team 2 cleanup 지시는 요청(request)이며 Team 1 세션이 직접 수행하지 않음.
