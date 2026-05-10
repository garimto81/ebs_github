---
id: B-355
title: "legacy-id-redirect.json validator (Dart CLI + CI gate)"
status: DONE
priority: P2
created: 2026-04-29
parent: B-354 supporting infra
related-prs:
  - "PR (본 PR — tools/validate_redirects.dart + .github/workflows/redirect-validation.yml)"
mirror: none
---

# [B-355] Redirect Validator Infrastructure (DONE)

## 배경

PR #19 머지로 `docs/_generated/legacy-id-redirect.json` 이 main 진입.
B-354 (OE-level 매핑 추가) 등 후속 변경 시 schema/cycle/path-format 회귀 방지가 필요.

## 산출물

| 파일 | 역할 |
|------|------|
| `tools/validate_redirects.dart` | 단일 .dart (no pubspec) — `dart:io` + `dart:convert` 만 사용 |
| `.github/workflows/redirect-validation.yml` | PR (main 타깃) + push to main 트리거. `dart analyze` + `dart run` 단계 |

## 검증 항목 (4종)

1. **JSON 유효성**: top-level 객체 + `mappings` 키 존재
2. **Required fields per mapping**: `{title, legacy_path, redirect_to, domain, phase}` 5종
3. **Path format**: `legacy_path` / `redirect_to` 모두 `^docs/.+\.md$` 매치
4. **Duplicate keys**: raw text 정규식 스캔 (JSON parser 가 silently 덮어쓰기 방지)
5. **Circular references**: `legacy_path → redirect_to` 그래프 DFS, self-redirect 도 1-cycle 로 검출

## Exit codes

- `0`: 성공 (`OK: N mappings validated (schema + paths + cycles)`)
- `1`: 실패 (`stderr` 에 상세 사유 N건 출력)

## PEVR Loop 검증 결과

| Phase | 검증 명령 | 결과 |
|-------|-----------|------|
| 1 | `python -c "json.load(...)"` + schema check | OK (17 mappings) |
| 2 | `dart analyze tools/validate_redirects.dart` | No issues found |
| 2 | `dart run tools/validate_redirects.dart` | OK exit 0 |
| 3 | `dart run tools/validate_redirects.dart tools/mock_invalid.json` | FAIL exit 1 (4/4 결함 검출) |
| 3 | mock 정리 후 실데이터 재실행 | OK exit 0 |
| 4 | `python -c "yaml.safe_load(...)"` workflow YAML | OK (3 triggers, 5 steps) |

## 수락 기준

- [x] `tools/validate_redirects.dart` 신규 — `dart analyze` 0 issue
- [x] 실데이터 PASS, mock invalid (duplicate key + bad path + missing field + cycle) FAIL
- [x] CI workflow 신규 — push (main) + PR (main 타깃) 트리거
- [x] mock harness 정리 (cleanup 검증)

## 후속 (B-354 본체 작업 시)

B-354 의 OE-level 매핑 추가 PR 작성자는 본 validator 가 자동으로 schema 회귀 차단 기능 활용 가능. `output_events` sub-section 도입 시 mapping schema 분기 발생 → validator 보강 필요할 수 있음 (별도 변경).

## 관련

- B-354 — OE-level 매핑 추가 (BLOCKED → READY, PR #19 머지로 unblock)
- PR #19 — `legacy-id-redirect.json` 본체 introduce
