# Plan: PokerGFX 완전 분석 프레임워크

> **Ralplan 합의 결과** (Planner + Architect + Critic 3자)

**복잡도 점수**: 4/5
- 파일 범위: 1 (10개+ 문서 생성/수정)
- 아키텍처: 1 (5-Layer 프레임워크 신규 도입)
- 의존성: 1 (ILSpy CLI 재설치)
- 모듈 영향: 1 (4개 소스 교차 연동)
- 사용자 명시: 0

**관련 PRD**: PRD-0003-EBS-RFID-System

---

## 배경

PokerGFX Server 3.111을 완벽하게 분석하여 EBS Phase 1에서 100% 복제하기 위한 체계적 분석 프레임워크가 필요하다.

현재 3개의 독립 문서(UI Analysis 270+ 요소, Feature Checklist 149개, Binary Analysis 2,877 C# 파일)가 존재하나, **구조적 연결성이 3/10**으로 교차 참조가 불가능한 상태.

## 문제 정의

| 문제 | 심각도 | 영향 |
|------|:------:|------|
| 출처 추적 없음 | CRITICAL | 149개 기능 중 확인 vs 추론 구분 불가 |
| 교차 참조 매트릭스 없음 | CRITICAL | 4개 소스 간 연결 부재 |
| ActionTracker 메시지 페이로드 미문서화 | HIGH | 50+ 메시지 이름만 있고 구조 없음 |
| 게임 상태 머신 미매핑 | HIGH | 전이 다이어그램 없음 |
| DB 스키마 미추출 | HIGH | Entity Framework 모델 미정리 |
| 매뉴얼 교차참조 없음 | HIGH | 113페이지 미활용 |
| 숨겨진 UI 미분석 | MEDIUM | 다이얼로그/팝업 미캡처 |
| 디컴파일 파일 미보존 | CRITICAL | 이전 세션 결과물 디스크에 없음 |

## 구현 범위

### 포함 항목

1. **ILSpy 재설치 + 바이너리 4개 재디컴파일 + 영구 보존**
2. **ActionTracker 50+ 메시지 페이로드 스키마 문서화**
3. **게임 상태 머신 전이 다이어그램 작성**
4. **5-Layer 분석 프레임워크 디렉토리 구조 생성**
5. **Feature ID 기반 JSON Registry 스켈레톤 구축**
6. **출처 신뢰도 3등급 체계 도입** (Verified/Observed/Inferred)

### 제외 항목

| 제외 | 이유 |
|------|------|
| render.cs 심층 분석 | EBS Flutter/Rive 사용, ROI 15% |
| KEYLOK DRM 로직 | EBS 미채택 |
| RFID 하드웨어 프로토콜 역공학 | EBS 자체 JSON 프로토콜, Phase 0 하드웨어 테스트로 대체 |
| 매뉴얼 전문 분석 | 본 Phase에서는 구조만 수립, 내용 채움은 후속 |
| ActionTracker UI 스크린샷 | 앱 실행 필요 (별도 세션) |

## 예상 영향 파일

```
docs/01-plan/pokergfx-analysis-framework.plan.md          # 신규
docs/02-design/pokergfx-analysis-framework.design.md       # 신규
docs/01_PokerGFX_Analysis/04_Protocol_Spec/                # 신규 디렉토리
  actiontracker-messages.md                                # 신규
docs/01_PokerGFX_Analysis/05_Behavioral_Spec/              # 신규 디렉토리
  game-state-machine.md                                    # 신규
docs/01_PokerGFX_Analysis/06_Cross_Reference/              # 신규 디렉토리
  feature-registry.json                                    # 신규
  confidence-audit.md                                      # 신규
docs/01_PokerGFX_Analysis/07_Decompiled_Archive/           # 신규 디렉토리
  README.md                                                # 신규
  (2,877개 .cs 파일)                                       # ILSpy 출력
docs/04-report/pokergfx-analysis-framework.report.md       # 신규
```

## 위험 요소

| 위험 | 확률 | 영향 | 완화 |
|------|:----:|:----:|------|
| ILSpy 설치 실패 | LOW | HIGH | dotnet SDK 8.0 이미 설치됨, 대안: GUI ILSpy |
| Server.exe 난독화로 핵심 로직 접근 불가 | HIGH | MEDIUM | ActionTracker.exe (부분 난독화) 우선 분석 |
| 디컴파일 출력 용량 과다 | MEDIUM | LOW | git에 포함하지 않고 로컬 아카이브 |
| core.cs 25,643 LOC 분석 시간 초과 | MEDIUM | MEDIUM | 정적 필드 + Send 메서드만 우선 추출 |

## Planner/Architect/Critic 관점 요약

### Planner
- 8개 갭 식별, CRITICAL 2개 + HIGH 4개 + MEDIUM 2개
- 분석 목적 3옵션 제시 → **하이브리드** 채택

### Architect
- ActionTracker 메시지 85% 실현, 상태 머신 60%, render.cs 15%
- RFID 소프트웨어 분석 충분, 추가 불필요
- **구조적 연결성 3/10이 가장 시급한 문제**
- JSON Registry + 출처 3등급 권고

### Critic
- 5번째 소스 타입 추가: **Live Application** (설치된 앱 자체)
- ActionTracker UI 스크린샷 누락 지적
- GameType 변형 매핑 누락 지적
- **디컴파일 파일 재접근성이 Critical Path**

## 실행 순서

| 단계 | 작업 | 선행 | 산출물 |
|:----:|------|:----:|--------|
| 0 | ILSpy 재설치 + 디컴파일 | 없음 | 07_Decompiled_Archive/ |
| 1 | ActionTracker 메시지 추출 | #0 | 04_Protocol_Spec/ |
| 2 | 게임 상태 머신 매핑 | #0 | 05_Behavioral_Spec/ |
| 3 | 디렉토리 구조 + Registry 스켈레톤 | Design 완료 | 06_Cross_Reference/ |
| 4 | 이중 검증 | #1,#2,#3 | Check 결과 |
| 5 | 완료 보고서 | #4 | 04-report/ |

## 기존 Plan 중복 확인

`docs/01-plan/` 내 기존 Plan 없음 (신규 디렉토리).

---

**Version**: 1.0.0 | **Updated**: 2026-02-12
