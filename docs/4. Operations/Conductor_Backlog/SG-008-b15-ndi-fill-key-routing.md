---
id: SG-008-b15
title: "NDI Fill/Key 분리 라우팅 — 방송 시설 협의 필요"
type: spec_gap
sub_type: spec_drift_b_escalated
parent_sg: SG-008-b13
status: RESOLVED
owner: conductor
decision_owners_notified: [team1, team4]
created: 2026-04-20
resolved: 2026-04-20
reimplementability: PASS
reimplementability_checked: 2026-04-20
reimplementability_notes: "status=RESOLVED, NDI Fill/Key 라우팅 default 채택"
---

# SG-008-b15 — NDI Fill/Key 분리 라우팅

## 배경

SG-008-b13 triage 에서 `fillKeyRouting` 필드가 team1 settings provider 에 code-only 로 존재 (D3). (b) 승격 — 단순 UI 옵션이 아닌 **방송 인프라 라우팅 정책**.

## 배경 지식

**NDI Fill/Key**:
- **Fill**: 실제 그래픽 색상 (RGB)
- **Key**: 투명도 마스크 (알파 채널, 흑백)
- 방송 스위처(ATEM, Tricaster)는 **Fill + Key 2 signal** 을 받아 Luma Key 합성으로 자연스러운 오버레이 표현
- 단일 signal 만 보내면 스위처가 chroma key (녹색 배경 제거) 로 대체 — 품질 저하

EBS Overlay 는 현재 **단일 NDI stream** 으로 송출 중 (team4 code 가정). 방송 시설 요구가 명확해질 때 Fill/Key 분리로 전환.

## 논점

1. **Fill/Key 분리 필수?**: 일반 방송 제작 표준이나 EBS 프로토타입/시연 단계에서는 단일 stream 충분
2. **라우팅 방식**: 단일 NDI source 로 묶음(dual-source) vs 2개 NDI source 생성?
3. **네이밍**: `EBS-Overlay-Fill` / `EBS-Overlay-Key` vs 통합
4. **성능**: 2배 대역폭 필요. LAN 10Gbps 환경 필수
5. **SDI 확장**: NDI 뿐 아니라 SDI 출력에서도 동일 정책 필요 (BlackMagic UltraStudio 등)

## 결정 옵션

| 옵션 | 내용 | 장점 | 단점 |
|------|------|------|------|
| **1. 항상 분리 (Fill+Key 2 source)** | 모든 Output 에 Fill/Key 2 source 생성 | 방송 표준, 스위처 호환 | 대역폭 2배, 프로토타입 과잉 |
| **2. 설정에 따라 분리 (단일/분리 토글)** | `fillKeyRouting` 필드로 사용자 선택 | 유연 | 스위처 설정 불일치 시 혼란 |
| **3. 단일 stream 유지 (프로토타입)** | 현재 방식 유지, Phase 2 전환 | 단순 | 방송 환경 즉시 대응 불가 |
| **4. Output 프리셋별 설정** | OutputPreset 에 fillKey 모드 편입 | 다양한 시설 지원 | UI 복잡 |

## Default 제안

**채택: 옵션 4 — Output 프리셋별 설정 (단, 프로토타입 기본값은 단일 stream)**

### 세부 결정

1. **OutputPreset 모델 확장**: `fill_key_mode: enum("single", "separate")` 추가 (default: "single")
2. **설정 UI**: Outputs 탭 §"NDI 고급" 서브그룹 — 체크박스 + 네이밍 패턴
3. **Runtime 동작**:
   - `single`: 기존 방식 — 단일 source (`EBS-Overlay-{table_id}`)
   - `separate`: 2 source (`EBS-Overlay-{table_id}-Fill` + `EBS-Overlay-{table_id}-Key`)
4. **Key 생성**: Flutter Overlay 렌더링 후 alpha channel 을 별도 8-bit greyscale 로 변환
5. **SDI 확장**: Phase 2 (SDI 하드웨어 도입 후)

### 이유

- 프로토타입 단계: 단일 stream 로 시연·개발 충분 (방송 품질 과잉 요구 불필요)
- 시설 도입 시 **preset 단위** 로 easily 전환 가능 (Table 별로 다른 시설 대응)
- 네이밍 표준화: 외부 스위처 운영자가 Fill/Key 매칭 즉시 식별
- Phase 2 에서 SDI + 물리 distributor 추가

### 대역폭 계산 (참고)

- 1080p60 NDI HX: ~100 Mbps (single)
- 1080p60 NDI Full: ~200 Mbps (single)
- Fill + Key 분리: ~300 Mbps (합계, HX 기준)
- 10 table × 300 Mbps = 3 Gbps — 10 GbE LAN 필요

## fillKeyRouting 필드 의미 재정의

team1 code-only 필드였던 `fillKeyRouting` 은 **Outputs.outputPresets[*].fill_key_mode** 로 이동:

- `fillKeyRouting: 'single'` / `'separate'` (enum)
- 기존 field 는 deprecation 마커 후 제거 (team1 다음 세션)

## 영향 챕터 업데이트

- [ ] `docs/2. Development/2.1 Frontend/Settings/Outputs.md` §"NDI 고급" 서브그룹 추가 (fill_key_mode + 네이밍 패턴)
- [ ] `docs/2. Development/2.4 Command Center/APIs/` OutputPreset 모델 확장 (fill_key_mode enum)
- [ ] `docs/2. Development/2.4 Command Center/Overlay/` NDI 송출 섹션 — Fill/Key 생성 로직
- [ ] team4 overlay renderer — alpha → key channel 변환
- [ ] team1 settings provider: `fillKeyRouting` 제거 + `outputPresets[*].fill_key_mode` 로 이동
- [ ] team2 DB schema: OutputPreset 테이블 (있으면) `fill_key_mode` 컬럼

## 수락 기준

- [ ] OutputPreset 에 `fill_key_mode` 필드 (default: "single")
- [ ] `separate` 선택 시 NDI source 2개 생성 확인
- [ ] Fill source 와 Key source 네이밍 표준 준수
- [ ] 네트워크 대역폭 모니터링 경고 (3 Gbps 초과 시)
- [ ] 스위처 연결 가이드 문서 (ATEM/Tricaster 설정 예시)

## Phase 2 확장 (별도 SG)

- SDI 물리 신호 분리 (BlackMagic UltraStudio API)
- Hardware chroma key 대체 (Fill/Key 미지원 스위처)
- Dynamic resolution 조정 (네트워크 상황 기반)

## 재구현 가능성

- SG-008-b15: **PASS** (본 문서 자립)
- team1 Settings §Outputs NDI 고급: PASS 전환 (fill_key_mode 편입 후)
- team4 Overlay NDI renderer: UNKNOWN → PASS (분리 로직 구현 후)
