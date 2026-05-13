---
id: NOTIFY-conductor-B088-PR9
title: "B-088 PR-9 — naming CI gate 도구 신설 (재발 방지)"
status: TOOL_READY  # 2026-04-21 tools/naming_check.py 작성 완료, CI 게이트 활성화는 PR 1-8 완료 후
created: 2026-04-21
from: team1 (B-088 PR-5 선행 알림)
target: conductor
priority: P3 (전 팀 마이그레이션 후)
---

# NOTIFY → Conductor: B-088 PR-9 CI gate

## 목적

WSOP LIVE 네이밍 규약 (camelCase JSON / PascalCase WS type / PascalCase REST path) 재발 방지용 린터.

## 제안 구현

### 1. `tools/naming_check.py`

스캔 대상:
- **WS event type**: team2 `.py` 파일의 `"type": "..."` literal → PascalCase 아니면 warning
- **JSON field**: team1/team4 Freezed `@JsonKey(name: '...')` → camelCase 아니면 warning
- **REST path**: team2 router decorator (`@router.get("/...")`) → PascalCase 아니면 warning
- **Path variable**: `{snake_case}` → warning

### 2. CI integration

각 팀 워크플로우에 추가:
```yaml
# .github/workflows/team2-ci.yml 등
- name: Naming convention check
  run: python tools/naming_check.py --team team2
```

violations > 0 시 CI fail.

### 3. Exception 화이트리스트

`tools/naming_check.exceptions.yaml`:
```yaml
allow_snake_case_keys:
  - "access"      # JWT type (RFC 7519)
  - "refresh"
  - "password_reset"
allow_snake_case_paths:
  - "/health"     # k8s 관행
  - "/metrics"    # Prometheus 관행
```

## 수락 기준

- [x] `tools/naming_check.py` 작성 (WS/JSON/REST/Path variable 4 종 검사) — 2026-04-21
- [x] Exception yaml 구조 (`tools/naming_check.exceptions.yaml`) — 2026-04-21
- [ ] 각 팀 `.github/workflows/*-ci.yml` 에 gate 추가 — **차단: PR 1-8 완료 후**
- [ ] 기존 코드 전수 통과 확인 (PR-1~8 완료 후)
- [x] 위반 시 친절한 fix suggestion 메시지 — suggestion 필드로 snake/kebab → 목표 형식 자동 제안

## 선행 의존

- PR-1~8 완료 (전 팀 마이그레이션) 필수 — 완료 전 도입 시 기존 코드 대량 fail
- **현재 baseline (2026-04-21)**: `python tools/naming_check.py --all` → **98 violation** (ws 10 / json 0 / rest 25 / pathvar 63). PR-5 완료로 json=0 확인. ws=10 은 §4.1 리스트 정확 일치.

## 사용법

```bash
# 전 범위 warning 모드 (exit 0 유지)
python tools/naming_check.py

# 개별 규칙 검사
python tools/naming_check.py --ws
python tools/naming_check.py --json-field
python tools/naming_check.py --rest

# 팀 필터
python tools/naming_check.py --team team2

# JSON 출력 (CI 파싱용)
python tools/naming_check.py --all --format=json

# CI gate 활성화 (PR 1-8 완료 후)
python tools/naming_check.py --strict   # violation > 0 이면 exit 1
```

## CI 게이트 활성화 절차 (후속)

1. B-088 PR 1-8 모두 DONE 확인
2. `tools/naming_check.py --strict --all` → exit 0 검증
3. `.github/workflows/*.yml` 에 gate step 추가 (예: `validate-links.yml` 옆)
   ```yaml
   - name: Naming convention check (B-088 PR-9 gate)
     run: python tools/naming_check.py --strict --all
   ```
4. 본 NOTIFY status = DONE 으로 변경

## 관련

- Master: `docs/4. Operations/Conductor_Backlog/B-088-naming-convention-camelcase-migration.md`
- SSOT: `docs/2. Development/2.5 Shared/Naming_Conventions.md` v2
- 유사 도구: `tools/spec_drift_check.py` (drift audit), `tools/reimplementability_audit.py` (재구현성)
