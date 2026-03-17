---
name: karpathy-guidelines
description: >
  This skill should be used when applying Andrej Karpathy's 6 development principles during code review, new code writing, refactoring, or debugging.
version: 2.0.0
triggers:
  keywords:
    - "karpathy"
    - "개발 원칙"
    - "코드 리뷰"
    - "리팩토링"
    - "코드 작성"
    - "디버깅"
    - "카파시"
    - "코드 리뷰 원칙"
auto_trigger: false
---

# Karpathy Guidelines Skill

Andrej Karpathy의 관찰에서 도출된 6가지 핵심 개발 원칙을 Claude Code 워크플로우에 적용하는 스킬.
코드 리뷰, 새 코드 작성, 리팩토링, 디버깅 상황에서 원칙에 기반한 판단과 실행을 돕습니다.

## 자동 트리거 조건

다음 상황에서 이 스킬의 원칙들을 자동 적용한다:

- **코드 작성**: 새 함수/클래스/모듈 작성 요청 시
- **코드 리뷰**: 기존 코드의 품질 검토 요청 시
- **리팩토링**: 구조 개선, 중복 제거 요청 시
- **디버깅**: 오류 원인 추적 및 수정 요청 시
- **문서 작성**: 기술 문서, README, 가이드 작성 요청 시

## 핵심 참조 문서

- **원칙 정의**: `C:\claude\.claude\skills\karpathy-guidelines\CLAUDE.md`
- **실전 예시**: `C:\claude\.claude\skills\karpathy-guidelines\EXAMPLES.md`

## 실행 지침

이 스킬이 트리거되면:

1. `C:\claude\.claude\skills\karpathy-guidelines\CLAUDE.md`를 읽고 6개 원칙을 확인한다
2. 현재 요청에 적용되는 원칙을 식별한다
3. 해당 원칙에 따라 작업을 수행한다
4. 원칙 위반 가능성이 있는 경우 사용자에게 명시적으로 알린다

예시 필요 시 `C:\claude\.claude\skills\karpathy-guidelines\EXAMPLES.md`를 참조한다.
