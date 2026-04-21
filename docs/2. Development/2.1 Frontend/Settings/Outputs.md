---
title: Outputs
owner: team1
tier: internal
legacy-id: BS-03-01
last-updated: 2026-04-21
reimplementability: PASS
reimplementability_checked: 2026-04-21
reimplementability_notes: "2026-04-21 교차검증 완료: lib/features/settings/screens/outputs_screen.dart 에 output_targets/active_overlay_preset_id/security_delay_ms/watermark_* 전 필드 구현 확인 (grep). SG-003 §Tab 1 스키마 충족."
sg_reference: SG-003
scope: table
---

# BS-03-01 Outputs — 송출 설정

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | NDI/HDMI 출력, Security Delay, 크로마키, 미리보기, 프리셋 정의 |
| 2026-04-09 | Console PRD v9.7 재설계 | §2.7 기반 — Resolution/Live Pipeline/Output Mode 3서브그룹, 13 컨트롤 |

---

## 개요

Outputs 섹션은 Settings의 첫 번째 탭으로, 오버레이 그래픽의 **방송 송출 파이프라인**을 구성한다. 3-Column 구조: Resolution(해상도/프레임레이트) → Live Pipeline(NDI/RTMP/SRT/DIRECT) → Output Mode(Fill & Key).

> 참조: Console PRD v9.7 §2.7 Outputs 탭

---

## 1. 컨트롤 목록

### 1.1 Resolution 서브그룹 (ID 2~4)

| ID | 이름 | 타입 (shadcn/ui) | 기본값 | 설명 | 오버레이 영향 |
|:--:|------|-----------------|--------|------|-------------|
| 2 | Video Size | Select | 1080p | 출력 해상도 (720p / 1080p / 4K) | 렌더링 캔버스 해상도 |
| 3 | 9:16 Vertical | Switch | OFF | 세로 모드 토글 (모바일 스트리밍용) | 좌표계 16:9→9:16 전환 |
| 4 | Frame Rate | Select + Input[type=number] | 60fps | 프레임레이트 (24/25/30/50/60fps + 수동 1~120) | 렌더링 fps |

**동작**: Video Size 변경 시 Preview Area + 오버레이 캔버스가 재초기화된다 (약 1초 블랙아웃). 방송 중 변경 비권장. 9:16 Vertical 활성화 시:

- Preview Area 종횡비: 16:9 → 9:16 (width/height 역전)
- Player Layout: 가로 1열 → 좌우 2열 세로 배치로 자동 전환
- Board Position: 수평 중앙 → 상단 중앙으로 재배치
- 출력 해상도: 1920x1080 → 1080x1920 (비율 역전)
- Skin: `skin_layout_type` = `vertical_only`(1) 또는 `both`(0) 스킨만 호환

Frame Rate는 24/25/30/50/60fps 프리셋 또는 수동 입력(1~120fps 정수). 변경 시 렌더링 파이프라인 재초기화.

### 1.2 Live Pipeline 서브그룹 (ID 6~9)

| ID | 이름 | 타입 (shadcn/ui) | 기본값 | 설명 | 오버레이 영향 |
|:--:|------|-----------------|--------|------|-------------|
| 6 | NDI Output | Switch | OFF | NDI 네트워크 출력 | 오버레이 NDI 소스 노출 |
| 7 | RTMP Stream | Switch | OFF | RTMP 스트리밍 출력 | 오버레이 RTMP 스트림 |
| 8 | SRT Output | Switch | OFF | SRT 저지연 전송 출력 | 오버레이 SRT 전송 |
| 9 | DIRECT Output | Switch | OFF | SDI/HDMI 물리 직접 출력 | 물리 포트 영상 출력 |

**동작**: 네트워크 프로토콜 3종 + 물리 직접 연결 1종을 독립적으로 활성화/비활성화. 토글 ON 시 프로토콜별 설정 폼이 인라인 확장 표시. OFF 시 폼 숨김(입력값 보존).

#### 프로토콜별 설정 폼

**NDI Output (6)**:

| 설정 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| Source Name | Input (자동) | `{PC이름} (EBS - {Table Name})` | NDI 소스 식별명. 네트워크 수신 장비에서 자동 디스커버리 |
| Discovery | Select | 자동 탐색 | 자동 탐색(mDNS) / 수동 입력 |
| Manual IP:Port | Input | — | 수동 모드 시 대상 주소 |

**RTMP Stream (7)**:

| 설정 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| Server URL | Input | — (필수) | RTMP 서버 주소 (예: `rtmp://host/live`) |
| Stream Key | Input (마스킹) | — (필수) | 스트림 키. `•••` 마스킹, 눈 아이콘으로 원문 확인 |

> 연결 끊김 시 자동 재연결 3회(10초 간격). 실패 시 Info Bar 경고 + RTMP 토글 자동 OFF.

**SRT Output (8)**:

| 설정 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| Mode | Select | Caller | Caller / Listener / Rendezvous |
| IP | Input | — (필수) | 대상 IP (Caller/Rendezvous 모드) |
| Port | Input[type=number] | 9000 | 포트 번호 |
| Passphrase | Input (마스킹) | — (선택) | 암호화 키. 빈 값 시 암호화 비활성 |
| Latency | Input[type=number] | 120 | 전송 지연 버퍼 (ms). 낮을수록 저지연 |

**DIRECT Output (9)**:

| 설정 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| Interface | Select | SDI | SDI / HDMI |
| Output Device | Select (자동 탐색) | 자동 선택 | 시스템 연결 출력 장치. 미감지 시 "No device found" |
| Port | Select | 자동 선택 | 선택 장치의 출력 포트 |

> 해상도/Fps는 Video Size(2) + Frame Rate(4) 상속. 물리 포트 지원 해상도 불일치 시 Info Bar 경고.

### 1.3 Output Mode 서브그룹 (ID 10~13)

| ID | 이름 | 타입 (shadcn/ui) | 기본값 | 설명 | 오버레이 영향 |
|:--:|------|-----------------|--------|------|-------------|
| 10 | Fill & Key Output | Switch | OFF | Fill(영상)+Key(마스크) 듀얼 포트 동시 출력 | Decklink 듀얼 포트 분리 |
| 11 | Alpha Channel (Linear) | Switch (RadioGroup) | OFF | 원본 Alpha로 투명도. 12와 상호 배타 | Key 신호 방식 |
| 12 | Luma Key (Brightness) | Switch (RadioGroup) | OFF | 밝기 기반 Key 생성. 11과 상호 배타 | Key 신호 방식 |
| 13 | Invert Key | Switch | OFF | Key 신호 반전. 11 또는 12 선택 시만 활성 | Key 반전 |

**동작**: Fill & Key Output(10) 활성화 시 Decklink 물리 포트로 Fill + Key 분리 출력. Alpha(11)과 Luma(12)는 **상호 배타 RadioGroup** — 한쪽 선택 시 다른 쪽 자동 비활성. Invert Key(13)는 10이 ON이고 11 또는 12 중 하나가 선택된 상태에서만 활성화 가능.

> Chroma Key(SV-005)는 OBS에서 처리하므로 Drop.

---

## 2. 트리거

| 트리거 | 발동 주체 | 설명 |
|--------|:--------:|------|
| Settings 변경 | Admin 수동 | Admin이 Outputs 탭에서 설정 변경 |
| `ConfigChanged` | 시스템 자동 | BO DB 갱신 후 WebSocket 이벤트 발행 |
| CC 핸드 시작 | 게임 엔진 자동 | CONFIRM 분류 설정의 적용 시점 |

---

## 3. 경우의 수 매트릭스

| 조건 | Video Size 변경 | Live Pipeline 토글 | Fill & Key 변경 |
|------|:--------------:|:-----------------:|:--------------:|
| CC IDLE | 즉시 적용 | 즉시 적용 | 즉시 적용 |
| CC 핸드 진행 중 | 다음 핸드 (CONFIRM) | 즉시 적용 | 다음 핸드 (CONFIRM) |
| BO 서버 미실행 | 변경 불가 | 변경 불가 | 변경 불가 |
| NDI 소스명 중복 | — | 경고 표시 (차단 아님) | — |
| RTMP 연결 끊김 | — | 자동 재연결 3회 → 실패 시 OFF | — |
| DIRECT 장치 미감지 | — | "No device found" 표시 | — |
| GPU 미지원 해상도 | 경고 + 폴백 | — | — |

---

## 4. 유저 스토리

| # | As a | When | Then | Edge Case |
|:-:|------|------|------|-----------|
| O-1 | Admin | Video Size를 4K로 변경 | Preview + 캔버스 재초기화, 약 1초 블랙아웃 | GPU 미지원: 경고 표시 |
| O-2 | Admin | 9:16 Vertical 활성화 | 좌표계 전환, Player Layout 세로 자동 변환 | 비호환 스킨: 경고 |
| O-3 | Admin | NDI Output ON | NDI 소스 네트워크 노출, 설정 폼 확장 | 소스명 중복: 경고 |
| O-4 | Admin | RTMP URL + Key 입력 후 ON | RTMP 스트리밍 시작 | 연결 실패: 3회 재연결 → 자동 OFF |
| O-5 | Admin | Fill & Key + Alpha Channel 선택 | 듀얼 포트 출력, Luma 자동 비활성 | Decklink 미감지: 경고 |
| O-6 | Admin | SRT Caller 모드로 IP:Port 입력 후 ON | SRT 전송 시작 | 대상 미응답: 재연결 시도 |

---

## 비활성 조건

| 조건 | 영향 |
|------|------|
| Admin이 아닌 역할 | Outputs 탭 접근 불가 |
| CC LIVE + 핸드 진행 중 | Resolution, Output Mode: CONFIRM 분류 |
| BO 서버 미실행 | 읽기 전용 |
