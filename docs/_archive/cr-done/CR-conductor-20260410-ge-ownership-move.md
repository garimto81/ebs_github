---
title: CR-conductor-20260410-ge-ownership-move
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-conductor-20260410-ge-ownership-move
confluence-page-id: 3818587264
confluence-parent-id: 3818521542
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818587264/EBS+CR-conductor-20260410-ge-ownership-move
mirror: none
---

# CCR-DRAFT: Graphic Editor 소유권 Team 4 → Team 1 이관 (Lobby 허브)

- **제안팀**: conductor
- **제안일**: 2026-04-10
- **영향팀**: [team1, team2, team4]
- **변경 대상 파일**:
  - contracts/specs/BS-08-graphic-editor/BS-08-00-overview.md (add)
  - contracts/specs/BS-08-graphic-editor/BS-08-01-import-flow.md (add)
  - contracts/specs/BS-08-graphic-editor/BS-08-02-metadata-editing.md (add)
  - contracts/specs/BS-08-graphic-editor/BS-08-03-activate-broadcast.md (add)
  - contracts/specs/BS-08-graphic-editor/BS-08-04-rbac-guards.md (add)
  - contracts/specs/BS-00-definitions.md (modify — 앱 아키텍처 표 + GEM-* 요구사항)
- **변경 유형**: add + modify
- **변경 근거**: 사용자(Conductor)가 2026-04-10 AskUserQuestion 세션에서 "GE 허브 위치 = Lobby (Team 1 Quasar+rive-js)" 및 "편집 범위 = Import+Activate 허브"를 명시 결정. 기존 `CCR-DRAFT-team4-20260410-bs08-graphic-editor-new.md`는 CC 내부 Flutter 화면 + 8모드 99컨트롤 풀 편집을 가정하여 다음과 충돌: ①"Settings는 글로벌" 원칙 (memory: feedback_settings_global.md), ②멀티 CC 동기화 시 편집권 락 프로토콜 필요성, ③Rive 공식 에디터와의 중복 투자, ④YAGNI. 본 CCR은 Team 4 제안의 유용한 자산(8모드 정의, Rive Import 흐름, SkinChanged 이벤트)을 Team 1 Quasar 허브 아키텍처로 재매핑한다.

## 변경 요약

1. **GE 허브 이관**: Team 4 CC 내부 Flutter 화면 → Team 1 Lobby Settings 내 `/lobby/graphic-editor` 탭
2. **Team 4 역할 축소**: GE 소유 제거, Overlay Skin Consumer로 재정의 (`skin_updated` WS 이벤트 수신 + BS-07-03 §5 기존 FSM 재사용)
3. **BS-08 재구조화**: Team 4 제안 6파일(overview/modes/skin-editor/color-adjust/rive-import/preview-apply) → Team 1 허브 기준 **5파일**(overview/import-flow/metadata-editing/activate-broadcast/rbac-guards)
4. **편집 범위 축소**: `skin.json` 메타데이터(이름/색상/폰트/해상도/애니메이션 duration)만 편집 가능. Transform/Animation type/keyframe/Color Adjust 전부 out-of-scope. 디자이너는 Rive 공식 에디터로 `.riv` 완성 후 업로드.
5. **Rive Import 흡수**: Team 4 CCR §BS-08-04 Rive Import 흐름을 Team 1 Lobby BS-08-01 import-flow로 이관 (QA-GE-02 CRITICAL 해소 경로 유지)
6. **Team 4 기존 CCR 폐기**: `CCR-DRAFT-team4-20260410-bs08-graphic-editor-new.md`를 `ccr-inbox/archived/`로 이동

## Diff 초안

### A. `contracts/specs/BS-00-definitions.md` §1 앱 아키텍처 표

```diff
 | 용어 | 정의 | 기술 | 비고 |
 |------|------|------|------|
 | **Lobby** | 모든 테이블의 관제·설정 허브. 웹 브라우저 앱 | Quasar Framework (Vue 3) + TypeScript | 구 WSOP LIVE Staff Page 대응. GE 허브 포함. |
 | **Command Center (CC)** | 게임 진행 커맨드 입력 화면. 테이블당 1개 인스턴스 | Flutter 앱 (별도 실행) | 구 PokerGFX Action Tracker |
 | **Overlay** | 방송 그래픽 출력 | Flutter + Rive Canvas | CC와 동일 앱의 다른 화면 |
-| **Graphic Editor** | Skin/Overlay 시각 편집 (CC/Overlay와 동일 Flutter 앱) | Flutter + Rive | Admin 전용 |
+| **Graphic Editor (GE)** | 아트 디자이너 `.gfskin` import + 메타데이터 편집 + activate 허브. Lobby 탭. | Quasar (Vue 3) + rive-js (@rive-app/canvas) | Admin 전용. CC/Overlay와 별개 런타임. 동일 `.riv` 바이너리 공유. |
```

### B. `contracts/specs/BS-00-definitions.md` §요구사항 ID 체계

```diff
-## GE-* (Graphic Editor) — 30개
-- GE-01 ~ GE-15: Board 편집
-- GE-16 ~ GE-30: Player 편집
+## GE 관련 Prefix 체계
+
+| Prefix | 범위 | 개수 | 상태 | 소유 |
+|--------|------|------|------|------|
+| **GEM-** | Metadata 편집 (이름/버전/색상/폰트/해상도/duration) | ~20 | active | team1 |
+| **GEB-** | Board 모드 (참고 자산, Team 4 제안에서 유입) | 15 | reference-only | - |
+| **GEP-** | Player 모드 (참고 자산) | 15 | reference-only | - |
+| **GEI-** | Import (.gfskin ZIP 업로드/검증) | ~8 | active | team1 |
+| **GEA-** | Activate (배포 + 멀티 CC 동기화) | ~6 | active | team1 + team2 |
+| **GER-** | RBAC (Admin/Operator/Viewer gate) | ~5 | active | team1 + team2 |
+
+> GEB-/GEP- 15×2=30 요구사항은 참고 자산(PokerGFX 역설계)으로만 유지. 실제 편집 UI 대상 아님. 디자이너가 Rive 공식 에디터에서 처리.
```

### C. `contracts/specs/BS-08-graphic-editor/` 5파일 신설

(전체 본문은 Conductor가 Week 1에 개별 작성. 각 파일 골격:)

- **BS-08-00-overview.md**: 역할(authoring 허브), 페르소나(Art Designer/Admin/Operator), use case 플로우, 8모드 참고 자산
- **BS-08-01-import-flow.md**: `.gfskin` 업로드 FSM (idle→validating→uploading→saved/failed), 클라이언트+서버 JSON Schema 검증, Rive .riv 파싱 (QA-GE-02 해소)
- **BS-08-02-metadata-editing.md**: 편집 가능 필드 매트릭스 (GEM-* 요구사항 매핑), PATCH API, If-Match ETag 낙관적 동시성
- **BS-08-03-activate-broadcast.md**: 멀티 CC 동기화 FSM (Activate→DB→WS→N CC), GameState==RUNNING 경고 다이얼로그, 실패 시 폴백
- **BS-08-04-rbac-guards.md**: Admin/Operator/Viewer 행동 매트릭스, UI gate + API gate 이중 강제

### D. `team4-cc/CLAUDE.md` 수정 요청 (Team 4 세션이 CCR 승격 후 수행)

```diff
-# Team 4: CC + Overlay + Graphic Editor — CLAUDE.md
+# Team 4: CC + Overlay (Skin Consumer) — CLAUDE.md

 ## Role

-Command Center (실시간 운영) + Overlay (방송 그래픽 출력) + Graphic Editor (Skin/Overlay 편집)
+Command Center (실시간 운영) + Overlay (방송 그래픽 출력) + Skin Consumer (Lobby GE의 skin_updated 이벤트 수신)

-## 3개 화면 — 동일 Flutter 앱
+## 2개 화면 — 동일 Flutter 앱

 | 화면 | 페르소나 | 역할 | 렌더링 |
 |------|---------|------|--------|
 | **Command Center** | Operator | 실시간 게임 진행 — 액션 버튼, 좌석 관리, RFID 카드 입력 | Flutter UI |
 | **Overlay** | 무인 | 방송 그래픽 출력 — holecards, pot, equity, animations | **Rive Canvas** |
-| **Graphic Editor** | Admin | Skin/Overlay 시각 편집 — Rive 애니메이션 설정, 레이아웃, 색상 | Flutter + Rive 미리보기 |

-> CC는 Flutter 네이티브 UI, Overlay는 Rive Canvas 위젯으로 렌더링.
-> Graphic Editor에서 편집한 .riv 파일을 Overlay가 로드하여 실시간 렌더링.
+> CC는 Flutter 네이티브 UI, Overlay는 Rive Canvas 위젯으로 렌더링.
+> Graphic Editor는 Team 1 Lobby(Quasar+rive-js) 소유. Team 4는 skin_updated WS 이벤트 수신 → Overlay가 BS-07-03 §5 기존 로드 FSM으로 리렌더.
```

### E. `team1-frontend/CLAUDE.md` 수정 요청 (Team 1 세션이 CCR 승격 후 수행)

```diff
 ## 소유 경로
 | 경로 | 내용 |
 |------|------|
 | `src/` | Quasar Vue3 소스 |
 | `ui-design/` | UI-00/01/03 (Lobby 주요 화면) |
+| `ui-design/UI-08-graphic-editor.md` | Graphic Editor 탭 UI 설계 |
+| `qa/graphic-editor/` | GE QA 체크리스트 |

 ## 계약 참조 (읽기 전용)
 | 계약 | 이 팀의 역할 |
+| BS-08 Graphic Editor | Admin UI 구현 (Quasar+rive-js) |
+| DATA-07 .gfskin schema | 클라이언트 검증 (ajv) |
+| API-07 Graphic Editor | 8 엔드포인트 호출 |
```

## 영향 분석

| 팀 | 영향 | 추정 공수 |
|----|------|-----------|
| **Team 1** | GE UI 신규 소유. ui-design/UI-08-graphic-editor.md 작성, Quasar 프로젝트에 `/lobby/graphic-editor` 라우트 추가, `@rive-app/canvas` + `jszip` + `ajv` 의존성 추가, 3-Zone 레이아웃 구현, 메타데이터 편집 UI, Activate 버튼 + GameState 경고 다이얼로그, RBAC UI gate | 3주 (Week 2~4) |
| **Team 2** | API-07 신설 구현 (8 엔드포인트), `active_skin_id` DB 컬럼, JSON Schema 서버 검증(ajv-python or fastjsonschema), `skin_updated` WS 이벤트 발행(seq 단조증가, CCR-015 준수), ETag 낙관적 동시성, X-Game-State 헤더 검증 | 2.5주 (Week 2~4) |
| **Team 4** | GE 소유 제거 (CLAUDE.md 수정). Overlay 수신 핸들러 (skin_updated → BS-07-03 §5 재사용). `team4-cc/ui-design/UI-06-skin-editor.md` → archive 이동. 기존 CCR `CCR-DRAFT-team4-20260410-bs08-graphic-editor-new.md` → archived 이동. 자체 리소스 해제 | 0.5주 (Week 1) |
| **마이그레이션** | 현재 구현 코드 없음 → 코드 마이그레이션 없음. 문서 정리만. | - |

## 대안 검토

### 옵션 A: Team 4 기존 CCR 수용 (CC 내부 Flutter GE)
- **장점**: Team 4 단일 앱 구조 유지, Rive 런타임 공유, Team 4 팀원 리뷰 완료
- **단점**: ①멀티 CC 환경에서 편집권 락 프로토콜 필요 (구현 복잡도 +50%) ②"Settings는 글로벌" 원칙 위배 ③Rive 공식 에디터와 기능 중복 (99컨트롤 투자) ④편집 scope 과대로 4주 일정 불가 ⑤디자이너 접근성 (Flutter 설치 필요) 낮음
- **채택**: ❌ (사용자 결정)

### 옵션 B: 본 CCR (Lobby 허브 이관 + scope 축소)
- **장점**: ①사용자 결정 부합 ②멀티 CC 동기화 문제 원천 제거(편집 지점 단일) ③YAGNI 극대 ④디자이너는 브라우저 접근 ⑤Rive 공식 도구 위임으로 scope 명확 ⑥Team 4 작업 부담 극소화
- **단점**: Team 4 기존 CCR 폐기, Team 1 rive-js 학습 곡선 (공식 문서 있음, 경미)
- **채택**: ✅

### 옵션 C: 하이브리드 (Lobby 관리 + CC 프리뷰)
- **장점**: 기존 Flutter Rive 프리뷰 재사용
- **단점**: 2개 코드베이스 유지, 사용자가 AskUserQuestion에서 Option 1 선택으로 명시 기각
- **채택**: ❌

## 검증 방법

1. **문서 정렬**:
   - [ ] `team4-cc/CLAUDE.md`의 "Graphic Editor" 행이 제거되고 "Skin Consumer" 명시
   - [ ] `team1-frontend/CLAUDE.md`에 GE UI 소유 추가
   - [ ] `contracts/specs/BS-08-graphic-editor/` 5파일 모두 생성
   - [ ] `contracts/specs/BS-00-definitions.md` §1 표의 GE 행이 Quasar+rive-js로 수정
   - [ ] `team4-cc/ui-design/UI-06-skin-editor.md` → `team4-cc/ui-design/archive/UI-06-skin-editor-nextjs-abandoned.md`
   - [ ] `docs/05-plans/ccr-inbox/CCR-DRAFT-team4-20260410-bs08-graphic-editor-new.md` → `archived/`

2. **CCR 연쇄**:
   - [ ] 본 CCR #1 승격 후 CCR #2(format-unify), #3(api-spec), #4(req-id-rework), #5(skin-updated-ws) 순차 승격

3. **backlog**:
   - [ ] `docs/backlog/conductor.md`에 GE 4주 계획 PENDING 추가
   - [ ] `docs/backlog/team1.md`, `team2.md`, `team4.md`에 CCR 알림 자동 append

## 승인 요청

- [ ] Conductor 승인 (본 CCR 작성자)
- [ ] Team 1 기술 검토 (Quasar+rive-js 수용 가능성, 3주 공수)
- [ ] Team 2 기술 검토 (API-07 8 엔드포인트 부담, `active_skin_id` DB 설계)
- [ ] Team 4 기술 검토 (GE 소유 제거 수용, 기존 CCR 폐기 동의)

## 참고 사항

- **Hook 허용 prefix 확인**: `team-policy.json`에 conductor는 `docs/05-plans/` 전체 소유로 정의되어 있어 `CCR-DRAFT-conductor-*` prefix 파일 쓰기 허용. `tools/ccr_promote.py`가 conductor prefix draft를 어떻게 처리할지는 별도 검증 필요 (필드 검증은 제안팀=conductor 허용 여부).
- **연관 CCR**: CCR-016(WSOP parity), `CCR-DRAFT-team1-20260410-tech-stack-ssot.md`(Quasar SSOT) 후속성.
- **선행 조건**: 없음. 본 CCR이 #2~#5의 전제.
- **Plan 파일**: `C:/Users/AidenKim/.claude/plans/floating-percolating-petal.md` (2026-04-10 작성)
