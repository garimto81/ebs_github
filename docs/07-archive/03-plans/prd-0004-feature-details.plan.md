# Plan: PRD-0004 Feature Interaction Details

## 목표

PRD-0004-EBS-Server-UI-Design.md의 184개 UI 요소에 대해 기능별 상세 로직, 상태 변화, 연관 요소, Mermaid 다이어그램을 포함한 위성 문서를 작성한다.

## 산출물

`docs/01_PokerGFX_Analysis/PRD-0004-feature-interactions.md`

## 구조

PRD-0004 본문의 장(chapter) 구조를 따르되, 각 요소별 상세 인터랙션 명세를 추가한다.

### 요소별 상세 템플릿

**Complex (Mermaid sequence diagram 포함)**: ~30개 핵심 요소
```
### X-NN: 요소명
- **트리거**: 버튼 클릭 / 단축키 / 자동
- **전제조건**: 필요한 시스템 상태
- **로직 플로우**: 단계별 내부 동작
- **상태 변화**: 게임 상태 / UI 상태 전이
- **영향 요소**: 연동되는 다른 UI 요소 (ID 참조)
- **비활성 조건**: 사용 불가 시점
- **Mermaid 다이어그램**
```

**Medium (로직 + 영향 요소)**: ~80개 요소
```
### X-NN: 요소명
- **트리거/전제조건**
- **로직**: 간결한 동작 설명
- **영향 요소**: 연동 요소
- **비활성 조건** (해당 시)
```

**Simple (간결 설명)**: ~74개 요소
```
### X-NN: 요소명
동작 설명 1-2줄. 영향 요소 참조.
```

## Complex 요소 목록 (Mermaid 다이어그램 필요)

### Main Window (7개)
- M-02 Preview Panel: GPU 렌더링 파이프라인 연동
- M-07 Lock Toggle: 전역 상태 전환
- M-08 Secure Delay: Dual Canvas 파이프라인 제어 *(추후 개발)*
- M-10 Delay Progress: 딜레이 버퍼 연동 *(추후 개발)*
- M-11 Reset Hand: 게임 상태 초기화 전체 플로우
- M-13 Register Deck: 52장 RFID 등록 플로우
- M-14 Launch AT: 앱 간 통신 연결

### Sources (3개)
- S-00 Output Mode: 모드별 UI 가시성 분기
- S-06 Auto Camera: 게임 상태 기반 자동 전환
- S-14 ATEM Control: 외부 스위처 연결

### Outputs (4개)
- O-04/O-05 Live Pipeline: Fill & Key 채널 매핑
- O-06/O-07 Delay Pipeline: Delay 독립 파이프라인 *(추후 개발)*
- O-08 Secure Delay: 딜레이 버퍼 리사이징 *(추후 개발)*
- O-20 DeckLink Channel Map: 포트 매핑

### GFX (7개)
- G-01 Board Position: Global 레이아웃 변경
- G-14 Reveal Players: 카드 공개 시점 제어
- G-15 How to Show Fold: 폴드 표시 연출
- G-37 Show Hand Equities: Equity 계산 트리거
- G-38 Hilite Winning Hand: 위닝 핸드 강조
- G-47 Currency Symbol: Global 통화 변경

### System (5개)
- Y-03 RFID Reset: 시스템 초기화
- Y-04 RFID Calibrate: 안테나 캘리브레이션
- Y-09 Table Diagnostics: 별도 창 진단
- Y-13 Allow AT Access: AT 접근 정책
- Y-15 Kiosk Mode: AT 기능 제한

### Skin/Graphic Editor (3개)
- SK-06 Element Buttons: Graphic Editor 진입
- SK-26 Use: 스킨 적용 플로우
- Graphic Editor 전체: Board/Player 모드 전환

## 참조 소스

1. PRD-0004-EBS-Server-UI-Design.md (v13.0.0) — UI 요소 정의
2. PRD-0004-technical-specs.md (v1.0.0) — 게임 상태 머신, GPU 파이프라인, 통신 프로토콜
3. pokergfx-prd-v2.md — 전체 시스템 아키텍처

## 실행 계획

1. 위성 문서 작성 (executor-high, opus)
2. PRD-0004 본문 satellite_docs 필드 업데이트
3. Architect 검증 (정합성, 누락 확인)
