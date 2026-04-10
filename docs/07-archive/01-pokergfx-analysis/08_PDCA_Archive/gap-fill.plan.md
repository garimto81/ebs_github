# Plan: PokerGFX Feature Registry 갭 메우기

> **Ralplan 합의 결과** (Planner + Architect + Critic)

---

## 배경

이전 PDCA 사이클에서 5-Layer PokerGFX 분석 프레임워크를 구축했으나, gap-detector 상세 분석 결과 **80%** Match Rate로 90% 기준 미달.

### Match Rate 기록 (모순 해소)

| 검증자 | 점수 | 근거 |
|--------|:----:|------|
| Architect (간이) | 92% | 4/4 구조적 기준 충족, 소스 매핑만 제외 |
| gap-detector (상세) | **80%** | L5 소스 매핑 0%를 Layer 가중치로 반영 (L5 20% weight) |

**현재 기준치**: gap-detector 80% (상세 분석이 정확한 수치)

### 식별된 3개 GAP

| GAP | 심각도 | 설명 | 영향 Layer |
|:---:|:------:|------|:----------:|
| 1 | CRITICAL | feature-registry.json 소스 매핑 0% (149개 전체 null) | L5 |
| 2 | HIGH | actiontracker-messages.md에 Feature ID 역매핑 없음 | L3 |
| 3 | LOW | gametype-variants.md 별도 파일 미생성 → Design 문서 수정으로 해결 | L4 |

## 문제 정의

5-Layer 프레임워크의 최상위 통합 레이어(L5)가 skeleton 상태로, 하위 Layer 분석 결과의 교차 연결이 불가능. 구조적 연결성 7/10을 9/10으로 끌어올려야 함.

## 구현 범위

### 포함

1. **feature-registry.json 소스 매핑**: 149개 Feature 중 134개 이상에 최소 1개 non-null source
2. **actiontracker-messages.md Feature ID 역매핑**: 68개 메시지에 관련 Feature ID 추가
3. **Design 문서 수정**: gametype-variants.md를 별도 파일 대신 game-state-machine.md 통합으로 재정의
4. **confidence-audit.md 갱신**: 실제 매핑 상태 반영

### 제외

- live_app 소스 매핑 (별도 세션 필요)
- 매뉴얼 PDF 전체 교차참조 (113페이지, 별도 작업)
- Feature ID 추가/삭제/변경

## 복잡도 점수

| # | 조건 | 점수 | 근거 |
|:-:|------|:----:|------|
| 1 | 파일 범위 | 1 | feature-registry.json, actiontracker-messages.md, confidence-audit.md, design.md (4+ 파일) |
| 2 | 아키텍처 | 0 | 기존 5-Layer 프레임워크 내 데이터 채움 |
| 3 | 의존성 | 0 | 기존 도구만 사용 |
| 4 | 모듈 영향 | 1 | L3 Protocol + L5 Cross-Reference 2개 Layer |
| 5 | 사용자 명시 | 1 | ralplan 키워드 |
| **총점** | | **3/5** | **Ralplan 실행** |

## 실행 전략

### Phase A: 병렬 소스 매핑 (4개 Task 동시)

T1~T3는 각각 **중간 산출물 JSON 파일**을 생성. feature-registry.json을 직접 수정하지 않음.

| Task | 카테고리 | 수량 | 에이전트 | 출력 파일 |
|:----:|----------|:----:|----------|-----------|
| T1 | AT-001~026 | 26 | executor-high (opus) | `06_Cross_Reference/mappings/at-mappings.json` |
| T2 | VO-001~014, GC-001~025, PS-001~013 | 52 | executor (sonnet) | `06_Cross_Reference/mappings/vo-gc-ps-mappings.json` |
| T3 | SEC, SV, EQ, ST, HH | 71 | executor (sonnet) | `06_Cross_Reference/mappings/remaining-mappings.json` |
| T4 | 68개 메시지 Feature ID | - | executor (sonnet) | actiontracker-messages.md 직접 수정 |

### 중간 산출물 JSON 형식 (Critic 피드백 #3 반영)

```json
{
  "AT-001": {
    "sources": {
      "binary": {
        "files": ["ClientNetworkService.cs:ConnectToServer"],
        "confidence": "V"
      },
      "screenshot": {
        "ref": "01-main-window.png#status-bar",
        "confidence": "O"
      }
    },
    "ebs_mapping": {
      "protocol_message": "ConnectToServer"
    }
  }
}
```

### Schema Migration (Critic 피드백 #4 반영)

현재 JSON: `"binary": null` → 목표: `"binary": {"files": [...], "confidence": "V"}`

각 T1/T2/T3 에이전트가 Design 스키마 형식의 구조화된 객체를 생성. T5에서 null을 구조화된 객체로 교체.

### Phase B: JSON 통합 (순차)

| Task | 작업 | 에이전트 |
|:----:|------|----------|
| T5 | 3개 중간 JSON → feature-registry.json 통합 + cross-cut validation | executor (sonnet) |

**Cross-cut Validation** (Architect 조건 #1): protocol_message가 여러 카테고리에 걸치는 경우 검증.

### Phase C: 문서 갱신 (병렬)

| Task | 작업 | 에이전트 |
|:----:|------|----------|
| T6 | confidence-audit.md 수치 갱신 | executor-low (haiku) |
| T7 | Design 문서 수정 (gametype-variants → 통합 유지) | executor-low (haiku) |

## 예상 영향 파일

- `docs/01_PokerGFX_Analysis/06_Cross_Reference/feature-registry.json` (수정)
- `docs/01_PokerGFX_Analysis/06_Cross_Reference/confidence-audit.md` (수정)
- `docs/01_PokerGFX_Analysis/06_Cross_Reference/mappings/` (신규 디렉토리)
- `docs/01_PokerGFX_Analysis/04_Protocol_Spec/actiontracker-messages.md` (수정)
- `docs/02-design/pokergfx-analysis-framework.design.md` (수정)

## 검증 방법 (Critic 피드백 #2 반영)

gap-detector는 `bkit:gap-detector` 에이전트. 추가로 기계적 검증 명령:

```python
python -c "import json; d=json.load(open('feature-registry.json')); mapped=sum(1 for f in d['features'].values() if any(v is not None for v in f['sources'].values())); print(f'{mapped}/149 ({mapped*100//149}%)')"
```

### 검증 기준

| 기준 | 목표 | 측정 방법 |
|------|:----:|----------|
| Feature 소스 매핑률 | 90%+ (134/149) | Python 스크립트 |
| 메시지 Feature ID | 68/68 | grep "관련 Feature ID" 카운트 |
| JSON 유효성 | PASS | `python -m json.tool` |
| gap-detector | 90%+ | bkit:gap-detector 에이전트 재실행 |
| Architect | APPROVED | oh-my-claudecode:architect 검증 |

## 위험 요소

| 위험 | 확률 | 영향 | 완화 |
|------|:----:|:----:|------|
| ConfuserEx 난독화로 V등급 불가 | 높음 | 중간 | I등급 + 추론 근거 |
| 중간 JSON 통합 시 형식 오류 | 중간 | 높음 | python -m json.tool 검증 |
| 스크린샷에서 Feature 식별 불가 | 낮음 | 낮음 | inference 소스로 보완 |

## Ralplan 합의 요약

| 역할 | 판정 | 반영 사항 |
|------|:----:|----------|
| Planner | 완성 | 8개 Task, 3 Phase 구조 |
| Architect | APPROVED (조건부) | 조건 3개: cross-cut validation, 양방향 matrix, 참조 링크 → 반영 완료 |
| Critic | REJECTED → 재수정 | 5개 개선: 80%/92% 모순 해소, gap-detector 정의, 중간 산출물 형식, schema migration, T5 다운그레이드 → 전부 반영 |

## 관련 PRD

PRD-0003-EBS-RFID-System

## 기존 Plan 중복 확인

| 기존 Plan | 관계 |
|-----------|------|
| `pokergfx-analysis-framework.plan.md` | 후속 작업 (skeleton 구축 → 데이터 채움) |

---

**Version**: 1.0.0 | **Updated**: 2026-02-13
