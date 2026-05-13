---
title: Global SSOT Sync — SG-022 advocacy eradication
owner: conductor
tier: operations
last-updated: 2026-04-27
status: active
supersedes: SG-022 single-binary advocacy across all docs/team* trees
confluence-page-id: 3819602444
confluence-parent-id: 3811573898
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3819602444/EBS+Global+SSOT+Sync+SG-022+advocacy+eradication
---

# Global SSOT Sync Handoff

> 2026-04-27 저녁 — SG-022 폐기 cascade 의 후속 글로벌 정합성 정렬. 워크스페이스 내 모든 기획 문서를 **Multi-Service Docker 아키텍처 (Lobby-Web 컨테이너 :3000 + CC-Web 컨테이너 :3001 + ebs-net bridge)** SSOT 로 통일.

## Edit History

| 날짜 | 변경 | 결정 |
|------|------|------|
| 2026-04-27 | v1.0 신규 | tools/ssot_auditor.py 신설 + 5건 active advocacy 교정 + 111 historical reference allowlist |

## 핵심 결과

```
SSOT Auditor — strict=False, scan dirs=['docs', 'team1-frontend', 'team2-backend', 'team3-engine', 'team4-cc']
  total matches:         111
  allowlisted (PASS):    111
  violations  (FAIL):    0    ← Gatekeeper 통과
exit=0
```

| 항목 | 값 |
|------|----|
| 스캔 대상 디렉토리 | `docs/`, `team1-frontend/`, `team2-backend/`, `team3-engine/`, `team4-cc/` |
| 스캔 확장자 | `.md`, `.json`, `.yaml`, `.yml` |
| 1차 스캔 violation | **28건** (auditor 최초 버전, allowlist v1) |
| Allowlist 정제 후 violation | **5건** (true active advocacy) |
| 교정 후 violation | **0건** (Gatekeeper PASS) |
| Allowlisted historical | **111건** (deprecation/archive/backlog ledger) |

## 도구 — `tools/ssot_auditor.py`

스캔 키워드 (legacy SG-022 advocacy):
- `단일 데스크탑`, `단일 데스크톱`, `Single Desktop`, `단일 앱`, `단일 바이너리`
- `SG-022`, `Lobby + CC 통합`, `app_router.dart 통합`

Allowlist 매커니즘 (4 layer):
1. **경로 정확 일치** — 본질적 폐기 기록 (SG-022-deprecation.md, MULTI_SESSION_DOCKER_HANDOFF.md, GLOBAL_SSOT_SYNC_HANDOFF.md, Active_Work.md, ssot_auditor.py 자기 자신)
2. **경로 substring** — `/archive/`, `/done/`, `/Plans/`, `Conductor_Backlog/B-Q*`, `Conductor_Backlog/NOTIFY-ALL-*`, `Conductor_Backlog/SESSION_*`, `Phase_1_Decision_Queue.md`, `Spec_Gap_Registry.md`
3. **Line-context markers** — `SUPERSEDED`, `폐기`, `deprecat`, `REMOVED`, `supersedes`, `REACTIVATED`, `REVERTED`, `cascade`, `linked-sg`, `linked-decision`, `gap-id`, `reversal`, `Multi-Service Docker`, etc.
4. **Domain-context markers** — `\.gfskin`, `ZIP 아카이브` (skin-editor 컨테이너 비교 — EBS 앱 아키텍처 무관)

사용:
```bash
python tools/ssot_auditor.py --scan          # human-readable
python tools/ssot_auditor.py --scan --json   # machine-readable
python tools/ssot_auditor.py --scan --strict # allowlist 무시 (history 포함 전수)
python tools/ssot_auditor.py --scan --report tools/_audit.json  # 파일 출력
```

종료 코드: 0 (PASS) / 1 (violations 발견) / 2 (사용 오류).

## 1차 스캔 — 28건 violation 분류

| 분류 | 건수 | 처리 |
|------|:----:|------|
| 진짜 active SG-022 advocacy | **5** | 본 turn 에서 교정 |
| Backlog ledger (linked-sg refs) | 14 | Allowlist 추가 (Conductor_Backlog/B-Q* prefix) |
| Backlog NOTIFY/SESSION/PURGE | 5 | Allowlist 추가 |
| Spec_Gap_Registry SG-022 행 | 2 | Allowlist 추가 (registry 파일 자체) |
| Phase_1_Decision_Queue | 1 | Allowlist 추가 |
| Archive (`/archive/`, `/done/`, `/Plans/`) | 1 | Allowlist 추가 (path-substring) |
| Skin-editor `.gfskin` 컨테이너 비교 | 0 (모두 domain-context) | Allowlist 정제로 자동 제외 |

## 교정한 5건 (active advocacy → Multi-Service Docker)

| 파일 | 줄 | 키워드 | 처리 |
|------|:--:|--------|------|
| `docs/2. Development/2.1 Frontend/Engineering.md` | 97 | `단일 바이너리` | §1.5 설치 관점 표 재작성 — `EBS Desktop App` → `lobby-web` Docker 컨테이너 |
| `docs/2. Development/2.2 Backend/Back_Office/Overview.md` | 111 | `단일 바이너리` | §2.1 BO 의 위치 재작성 + Mermaid 다이어그램 (LobbyApp/CCApp 분리 subgraph) |
| `docs/2. Development/2.4 Command Center/Command_Center_UI/Seat_Management.md` | 214 | `단일 앱` | "EBS 는 CC 단일 앱에서..." → "EBS 는 `cc-web` 컨테이너 (Command Center) 에서..." |
| `docs/2. Development/2.5 Shared/BS_Overview.md` | 38, 42 | `SG-022`, `단일 바이너리` | §1 전체 재작성 — "단일 Desktop 바이너리 (SG-022)" 폐기, Multi-Service Docker SSOT 채택. 1.1 채택 근거, 1.2 컨테이너 토폴로지, 1.3 용어 구분 모두 갱신 |

## Before / After 핵심 발췌

### BS_Overview.md §1

**Before** (`## 1. 단일 Desktop 바이너리 (SG-022, 2026-04-27)`):
> EBS 는 ... **모든 프론트엔드 (Lobby / Settings / Graphic Editor / Command Center / Overlay) 가 동일한 Flutter + Dart + Rive 스택을 공유하며, 단일 Desktop 바이너리 (`.exe` / `.app` / `.deb`) 로 배포된다.**

**After** (`## 1. Multi-Service Docker 아키텍처 (2026-04-27 저녁 SSOT)`):
> EBS 는 **Multi-Service Docker 아키텍처** 를 채택한다. **Lobby (team1) 와 Command Center (team4) 는 단일 앱이 아니며, 각각 독립된 Flutter 프로젝트로 존재한다.** 다만 완전 독립은 아니며, Docker 격리 컨테이너로 기동되어 동일한 EBS 에코시스템 (`ebs-net` bridge 네트워크) 내에서 service-name DNS + 환경 변수로 상호 작용한다.

### Engineering.md §1.5 표

**Before**:
| 구분 | 내용 |
| 설치 단위 | `EBS Desktop App` — 로비 + 커맨드 센터 + 오버레이 뷰 3 기능의 **단일 Flutter 바이너리** |

**After**:
| 구분 | 내용 |
| 설치 단위 | `lobby-web` Docker 컨테이너 — 로비 + Settings + Rive Manager Flutter Web 빌드 산출물 (port 3000). Command Center / Overlay 는 별도 컨테이너 `cc-web` (team4 소유, port 3001) |

### Back_Office Overview.md §2.1 Mermaid

**Before**:
```mermaid
subgraph App["EBS Desktop App (Flutter Desktop)"]
    LO[Lobby 조각]
    CC[CC 조각]
    OV[Overlay 조각]
end
```

**After**:
```mermaid
subgraph LobbyApp["lobby-web 컨테이너 (team1, :3000)"]
    LO[Lobby + Settings + Rive Manager]
end
subgraph CCApp["cc-web 컨테이너 (team4, :3001)"]
    CC[Command Center]
    OV[Overlay]
end
```

## Gatekeeper Verification (Zero-Defect)

```bash
$ cd C:/claude/ebs
$ python tools/ssot_auditor.py --scan
============================================================================
SSOT Auditor — strict=False, scan dirs=[...]
  total matches:         111
  allowlisted (PASS):    111
  violations  (FAIL):    0
============================================================================

$ echo "exit=$?"
exit=0
```

## 후속 작업 (별도 cascade)

- [ ] `team1-frontend/web/README.md` 정합 검토 — Web 배포가 정규 채널인지 명시
- [ ] `Foundation.md` §5.0 "두 런타임 모드" — Multi-Service Docker 의 "두 브라우저 탭" 워크플로우로 의미 갱신 검토
- [ ] `Spec_Gap_Registry.md` SG-022 행에 `(SUPERSEDED 2026-04-27 저녁 by Multi-Service Docker)` 인라인 마크 추가
- [ ] CI 통합 — `tools/ssot_auditor.py --scan` 을 GitHub Actions pre-merge 게이트로 추가 (재발 차단)
- [ ] `--strict` 모드 정기 검토 — history 정리 시점에 archive purge 결정 근거

## 금지

- Auditor allowlist 를 우회하기 위해 deprecation marker 만 추가하고 본문은 advocacy 유지하기
- `--strict` 모드를 default 로 만들기 (history 보존이 깨짐)
- SG-022 keyword 자체를 일괄 sed 로 제거 (역사 추적 불가능해짐)
