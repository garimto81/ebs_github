---
id: SG-renewal-ui-32
title: "Security_Posture.md → 보안 모델 4 컴포넌트 cascade"
type: spec_gap_security
status: OPEN
owner: conductor
created: 2026-05-17
priority: P2
scope: security
mirror: none
confluence-sync: none
affects_files:
  - team2-backend/app/api/v1/auth.py (RBAC 3등급)
  - team2-backend/app/middleware/two_eyes_principle.py (2 인 승인)
  - team4-cc/src/lib/features/auth/services/session_timer.dart (60분 timer)
  - tools/check_cc_no_holecard.py (정적 가드)
related_sg: []
prd_refs:
  - Foundation §A.4 (Hole Card Visibility 4단 방어, v5.0 footnote DRM 직교)
  - Command_Center.md Ch.10 (Hole Card Visibility, v4.4 DRM 직교 cross-ref)
  - docs/2. Development/2.5 Shared/Security_Posture.md (v1.0.0 신규)
pokergfx_refs:
  - archive/.../complete.md line 1909-1995 (4계층 DRM 상세 — 회피 대상)
  - archive/.../complete.md line 2118-2134 (15 보안 취약점 ★)
  - archive/.../complete.md line 1903-1905 (InsecureCertValidator)
parent_plan: ~/.claude/plans/decision-report-v5-ultrathink-rewrite.md
---

# SG-renewal-ui-32 — 보안 모델 4 컴포넌트 cascade

## 공백 서술

신규 doc `Security_Posture.md` v1.0.0 = EBS = Operational Integrity (PokerGFX DRM 직교). 본 SG = 4단 방어 (RBAC + 2-eyes + 60-min + 물리 영역) 의 4 컴포넌트 구현 cascade.

## 권장 조치

### Step 1 — RBAC 3등급 (team2 Backend)

`auth.py` 에 Admin / Operator / Viewer 권한 매트릭스 구현. Lobby.md 부록 E (10×3 매트릭스) 정합.

### Step 2 — 2-eyes principle (team2)

`two_eyes_principle.py` middleware — Admin + Manager 동시 승인 endpoint.

### Step 3 — 60-min Session Timer (team4 CC)

`session_timer.dart` — Hole Card 옵션 ON 상태 60 분 자동 expire + 재승인 prompt.

### Step 4 — 정적 가드 (CI)

`tools/check_cc_no_holecard.py` (이미 존재 — CC PRD Ch.10.3 참조) 강화: bypass 모드 audit log.

## 수락 기준

- [ ] RBAC 3등급 매트릭스 정확
- [ ] 2-eyes 승인 endpoint 정확 동작
- [ ] 60분 timer 정확
- [ ] PokerGFX 15 취약점 회피 (자체 RFID + 자체 통신)
- [ ] PRD Foundation §A.4 + CC Ch.10 정합

## 위상

- Type: B (PRD 명시 + 구현 cascade)
- Scope: security architecture
- Branch: `work/team2+team4/security-posture`
- Estimated diff: ~400-600 줄
- Risk: 높음 — 보안 핵심
- Dependency: 없음
