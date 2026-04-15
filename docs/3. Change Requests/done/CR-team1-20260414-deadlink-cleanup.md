---
title: CR-team1-20260414-deadlink-cleanup
owner: conductor
tier: internal
last-updated: 2026-04-15
legacy-id: CCR-DRAFT-team1-20260414-deadlink-cleanup
---

# CCR-DRAFT: 외부 파일의 구 contracts/specs/BS-0X-* 경로 dead link 일괄 정리

- **제안팀**: team1
- **제안일**: 2026-04-14
- **영향팀**: [team4]
- **변경 대상 파일**: contracts/api/API-07-graphic-editor.md
- **변경 유형**: modify
- **변경 근거**: team-policy v4 이관(BS-02/03/08 → team1-frontend/specs/)에도 불구하고 contracts/api/API-07-graphic-editor.md 가 구 경로 `contracts/specs/BS-08-graphic-editor/` 를 하드코딩 중. dead link. 원안 draft 는 docs/backlog, integration-tests, team4-cc 도 포함했으나 CCR 시스템은 contracts/ 범위 전용이므로 contracts 타겟 1건으로 축소. 그 외 경로는 각 팀/Conductor 별도 세션에서 직접 편집.
- **리스크 등급**: LOW

## 변경 요약

구 경로 3종 → 신 경로로 bulk rewrite:

| 구 | 신 |
|----|----|
| `contracts/specs/BS-02-lobby/` | `team1-frontend/specs/BS-02-lobby/` (또는 팀 경계에 따라 상대경로) |
| `contracts/specs/BS-03-settings/` | `team1-frontend/specs/BS-03-settings/` |
| `contracts/specs/BS-08-graphic-editor/` | `team1-frontend/specs/BS-08-graphic-editor/` |

## Diff 초안 (샘플)

```diff
 # team4-cc/CLAUDE.md:65
-| Settings | consumes | ../../contracts/specs/BS-03-settings/ |
+| Settings | consumes | ../team1-frontend/specs/BS-03-settings/ |

 # contracts/api/API-07-graphic-editor.md
-행동 명세: contracts/specs/BS-08-graphic-editor/BS-08-00-overview.md
+행동 명세: ../team1-frontend/specs/BS-08-graphic-editor/BS-08-00-overview.md

 # docs/backlog/_aggregate.md (여러 위치)
-- contracts/specs/BS-02-lobby/BS-02-02-event-flight.md
+- team1-frontend/specs/BS-02-lobby/BS-02-02-event-flight.md
```

## 영향 분석

- **Team 1 (자기 참조)**: 이미 팀 내부 22건은 수정 완료 (본 CCR 범위 외).
- **Team 4 (consumer)**: `CLAUDE.md` 와 `specs/BS-07-overlay/BS-07-*.md` 가 Team 1 BS-03/08 을 참조. 경로 rewrite 만 필요, 내용 변경 없음.
- **Contracts (team1 BS 를 역참조)**: `api/API-07`, `data/DATA-07`, `data/DATA-02` 가 team1 soeur 에 대한 pointer 를 보유. "계약이 팀 스펙을 가리키는" 구조는 유지.
- **Integration tests**: `_TODO.md` 의 grep 경로 하드코딩만 수정.
- **마이그레이션**: 없음 (파일 이동은 이미 완료된 상태, 단지 링크 갱신).

## 대안 검토

1. **스크립트 (`tools/link_lint.py`)**: 장기적으로 권장. 본 CCR 는 수동 bulk rewrite 먼저, 스크립트는 별도 backlog.
2. **유지 (방치)**: 깨진 링크가 학습 비용·drift 위험 계속 누적. 기각.
3. **team1 폴더로 파일 복제**: SSOT 분산 + drift 심화. 기각.

## 검증 방법

Conductor 세션에서:

```bash
# 수정 전 카운트 (기대: ~110)
grep -rn "contracts/specs/\(BS-02-lobby\|BS-03-settings\|BS-08-graphic-editor\)" \
  contracts/ docs/ team2-backend/ team3-engine/ team4-cc/ integration-tests/ | wc -l

# 수정 후 카운트 (기대: 0, 단 본 CCR 자신과 archive 제외)
```

## 승인 요청

- [ ] Conductor 승인 + 실제 파일 편집 수행
- [ ] Team 4 검토 (자기 CLAUDE.md / BS-07 수정 확인)
- [ ] Team 2/3 검토 (해당 팀 파일에 구 경로 존재 시)
