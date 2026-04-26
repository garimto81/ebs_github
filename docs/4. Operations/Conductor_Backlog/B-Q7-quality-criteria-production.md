---
title: B-Q7 — 품질 기준 (prototype-grade vs production-grade 측정) (사용자 명시 대기)
owner: conductor
tier: internal
status: PENDING
type: backlog-deferred-decision
linked-sg: SG-023
linked-decision-pending: user (품질 측정 기준 명시 부재)
last-updated: 2026-04-27
---

## 개요

SG-023 (인텐트 = production 출시) 의 "100% 검증된 완제품 + 운영 가능 상태" 정의. **사용자 명시 결정 필요**.

## 결정 사항

production-grade 의 정확한 측정 기준:

| 측정 영역 | 가능한 기준 | 사용자 결정 |
|----------|------------|:----------:|
| Test coverage | 80% / 90% / 95% / 100% | ? |
| API 응답 시간 | p50 100ms / p99 200ms / SG-022 의 100ms 전체 파이프라인 (BLANK-1) | ? |
| Uptime SLA | 99% / 99.9% / 99.99% | ? |
| 에러율 | 1% / 0.1% / 0% | ? |
| 부하 처리 | N 동시 테이블 / N 동시 사용자 | ? |
| 보안 audit | OWASP Top 10 / 별도 외부 audit | ? |
| 접근성 (a11y) | WCAG 2.1 AA / AAA / 미준수 | ? |
| i18n | 한글 + 영어 / 다국어 / 한글만 | ? |

## 선택지 (조합)

| 옵션 | 의미 |
|:----:|------|
| ㉠ Production-strict | 95%+ coverage, 99.9% uptime, p99<200ms, OWASP audit, WCAG AA, 한+영 |
| ㉡ Production-balanced | 80%+ coverage, 99% uptime, p50<100ms, OWASP 기본, 한글 |
| ㉢ MVP-grade | 60%+ coverage (key path), 가용 가능, 한글 only |
| ㉣ 사용자 명시 (직접 입력) | — |

## 영향

- ㉠ 채택 시: 모든 팀 작업에 strict 측정 기준 적용. 시간 비용 큼.
- ㉡ 채택 시: 표준 production 수준. 합리.
- ㉢ 채택 시: production 인텐트의 1차 단계. 향후 ㉠/㉡ 으로 전환 가능.
- ㉣ 채택 시: 사용자 입력 후 cascade.

## 후속 cascade (사용자 결정 후)

- Spec_Gap_Triage.md 의 verification 섹션 갱신
- 각 팀 CLAUDE.md 의 build 명령 + 테스트 기준 갱신
- integration-tests/ 의 시나리오 보강
- CI/CD 파이프라인 정비 (B-Q4 cascade 와 연계)

## 참조

- memory `project_intent_production_2026_04_27` (SG-023 SSOT)
- SG-022 의 BLANK-1 (100ms 전체 파이프라인) — 이미 결정됨
- SG-023, SG-024 (선행 결정)
