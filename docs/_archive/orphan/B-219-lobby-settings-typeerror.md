---
id: B-219
title: "B-219 — Lobby Settings 화면 TypeError (response schema 불일치)"
owner: team1 + team2
tier: internal
status: PENDING
type: backlog
severity: MEDIUM
blocker: false
source: docs/4. Operations/Plans/E2E_Verification_Report_2026-05-10.md
last-updated: 2026-05-10
---

## 개요

E2E v1.2 검증 중 Lobby `/settings/outputs` 화면 진입 시 빨간 에러 박스 발견.

## 증상

스크린샷 16 하단:
```
TypeError: Instance of 'minified:t<dynamic>': type 'minified:t<dynamic>' is not a subtype of type 'Map<String, dynamic>'
```

화면 자체는 렌더 (Resolution, Frame Rate, Output Protocol 등). 그러나 일부 영역에서 backend response를 `Map<String, dynamic>`로 cast 시도 → 다른 타입(List or single value) 반환되어 TypeError.

## 원인 추정

team2 backend의 `/api/v1/settings/*` endpoint가 dict 대신 list 또는 다른 shape으로 응답. team1 frontend의 Freezed model이 `Map<String, dynamic>` expected.

## 작업 범위

1. **재현**: `curl -H "Authorization: Bearer $TOK" http://localhost:8000/api/v1/settings/outputs` 응답 shape 확인
2. **소유 결정**:
   - shape 잘못된 쪽이 backend면 → team2 정정 (BO settings endpoint)
   - schema 정의가 frontend 가정과 다르면 → team1 model 정정 (또는 shared/ebs_common 갱신)
3. **회귀 테스트**: Settings 5탭 모두 진입 시 TypeError 0건 확인

## 완료 기준

- [ ] Settings/Outputs 화면 진입 시 빨간 에러 박스 미표시
- [ ] Settings 5탭 (Outputs/GFX/Display/Rules/Stats) 모두 정상 렌더
- [ ] 가능하면 BO API spec(`docs/2. Development/2.2 Backend/APIs/Backend_HTTP.md`) frontmatter와 정합

## 참조

- E2E 보고서 §1, screenshot 16 (`Screenshots/2026-05-10-e2e/iteration-3/16-lobby-settings.png`)
- IMPL-004 (team1 Settings 19 D3 mapping)
- SG-003 Settings 5-level scope
