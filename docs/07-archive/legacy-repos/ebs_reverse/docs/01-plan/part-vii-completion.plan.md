# PDCA Plan: Part VII 인터페이스 설계 완성

**Plan ID**: part-vii-completion
**Created**: 2026-02-16
**Status**: APPROVED
**Complexity**: 3/5 (STANDARD)

---

## 배경

PRD v2 (v6.0.0) Part VII "사용자 인터페이스 설계"(Section 17-21)는 멘탈 모델과 워크플로우 수준에서 우수하나, 화면별 구현 스펙이 부족하다. Architect Gap 분석 결과 완성도 60%, 27개 HTML 목업 중 5개만 PRD에 참조됨.

## 문제 정의

1. **11개 서버 화면 목업 미통합** (CRITICAL): server-01~11 HTML 목업이 존재하나 PRD Part VII에서 미참조
2. **화면별 레이아웃 스펙 부재** (CRITICAL): 개발자가 구현할 수 없는 수준의 추상적 서술
3. **인터랙션 설계 부재** (HIGH): 클릭/드래그/키보드 단축키/터치 동작 미정의
4. **상태 관리 스펙 부재** (HIGH): 로딩/에러/비활성/빈 상태 UI 미정의

## 구현 범위

### 접근법: 기존 구조 확장 (번호 변경 없음)

Part VIII(Section 22), Part IX(Section 23-26) 번호를 건드리지 않고, Section 18-19를 서브섹션으로 확장한다.

### Section 18 확장 (준비 단계)

| 서브섹션 | 대상 목업 | 내용 |
|---------|----------|------|
| 18.2 메인 윈도우 | server-01 | 3-column 레이아웃, 툴바, 상태바, RFID 그리드, Quick Actions |
| 18.3 시스템 설정 → 확장 | server-08 | RFID 12대 설정 그리드, 네트워크, 라이선스, 진단, 폴더/백업 |
| 18.4 비디오 파이프라인 → 확장 | server-02, 03 | Sources 테이블, 속성 패널, Outputs Dual Canvas, 보안/딜레이 |
| 18.5 스킨 에디터 → 확장 | server-09, 10, 11 | 3-Panel IDE 상세, Element Tree, Canvas, Properties |

### Section 19 확장 (본방송)

| 서브섹션 | 대상 목업 | 내용 |
|---------|----------|------|
| 19.4 GFX1 → 확장 | server-04 | 24개 기능 6그룹, 52장 카드 그리드, 좌석 토글 |
| 19.5 GFX2 통계 → 신규 | server-05 | VPIP/PFR/AF 테이블, 리더보드, 토너먼트, 데이터 내보내기 |
| 19.6 GFX3 방송 연출 → 신규 | server-06 | Lower Third, 티커, 오버레이 레이어, 애니메이션 |
| 19.7 해설자 피드 → 확장 | server-07 | 보안 격리, 표시 옵션 6개 토글, 카메라/PIP |

### Section 20.5 인터랙션 & 상태 설계 (신규 삽입)

Section 20(시청자 경험)과 Section 21(기능 추적표) 사이에 삽입:
- 20.5.1 터치 타겟 & 클릭 영역
- 20.5.2 키보드 단축키
- 20.5.3 에러 상태 UI (6개 시나리오)
- 20.5.4 로딩/비활성/빈 상태

## 제외 항목

- Part VIII/IX 번호 변경 (호환성 보존)
- 접근성 상세 (별도 PDCA cycle)
- 애니메이션 타이밍 상세 (구현 단계에서 결정)
- 반응형 디자인 (WinForms 고정 레이아웃 전제)

## 예상 영향 파일

- `docs/01-plan/pokergfx-prd-v2.md` Section 18-21 (약 500줄 → 1,200줄 예상)
- `docs/01-plan/part-vii-draft.md` (동기화)

## 위험 요소

1. **PRD 길이 증가**: 1,916줄 → ~2,600줄 (36% 증가). 스펙 문서이므로 허용 범위
2. **목업-텍스트 불일치**: HTML 목업 세부사항과 PRD 서술 차이 가능 → 목업 우선
3. **Section 20.5 삽입**: 중간 번호(20.5)가 비관례적 → "20-bis" 또는 별도 처리 가능

---

**Version**: 1.0.0 | **Updated**: 2026-02-16
