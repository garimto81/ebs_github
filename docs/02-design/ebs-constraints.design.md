---
doc_type: "design"
doc_id: "DESIGN-CON-v3"
version: "1.0.0"
status: "draft"
owner: "BRACELET STUDIO"
created: "2026-03-11"
last_updated: "2026-03-11"
prd_ref: "EBS-UI-Design-v3 v9.0.0 §6"
---

# 제약 조건

## 6.1 화면 크기

| 앱 | 최소 | 권장 | 비고 |
|----|------|------|------|
| EBS Console | 1024x768 | 1920x1080 | 반응형, Top-Preview 레이아웃 (Menu Bar 28px + Preview 가변 + Info Bar 36px + Tab Bar 36px + Tab Content 가변) |
| Action Tracker | 1024x600 | 1280x800 | 태블릿 가로(Landscape) 고정 |
| 오버레이 출력 | 1920x1080 | 1920x1080 | 방송 표준 (4K 스케일링 대응) |
| 오버레이 세로 | 1080x1920 | 1080x1920 | 9:16 모바일 스트리밍 |

## 6.2 터치 제약 (Action Tracker)

| 항목 | 사양 |
|------|------|
| 최소 터치 타겟 | 48x48px (WCAG 2.5.8) |
| 액션 버튼 영역 | 화면 하단 1/3 고정 (thumb zone) |
| 방향 | 가로(Landscape) 고정. 세로 전환 불가 |
| 제스처 | 탭(선택), **개별 좌석 셀 위** 좌측 스와이프(해당 좌석 폴드), 롱프레스(상세 정보). 스와이프 인식 영역은 좌석 셀 경계 내로 제한 |
| 멀티터치 | 지원하지 않음 (오입력 방지) |

## 6.3 오버레이 렌더링 제약

| 항목 | 사양 |
|------|------|
| 프레임레이트 | 60fps 최소 (GPU 가속 렌더링) |
| 렌더링 영역 | 1920x1080 고정 캔버스 |
| 투명도 지원 | Fill & Key NDI 출력 (알파 채널 필수) |
| 폰트 | 시스템 산세리프 기본. 커스텀 폰트 로딩 지원 |
| 카드 에셋 | 60x84px PNG 투명 배경 x 52장 + 카드 백 1장 |
| 렌더링 | Flutter/Rive 기반. 스킨은 .riv 파일로 관리 |
| 커스터마이징 범위 | 위치/크기 자유 설정. 화면 경계 밖 배치 금지. 최소 크기 60x40px |
| 템플릿 저장 | 사용자 커스텀 템플릿 최대 20개 저장 |

## 6.4 성능 기준

| 항목 | 기준 |
|------|------|
| 오버레이 업데이트 지연 | < 100ms (설정 변경 → Preview 반영) |
| RFID → 오버레이 표시 | < 500ms (카드 태핑 → 화면 표시) |
| 오버레이 렌더링 프레임레이트 | ≥ 60fps (GPU 가속 시 120fps 목표) |
| AT → 오버레이 액션 반영 | < 200ms (버튼 탭 → 오버레이 갱신) |
| WebSocket 메시지 왕복 | < 50ms (로컬 네트워크) |

## 6.5 보안

| 항목 | 요구사항 |
|------|---------|
| WebSocket 통신 | TLS 암호화 (wss://) |
| Table Password | bcrypt 해싱 저장 |
| RFID UID | 로컬 전용 — 외부 네트워크 전송 금지 |
| Hand History | 암호화 옵션 (AES-256, 선택적 활성화) |
| API 접근 | 인증 토큰 기반 (JWT) |

## 6.6 신뢰성

| 항목 | 요구사항 |
|------|---------|
| WebSocket 재연결 | 자동 재연결 (5초 간격, 최대 12회 = 60초) |
| RFID 폴백 | 5초 인식 실패 시 수동 입력 그리드 자동 활성화 |
| 설정 영속화 | 변경 즉시 로컬 파일 저장 (크래시 시에도 설정 보존) |
| 크래시 복구 | 앱 재시작 시 마지막 핸드 상태 자동 복원 시도 |
| AT 연결 | Console-AT 간 WebSocket 끊김 시 5초 간격 자동 재연결 |

## 6.7 기술 스택 참조

EBS의 기술 아키텍처는 v2에서 정의되었으며, 아래는 v3에서 변경된 사항이다:

| 영역 | v2 | v3 변경 |
|------|-----|---------|
| 오버레이 렌더링 | 미정 | **Flutter/Rive** 기반 |
| Console 앱 | 미정 | Flutter 데스크톱 (Windows/macOS) |
| Action Tracker | 미정 | Flutter 모바일/태블릿 |
| 서버 | FastAPI | 유지 |
| 통신 | WebSocket | 유지 |

> 구체적 기술 스택 결정, 패키지 선택, 빌드 설정 등은 기술 문서에서 다룬다.

## 6.8 레퍼런스

| 자료 | 경로 |
|------|------|
| PokerGFX 주석 이미지 | `docs/01_PokerGFX_Analysis/02_Annotated_ngd/` |
| PokerGFX 크롭 이미지 | `docs/01_PokerGFX_Analysis/03_Cropped_ngd/` |
| PokerGFX 매뉴얼 | `docs/01_PokerGFX_Analysis/03_Reference_ngd/` |
| Whitepaper (247개 요소) | `C:/claude/ui_overlay/docs/03-analysis/pokergfx-v3.2-complete-whitepaper.md` |
| Feature Interactions | `docs/01_PokerGFX_Analysis/PRD-0004-feature-interactions.md` |
| v2.0 기술 아키텍처 | *(archived, 삭제됨 — 본 문서 §6.7에 통합)* |

---

## Changelog

| 날짜 | 버전 | 변경 내용 | 결정 근거 |
|------|------|-----------|----------|
| 2026-03-11 | v1.0.0 | EBS-UI-Design-v3.prd.md §6에서 분리 | 설계 내용 방대, 개발 시 별도 진행하기에 분리 |

---

**Version**: 1.0.0 | **Updated**: 2026-03-11
