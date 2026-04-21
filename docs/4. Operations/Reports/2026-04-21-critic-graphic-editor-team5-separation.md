---
title: "Critic — Graphic Editor team5 분리 적합성 검토"
owner: conductor
tier: internal
last-updated: 2026-04-21
critic-mode: parallel-2-critic
---

# Critic Report — Graphic Editor `team5` 분리 적합성 검토

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-21 | 신규 작성 | 사용자 요청 ("Visual Studio급 트리거+DB 매핑 인프라 에디터") 에 대한 5-Phase 병렬 critic — 옹호 vs 반대 |

---

## 1. 검토 요청

> "graphic editor 를 별도 설계하는 것에 대한 적합성에 대해 critic mode 로 검토 필요. 내가 원하는 형태는 Visual Studio 처럼 확장성이 넓은 형태로 트리거 기반으로 db 와 매핑되어 자유롭게 이미지를 호출할수 있는 인프라 에디터"

**해석**: 현재 `team1` 산하 1 라우트로 압축된 GE (`docs/2. Development/2.1 Frontend/Graphic_Editor/`) 를 **별도 팀 (`team5-graphic_editor/`)** 으로 분리하고, scope 를 단순 `.gfskin` uploader 에서 **reactive runtime IDE** (트리거 기반 + DB 매핑 + 확장 가능) 로 확장하는 것이 적합한가.

---

## 2. 배경 사실 (verified)

| 항목 | 사실 | 근거 |
|------|------|------|
| 현행 GE 위치 | `team1` 산하 Lobby `/graphic-editor` 라우트 | `Graphic_Editor/Overview.md:21` |
| 현행 GE scope | `.gfskin` import + 메타데이터 (이름/색상/폰트/duration) + Activate. Transform/keyframe **out-of-scope** | `Overview.md:34, 117-119` |
| 결정 이력 | CR-011 (2026-04-10 done) — team4 → team1 이관 + scope 축소 | `CR-conductor-20260410-ge-ownership-move.md` |
| API 계약 | API-07 `Graphic_Editor_API.md`. publisher=team2, subscribers=[team1, team4] | `team-policy.json:147` |
| 현행 PASS 문서 | 6개 (Overview/Import/Metadata/Activate/RBAC/UI) reimplementability=PASS, checked 2026-04-20 | 각 frontmatter |
| `team5-graphic_editor/` 상태 | untracked. `.claude/session_state.json` + `.gitignore` 만 존재 (빈 디렉토리) | git status |
| WSOP LIVE 정렬 | PokerGFX 자체가 SE/GE/Console **3-tool 분리**. "하나의 설정은 한 곳에서만 편집" SSOT | `wsoplive/.../EBS UI Design - Skin Editor.md` §3 |
| 프로젝트 의도 | 2026-04-20 재정의 — "기획서 완결 프로토타입". MVP/Phase/런칭 **범위 밖** | `MEMORY.md` |

---

## 3. 5-Phase Critic 절차

| Phase | 처리 |
|-------|------|
| 1. 체크리스트 준비 | 배경 사실 8개 verified |
| 2. 병렬 critic | architect 2명 (advocate-critic / opposition-critic) 동시 spawn, 각자 명시적 입장 |
| 3. 반대근거 explicit | 두 입장 모두 5개 핵심 논거 + 1줄 결론 산출 |
| 4. 자기반박 | §5 회피 항목 평가 |
| 5. 종합 판정 | §6 Conductor 권고 + 옵션 A/B/C |

---

## 4. 양 입장 핵심 요약

### 4.1 옹호 (advocate-critic) — team5 분리 찬성

| # | 핵심 논거 |
|:-:|-----------|
| 1 | 사용자 비전 ("트리거+DB+확장 IDE") 은 현행 GE 정의 (`.gfskin` uploader) 와 **종(種) 자체가 다르다** — 한 라우트 공존 불가 |
| 2 | WSOP LIVE Confluence 가 **SE/GE/Console 3-tool 분리 SSOT 원칙** 명시 → 원칙 1 (WSOP LIVE 정렬) 에 직접 부합 |
| 3 | `team-policy.json:147` 의 `Graphic_Editor_API` 가 이미 별도 contract 로 등록 → publisher (team2) ↔ runtime owner (team5) ↔ subscribers (team1/team4) **3축 거버넌스 정합** |
| 4 | 사용자 비전의 trigger DSL 은 **새 publisher 책임** — team1 은 pure subscriber 로 publisher 자격 없음 (`team-policy.json:59`) |
| 5 | `team5-graphic_editor/` 가 이미 untracked + cwd 자체 → 사용자의 물리적 의도 표명 |

**1줄 결론 (옹호)**:
> WSOP LIVE 정렬 원칙 + publisher 자격 + 라이프사이클 분리 + 기존 untracked 폴더 의도를 동시 정합화하는 유일한 결정.

### 4.2 반대 (opposition-critic) — team5 분리 반대

| # | 핵심 논거 |
|:-:|-----------|
| 1 | CR-011 폐기 사유 5개 중 **0개** team5 분리로 해결 안 됨 (Settings 글로벌, 멀티CC 락, Rive 중복, YAGNI, Flutter 접근성) |
| 2 | `Overview.md:117-119` "8모드 reference-only" 결정의 **명시적 6일 만의 번복** 비용 |
| 3 | 어제 PASS 받은 6개 문서 invalidation + `team-policy.json` v8 신설 + hook 갱신 + GEM/GEI/GEA/GER prefix BS-08→BS-09 cascading **도미노** |
| 4 | Conductor backlog 35+ PENDING 디큐 정체 (B-074 / SG-001~011 / SG-008-b1~b15 등) |
| 5 | "Visual Studio급 인프라" 야망의 실체는 (a) Rive Editor 중복, (b) GEM-* scope 확장, (c) 이미 존재하는 API-04/05 — 모두 팀 분리 없이 처리 가능 |

**1줄 결론 (반대)**:
> 어제 PASS 받은 6개 문서를 무효화하고 11일 전 done CR-011 의 5개 폐기 사유를 모두 재발시키며, 사용자 비전은 team1 GE 산하 BS-08-05~07 추가 3개 문서로 zero 인프라 비용에 동일하게 달성 가능.

---

## 5. 자기반박 (양 critic 의 회피 영역)

### 5.1 옹호 critic 가 회피한 것

| 회피 | 평가 |
|------|------|
| WSOP LIVE 의 SE/GE/Console 3-tool 분리는 **도구 분리** 이지 **팀 분리** 가 아니다. PokerGFX 회사 1곳이 3 도구 모두 만든다. | **CRITICAL** — 옹호의 가장 강한 논거 (WSOP 정렬) 가 over-extrapolation. team5 까지가 아니라 별도 라우트/앱 까지만 정당화. |
| team5 신설 비용을 정량화하지 않고 "정합" 만 강조. 반대 critic 의 도미노 비용에 응답 안 함. | **HIGH** — 비용 무시 |
| 사용자 표현 "Visual Studio급" 을 글자 그대로 reactive runtime IDE 로 확장 해석. 비유일 가능성 미고려. | **MEDIUM** — 의도 추론 점프 |

### 5.2 반대 critic 가 회피한 것

| 회피 | 평가 |
|------|------|
| WSOP LIVE 3-tool SSOT 원칙을 정면 다루지 않음. "Rive Editor 중복" 으로 처리하고 끝. | **CRITICAL** — EBS 원칙 1 (WSOP LIVE 정렬) 를 무시. |
| CR-011 결정의 대상 (8모드 99컨트롤 GUI 편집) 과 사용자 비전 (트리거+DB 인프라) 이 **다른 카테고리** 라는 옹호 논거 1 에 미응답 → "동일 결정의 번복" 으로 단순화. | **HIGH** — 사용자 비전을 새 카테고리로 인정하지 않음. |
| "사용자 의도 재해석" 권고는 사용자 결정 무시 위험. | **MEDIUM** — Type C 점프 경고 자체는 정당하나, "분리 자체 부정" 은 over-reach. |

---

## 6. Conductor 종합 판정

### 6.1 두 critic 의 강도 평가

| 평가 축 | 옹호 | 반대 |
|---------|:----:|:----:|
| 사실 인용 정확도 | 9/10 | 9/10 |
| 논거의 생존성 (자기반박 후) | 6/10 | 7/10 |
| 비용 정량화 | 3/10 | 9/10 |
| 사용자 의도 존중 | 9/10 | 5/10 |
| WSOP LIVE 원칙 1 준수 | 9/10 | 4/10 |
| 프로젝트 의도 (2026-04-20) 준수 | 5/10 | 9/10 |
| **종합** | **41/60** | **43/60** |

**판정**: 두 입장의 강도가 거의 동일. 단일 입장 채택 불가. **부분 채택 (옵션 B)** 이 정합.

### 6.2 양 critic 합의 영역 (불변 결정)

두 입장이 모두 인정하는 사실:

1. **현행 GE Overview (Lobby 1 라우트 + 메타데이터만) 는 사용자 비전을 담을 수 없다** — 옹호 논거 1 + 반대 §4 대안 모두 인정
2. **사용자 비전은 진지하게 검토할 가치가 있다** — 반대도 BS-08-05~07 확장으로 처리 권고
3. **현행 6개 PASS 문서를 invalidate 하지 않고 처리할 길이 있다** — 반대 §4 대안의 핵심
4. **`team5-graphic_editor/` 빈 디렉토리는 처분 결정 필요** — 분리 채택 시 활성, 미채택 시 archive/삭제

### 6.3 결정 옵션 3종

| Option | 정의 | 비용 | 리스크 |
|--------|------|------|--------|
| **A. team1 scope 확장** (반대 critic 안) | GE 를 team1 산하 유지. BS-08-05 (Trigger), BS-08-06 (DB Mapping), BS-08-07 (Extension Points) 3개 문서 추가. `team5-graphic_editor/` 디렉토리 삭제. | **LOW** (3 문서 작성, policy/hook 변경 0건) | 사용자 비전의 "독립 IDE 라이프사이클" 측면 미해결. team1 의 publisher 자격 부재로 trigger DSL 권위 약함. |
| **B. 도구 분리 + team1 owner 유지** (Conductor 권고) | GE 를 **별도 Flutter Desktop 앱** 으로 분리 (Lobby SPA 와 별도 빌드, `ebs_ge_studio.exe`). 단, **owner 는 team1 유지**. WSOP LIVE 3-tool 분리 패턴을 도구 차원에서 적용. BS-08-05/06/07 추가. `team5-graphic_editor/` 디렉토리 삭제 또는 `team1-frontend/ge_studio/` 로 이동. | **MEDIUM** (3 문서 + 빌드 분리 spec + Lobby 라우트 제거) | trigger DSL publisher 자격 여전히 team1 (subscriber) 비대칭. 향후 트리거 spec 변경 시 cross-team 합의 비용. |
| **C. team5 신설** (옹호 critic 안) | `team-policy.json` v8 — `teams.team5` 신설. `docs/2. Development/2.6 Graphic Editor/` 폴더 신설. 기존 6개 PASS 문서 owner team1→team5 이관. `Editor_Trigger_DSL`, `Asset_Mapping_Schema` 신규 contract publisher 등록. 4개 cross-team 계약 갱신. | **HIGH** (6 문서 invalidation + policy v8 + hook + 4 계약 갱신 + audit/drift baseline 재설정 + Conductor backlog 35+ 정체) | CR-011 폐기 사유 5개 중 3개 CRITICAL/HIGH 재발. 프로젝트 의도 (2026-04-20 "기획서 완결") 와 충돌. |

### 6.4 권고: **Option B (조건부)**

**근거**:
1. WSOP LIVE 3-tool SSOT 원칙은 **도구 분리** 까지 정당화 → Option B 가 정확히 그 수준
2. 사용자의 "별도 설계" 요구를 충족 (Lobby 1 라우트 → 독립 앱)
3. CR-011 폐기 사유 중 (a) 멀티 CC 편집권 락, (b) 디자이너 접근성, (c) Rive 중복 — 도구 분리만으로는 재발하지 않음 (팀 분리가 아니므로)
4. team1 owner 유지로 publisher 자격 비대칭은 발생하나, BS-08-05 trigger DSL 만 team2 publisher 로 등록 (이미 API-07 가 team2 publisher 인 것과 동일 패턴) → 해소 가능
5. team5 신설의 도미노 비용 회피
6. 프로젝트 의도 ("기획서 완결 프로토타입") 와 정합 — 도구 분리는 기획 차원이지 조직 신설이 아님

**조건**:
- BS-08-05/06/07 PRD 선행 작성 (Type B 기획 공백 해소 — 사용자 비전 명세화 후 분리 결정)
- `team5-graphic_editor/` 빈 디렉토리는 **결정 확정 시까지 유지**, 결정 후 archive 또는 `team1-frontend/ge_studio/` 로 이동
- CR-011 의 부분 번복 (Lobby 허브 → 별도 앱) 은 신규 CR 로 명시적 기록 필요

### 6.5 사용자 confirm 필요 (auto mode 한계)

세 옵션 모두 거버넌스/구조 변경을 수반하므로 **사용자 명시 결정 필수**. Conductor 는 권고만 하고 자동 채택하지 않음. 다음 질문 응답 필요:

1. 사용자 비전의 핵심이 (a) **별도 팀 분리** 인가, (b) **별도 도구/앱 분리** 인가, (c) **기존 GE scope 확장** 인가?
2. "트리거 기반 + DB 매핑" 의 구체 범위는 — Rive state machine 시각 편집까지 포함하는가, 아니면 EBS 자체 trigger DSL 인가?
3. 시급도 — 이번 세션에 BS-08-05~07 PRD 초안 작성을 시작할 것인가, 다음 세션으로 보낼 것인가?

---

## 7. 부속

### 7.1 두 critic 의 원본 보고서

세션 트랜스크립트 보존. `~/.claude/teams/ge-team5-critic/` 참조.

### 7.2 영향 받을 자산 (Option C 채택 시)

- `team-policy.json` v7 → v8
- `docs/2. Development/2.1 Frontend/Graphic_Editor/` (6개 .md) → `docs/2. Development/2.6 Graphic Editor/` 이동
- `docs/2. Development/2.1 Frontend/Backlog.md` GE 항목 → team5 backlog 이관
- `docs/_generated/` 인덱스 재생성
- `.claude/hooks/session_branch_init.py`, `branch_guard.py` team5 인지
- `tools/spec_drift_check.py`, `reimplementability_audit.py`, `team_merge.py` team5 인지
- `team1-frontend/CLAUDE.md`, `team4-cc/CLAUDE.md` GE 참조 갱신

### 7.3 영향 받을 자산 (Option B 채택 시)

- `Graphic_Editor/Overview.md` §1 라우트 정의 갱신 (Lobby 라우트 → 독립 앱)
- `Graphic_Editor/Engineering.md` 빌드 분리 spec 추가
- `team1-frontend/lib/features/graphic_editor/` → `team1-frontend/ge_studio/` 분리 (장기)
- 신규: `Graphic_Editor/Trigger_Mapping.md` (BS-08-05)
- 신규: `Graphic_Editor/DB_Mapping.md` (BS-08-06)
- 신규: `Graphic_Editor/Extension_Points.md` (BS-08-07)
- 신규 CR: `CR-conductor-20260421-ge-tool-separation.md`

### 7.4 영향 받을 자산 (Option A 채택 시)

- 신규: `Graphic_Editor/Trigger_Mapping.md`, `DB_Mapping.md`, `Extension_Points.md` (3개)
- `team5-graphic_editor/` 디렉토리 삭제 + `.gitignore` 의 team5 entry 정리

---

## 8. 후속 액션 (사용자 결정 후)

| 결정 | 액션 |
|------|------|
| Option A | `Conductor_Backlog/B-XXX-ge-scope-expansion.md` PENDING 등록 + `team5-graphic_editor/` 처분 |
| Option B | 신규 CR `CR-conductor-20260421-ge-tool-separation.md` 작성 + BS-08-05~07 PRD 선행 + `team5-graphic_editor/` 보류 |
| Option C | `team-policy.json` v8 PR + 도미노 task list 작성 + Conductor backlog 우선순위 재조정 |
