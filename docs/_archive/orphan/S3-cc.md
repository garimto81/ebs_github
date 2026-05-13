---
owner: conductor
tier: internal
stream: S3
name: Command Center
worktree: C:/claude/ebs-cc-stream
phase: P2 (정합성 감사)
blocked_by: S1
audit_basis: docs/4. Operations/orchestration/2026-05-08-consistency-audit/foundation_ssot.md
last-updated: 2026-05-08
confluence-page-id: 3818848858
confluence-parent-id: 3811573898
confluence-url: https://ggnetwork.atlassian.net/wiki/spaces/WSOPLive/pages/3818848858/EBS+S3+Command+Center+spec
---

# S3 Command Center — 정합성 감사 작업 spec

## 🎯 미션

**CC_PRD v4.0 ↔ 정본 Command_Center_UI/Overview.md ↔ Foundation 3-way 정합 + 2.4 CC 전 영역 cascade**.

## 📂 영향 파일 (74)

| 영역 | 패턴 | 파일 수 |
|------|------|--------|
| 외부 PRD | `docs/1. Product/Command_Center.md` | 1 |
| 정본 | `docs/2. Development/2.4 Command Center/Command_Center_UI/**` | ~10 |
| APIs | `docs/2. Development/2.4 Command Center/APIs/**` | ~15 |
| Overlay | `docs/2. Development/2.4 Command Center/Overlay/**` | ~15 |
| RFID_Cards | `docs/2. Development/2.4 Command Center/RFID_Cards/**` | ~10 |
| Backlog | `docs/2. Development/2.4 Command Center/Backlog/**` | ~20 |
| Test Plan | `docs/2. Development/2.4 Command Center/Integration_Test_Plan/**` | ~3 |

## ✅ 검증 항목

1. **derivative-of chain**: `Command_Center.md` frontmatter `derivative-of` = `../2. Development/2.4 Command Center/Command_Center_UI/Overview.md`
2. **last-synced 일치**: `CC_PRD last-synced` = `Overview.md last-updated`
3. **6 키 매핑 (Foundation §3)**: N · F · C · B · A · M 정확
4. **5-Act 시퀀스**: Hand Start → Deal → Bet → Showdown → Hand End
5. **Hole Card Visibility 4단 방어 (Foundation §9)**: RBAC / 2인승인 / 60분 Timer / 물리영역
6. **1×10 좌석 + 6 키 그리드**: 정확
7. **배포 정합**: Flutter Desktop (RFID 시리얼 + SDI/NDI 직결)
8. **CC = Orchestrator 패턴 (Foundation §11)**: CC → BO + Engine 병행 dispatch, Engine = SSOT
9. **Overlay 정합 (Foundation Ch.5 §C.1)**: Rive Manager 활성 .riv, 0~120초 보안 지연
10. **RFID_Cards 정합 (Foundation §13)**: 12 안테나, ST25R3911B + ESP32, Mock HAL

## 🔄 자율 Iteration

```
1. python tools/doc_discovery.py --impact-of "docs/1. Product/Command_Center.md"
2. CC_PRD ↔ Command_Center_UI/Overview.md 본문 비교
3. 2.4 CC/** 전수 (74) → Foundation §3,§9,§11,§13 cascade
4. drift 정정 (단일 commit per file)
5. PR ready
```

## 🚫 금지

- 다른 Stream 영역 수정
- 정본 임의 수정 (Foundation 원인이면 S1 escalate)
- meta files 수정

## 📋 PR 체크리스트

- [ ] CC_PRD ↔ Overview.md 본문 일치
- [ ] frontmatter `last-synced` 갱신
- [ ] 4단 방어 / 6 키 / 5 Act 일관
- [ ] `tools/doc_discovery.py --impact-of` 결과 = 0 drift
- [ ] PR title: `docs(s3-cc): consistency audit 2026-05-08`
- [ ] PR label: `stream:s3`, `consistency-audit`
