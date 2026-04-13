# BS-03-06 Preferences — 테이블/진단/내보내기

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | Console PRD v9.7 §2.10 기반 — Table/Diagnostics/Export 3서브그룹, 9 컨트롤 |

---

## 개요

Preferences 섹션은 Settings의 여섯 번째 탭으로, **테이블 인증, 시스템 진단, 데이터 내보내기**를 관리한다. Settings > Preferences 메뉴 또는 단축키(Ctrl+,)로 접근. 480x400px 모달 오버레이. 변경 즉시 적용 (Table Name/Password만 Update 버튼 커밋).

> 참조: Console PRD v9.7 §2.10 Settings 다이얼로그

---

## 1. 컨트롤 목록

### 1.1 Table 서브그룹 (ID 1~3)

| ID | 이름 | 타입 (shadcn/ui) | 기본값 | 설명 | 오버레이 영향 |
|:--:|------|-----------------|--------|------|-------------|
| 1 | Table Name | Input + Button | "Table 1" | 테이블 식별 이름. AT 연결 시 이 이름으로 테이블 검색 | 없음 (AT 인증용) |
| 2 | Table Password | Input (마스킹) + Button | 빈 문자열 | AT 접속 비밀번호. 빈 값이면 비밀번호 없이 접속 허용 | 없음 (AT 인증용) |
| 3 | PASS / Reset | Button x2 | — | PASS: 비밀번호만 초기화 / Reset: 테이블명+비밀번호 전체 초기화 | 없음 |

**동작**:

- **Table Name**: Info Bar의 테이블 라벨(M-02t)에 표시되는 이름과 동기화. NDI 소스명에도 반영 (`{PC이름} (EBS - {Table Name})`).
- **Table Password**: AT에서 접속 시 Table Name + Password 조합으로 인증.
- **Update 버튼**: 명시적 커밋 패턴 — 실수 방지를 위해 별도 확인 단계. Table Name과 Password만 이 패턴 적용 (서버 인증 정보이므로).

> 저장 패턴: Preferences 기본 동작은 **즉시 적용**. Table Name(1)/Password(2)만 Update 버튼 커밋.

### 1.2 Diagnostics 서브그룹 (ID 4~6)

| ID | 이름 | 타입 (shadcn/ui) | 기본값 | 설명 | 오버레이 영향 |
|:--:|------|-----------------|--------|------|-------------|
| 6 | PC Specs | — (ReadOnly) | 시스템 자동 감지 | CPU/GPU/RAM/OS 정보 읽기 전용 표시 | 없음 |
| 4 | Table Diagnostics | Button | — | 안테나별 상태/신호 강도 별도 창 열기 | 없음 |
| 5 | System Log | Button | — | 실시간 이벤트/오류 로그 뷰어 별도 창 열기 | 없음 |

**동작**:

- **PC Specs**: 시스템 부팅 시 자동 수집. CPU 모델/코어 수, GPU 모델/VRAM, RAM 용량, OS 버전. 읽기 전용.
- **Table Diagnostics**: 별도 창 (600x400px, 비모달). RFID 안테나 10개(좌석별 UPCARD + Muck + Community)의 연결 상태, 신호 강도(dBm), 마지막 인식 시각.
- **System Log**: 별도 창 (800x500px, 비모달). WebSocket 메시지, RFID 이벤트, 오류 실시간 스트리밍. 로그 레벨 필터(INFO/WARN/ERROR). 자동 스크롤.

### 1.3 Export 서브그룹 (ID 10~10.2)

| ID | 이름 | 타입 (shadcn/ui) | 기본값 | 설명 | 오버레이 영향 |
|:--:|------|-----------------|--------|------|-------------|
| 10 | Hand History Folder | Input + Button (FolderPicker) | ./exports/ | JSON 핸드 히스토리 내보내기 폴더 | 없음 |
| 10.1 | Export Logs Folder | Input + Button (FolderPicker) | ./logs/ | 시스템/이벤트 로그 내보내기 폴더 | 없음 |
| 10.2 | API DB Export Folder | Input + Button (FolderPicker) | ./db_exports/ | API DB 추출 데이터 폴더 | 없음 |

**동작**:

- **Hand History**: 핸드별 JSON 파일 저장 (카드, 액션, 팟 분배 전체 기록).
- **Export Logs**: 시스템 로그를 일별/세션별로 저장.
- **API DB Export**: 서버 DB의 테이블 데이터(플레이어, 세션, 통계)를 JSON/CSV로 추출하는 경로 지정.
- 3개 FolderPicker는 각각 독립된 내보내기 경로. 즉시 적용.

---

## 2. 트리거

| 트리거 | 발동 주체 | 설명 |
|--------|:--------:|------|
| Settings 접근 | Admin 수동 | Preferences 탭 열기 |
| Update 버튼 클릭 | Admin 수동 | Table Name/Password 서버 반영 |
| 시스템 부팅 | 시스템 자동 | PC Specs 수집 |
| 핸드 완료 | 게임 엔진 자동 | Hand History 자동 저장 |

---

## 3. 경우의 수 매트릭스

| 조건 | Table 변경 | Diagnostics | Export 변경 |
|------|:--------:|:----------:|:----------:|
| CC IDLE | Update 버튼으로 즉시 적용 | 읽기 전용 / 별도 창 열기 | 즉시 적용 |
| CC 핸드 진행 중 | Update 버튼으로 즉시 적용 | 동일 | 즉시 적용 |
| BO 서버 미실행 | 변경 불가 | PC Specs만 표시 | 로컬 경로만 변경 가능 |
| AT 연결 중 Table Name 변경 | 기존 AT 연결 유지, 재접속 시 새 이름 사용 | — | — |
| 내보내기 폴더 미존재 | — | — | 자동 생성 또는 "폴더를 생성할 수 없습니다" 경고 |

---

## 4. 유저 스토리

| # | As a | When | Then | Edge Case |
|:-:|------|------|------|-----------|
| P-1 | Admin | Table Name을 "Final Table"로 변경 후 [Update] | Info Bar 라벨 갱신, NDI 소스명 갱신 | AT 연결 중: 재접속 시 반영 |
| P-2 | Admin | Table Password 설정 후 [Update] | AT 접속 시 비밀번호 요구 | 빈 값: 비밀번호 없이 접속 |
| P-3 | Admin | [PASS] 클릭 | 비밀번호만 초기화 (빈 문자열) | — |
| P-4 | Admin | [Reset] 클릭 | 테이블명 "Table 1" + 비밀번호 초기화 | — |
| P-5 | Admin | [Table Diagnostics] 클릭 | 안테나 상태 창 열림 (600x400px) | 안테나 미연결: "Disconnected" 상태 |
| P-6 | Admin | [System Log] 클릭 | 로그 뷰어 창 열림 (800x500px) | 이벤트 없음: 빈 로그 |
| P-7 | Admin | Hand History Folder 경로 변경 | 다음 핸드부터 새 경로에 저장 | 경로 미존재: 자동 생성 또는 경고 |

---

## 비활성 조건

| 조건 | 영향 |
|------|------|
| Admin이 아닌 역할 | Preferences 탭 접근 불가 |
| BO 서버 미실행 | Table 변경 불가, PC Specs만 표시 |
