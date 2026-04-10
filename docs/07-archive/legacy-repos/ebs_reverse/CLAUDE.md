# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

EBS(Event Broadcasting System) 개발 프로젝트. PokerGFX Server v3.2.985.0 역공학 분석을 기반으로 라이브 포커 방송용 실시간 그래픽 오버레이 시스템을 독립 구현한다.

**타겟**: Windows .NET Framework 4.x WinForms 애플리케이션 (ConfuserEx + Dotfuscator 2중 난독화)

## Google Docs 동기화

| 문서 | Doc ID | Drive 표시 이름 | 버전 | 동기화 |
|------|--------|----------------|------|--------|
| **EBS PRD** | `1PLJuD2BbT4Jp1p6smue9ezLAfbkOSTrfVxCOXTsrau4` | PRD-0001: EBS 기초 기획서 | v29.2.0 | 2026-02-24 |
| **Lookup Tables** | `1L-QX5t-gcpN0PqM9dTkizLGVi99p5YfeYWVa0SLjwmA` | — | v1.0.0 | 2026-02-23 |
| **Glossary** | `1cAjplU6dCldLAVIRr2MLGE3_LBvtdQI8XgkWS8xsiYM` | — | v1.0.0 | 2026-02-23 |
| **Reverse Engineering Complete** | `1Y4YPRicgItRqxdOe4X2KJyW-D8TP3Gd9dE1uDTvSBHU` | PokerGFX Reverse Engineering Complete Analysis | v1.0.0 | 2026-02-24 |

로컬 PRD (`docs/01-plan/pokergfx-prd-v2.md` v28.0.0)
로컬 설계 (`docs/02-design/pokergfx-lookup-tables.md` v1.0.0)
로컬 용어집 (`docs/01-plan/pokergfx-glossary.md` v1.0.0)

**Drive 이름 변경 도구**: `cd /c/claude && python ebs/rename_ebs_docs.py` (PRD-0001/PRD-0002 표시 이름 일괄 적용)

## Repository Structure

```
decompiled/          # 역컴파일된 C# 소스 (2,887 파일, 8개 모듈)
  vpt_server/        # 메인 서버 (2,402 파일) - 3세대 아키텍처 공존
  net_conn/          # 네트워크 프로토콜 (168 파일, 99개 외부 명령 + ~31개 내부)
  hand_eval/         # 핸드 평가 엔진 (52 파일, Bitmask + Monte Carlo)
  mmr/               # GPU 렌더링 (80 파일, DirectX 11)
  PokerGFX.Common/   # 공통 라이브러리 (50 파일)
  RFIDv2/            # RFID 리더 드라이버 (26 파일, SkyeTek)
  boarssl/           # 자체 TLS 구현 (102 파일)
  analytics/         # 텔레메트리 (7 파일, S3)

extracted/           # Costura.Fody 임베디드 DLL 추출본 (80개 DLL, .gitignore 대상)
named/               # 리소스 자동 명명 결과 (.gitignore 대상)

scripts/             # 역공학 도구 (30개 Python 스크립트)
  il_decompiler.py           # 커스텀 IL→C# 디컴파일러 (200+ opcode)
  confuserex_analyzer.py     # ConfuserEx 난독화 분석기
  extract_costura_v3.py      # Costura.Fody 언패커
  extract_reflection_data.py # .NET Reflection 메타데이터 추출
  rfid_gui.py                # RFID 모니터 GUI (Tkinter)
  rfid_reader.py             # SkyeTek RFID HID 드라이버
  build_all.py               # PyInstaller 빌드 자동화
  recapture_mockups.py       # HTML 목업 → PNG 일괄 재캡처
  trim_mockup_pngs.py        # PNG 여백 자동 트리밍
  annotate_overlay.py        # 오버레이 이미지 주석 처리
  annotate_anatomy.py        # JSON 좌표 기반 오버레이 해부도 주석기
  extract_overlay_bbox.py    # OpenCV 기반 오버레이 요소 자동 검출
  labelme2anatomy.py         # LabelMe JSON → overlay-anatomy-coords.json 변환기
  dist/                      # 빌드된 실행 파일

docs/
  01-plan/data/              # 오버레이 좌표 JSON
    overlay-anatomy-coords.json  # 11개 UI 요소 bounding box (OpenCV+Vision 보정)

docs/
  01-plan/           # EBS PRD (pokergfx-prd-v2.md v28.0.0)
    pokergfx-ui-overview.md  # UI 화면 개요 (기능별 요약)
    pokergfx-ui-screens.md   # 화면별 상세 명세
    mockups/         # 27개 HTML 와이어프레임 목업 (BnW)
    images/prd/      # PNG 다이어그램/목업 캡처
  02-design/         # 통합 역공학 문서 + 기술 설계
  04-report/         # changelog
  archive/           # 이전 분석/설계/보고서 아카이브
```

## Build & Run Commands

```bash
# RFID 모니터 전체 빌드 (GUI + 진단 도구)
python scripts/build_all.py

# 개별 PyInstaller 빌드
python -m PyInstaller scripts/rfid_gui.py --onefile --windowed
python -m PyInstaller scripts/rfid_diagnostic.py --onefile --console

# RFID 모니터 실행 (데모 모드 - 하드웨어 불필요)
scripts/dist/PokerGFX_RFID_Monitor.exe --demo

# 역공학 스크립트 실행 예시
python scripts/il_decompiler.py <target.dll>
python scripts/confuserex_analyzer.py <target.exe>
python scripts/extract_costura_v3.py <target.exe>
```

**Python 의존성** (requirements.txt 없음, 직접 설치 필요):
```bash
pip install pefile hidapi PyInstaller
# tkinter는 Python 표준 배포판에 포함 (별도 설치 불필요)
```

## Key Architecture Insights

### PokerGFX 3세대 아키텍처 공존

vpt_server 내 3세대가 혼재. 분석/구현 시 해당 코드가 어느 세대인지 구분 필요:

| Phase | 패턴 | 식별 기준 |
|-------|------|----------|
| Phase 1 | God Class | main_form (329 methods, 7,912 lines) |
| Phase 2 | Service Interface | GameTypes/ 디렉토리 (26 파일), facade 패턴 |
| Phase 3 | DDD + CQRS | Features/ 디렉토리 (58 파일), FluentValidation |

### 프로토콜 스택

- Discovery: UDP Multicast :15000
- Control: TCP :8888, AES-256 CBC 암호화, Length-Prefixed Binary 직렬화
- 99개 명령어 10개 카테고리 (연결, 게임, 플레이어, 카드, 디스플레이, 미디어, 베팅, 데이터, RFID, Slave)

### 난독화 구조

- ConfuserEx: XOR key `0x6969696969696968`, 메서드 바디 암호화
- Dotfuscator: 문자열/네이밍 난독화
- Costura.Fody: 60개 DLL 실행 파일 내 임베딩

### 보안 취약점 (분석 완료)

- InsecureCertValidator: MITM 공격 가능
- AWS 자격증명 하드코딩 (analytics 모듈)
- AES-256 Zero IV 재사용

## Working with Decompiled Code

`decompiled/` 내 코드는 IL 디컴파일 결과물로, 완전한 C# 소스가 아님:
- 변수명이 IL 레지스터명(V_0, V_1)인 경우 Phase 1 God Class 코드
- PDB 심볼이 있는 모듈은 원본 변수명/소스 경로 복원됨
- 난독화 잔재(`\u0001`, `\u0002` 등 유니코드 식별자)가 남아있을 수 있음
- 커버리지 88% (839/2,602 유의미 타입) - 미해석 영역은 주로 UI 폼 코드

## Document Hierarchy

핵심 문서 읽기 순서:
1. `docs/01-plan/pokergfx-prd-v2.md` - EBS PRD v28.0.0 (유일한 기획 문서, WHAT/WHY)
2. `docs/02-design/features/pokergfx.design.md` - 기술 설계 v4.0.0 (유일한 기술 설계 문서, HOW)
3. `docs/02-design/pokergfx-reverse-engineering-complete.md` - 통합 역공학 분석 (4,287줄)
4. `docs/archive/analysis/architecture_overview.md` - 시스템 아키텍처 상세
5. `docs/archive/pokergfx-development-prd-v1.md` - Master PRD v1 (아카이브, 참고용)

## Mockup Capture Rules

HTML 목업(`docs/01-plan/mockups/`)을 PNG로 캡처할 때 반드시 준수:

1. **불필요한 공백 금지** — 캡처 영역을 콘텐츠 표시 영역에 딱 맞출 것
2. **HTML body 패딩**: `padding: 0; margin: 0` — `/mockup` 커맨드 CSS 기준 준수
3. **Chrome headless 캡처 명령**:
   ```bash
   chrome --headless --disable-gpu --hide-scrollbars \
     --screenshot="<output>.png" --window-size=<W>,<H> "<html_file>"
   ```
4. **window-size 산정**: 콘텐츠 우측 끝 + body padding + 40px 여유 (width), 전체 콘텐츠 높이 + 40px 여유 (height)
5. **캡처 후 반드시 시각 검증** — Read 도구로 PNG를 열어 스크롤바, 잘림, 과도한 공백 확인
6. **PNG ↔ HTML ↔ PRD 본문 3자 정합성** — 캡처 후 PRD의 alt text/캡션과 다이어그램 내용이 일치하는지 확인

## Overlay Anatomy Coordinates Workflow

오버레이 해부도 좌표(`docs/01-plan/data/overlay-anatomy-coords.json`)를 갱신하는 방법:

### Option A — OpenCV 자동 검출 (빠름, 근사값)
```bash
pip install opencv-python
python scripts/extract_overlay_bbox.py --output docs/01-plan/data/auto_detected.json
# 결과 검토 후 anatomy JSON에 반영
```

### Option B — LabelMe 수동 어노테이션 (pixel-perfect)
```bash
pip install labelme
labelme "docs/01-plan/images/web/wsop-2025-paradise-overlay.png"
# GUI에서 11개 요소 드래그 (라벨명: player_panel, hole_cards, action_badge,
# equity_bar, community_cards, top_bar, event_badge, bottom_strip,
# pot_counter, field_stage, sponsor_logo)
python scripts/labelme2anatomy.py wsop-2025-paradise-overlay.json
```

### Option C — coord_picker.html 글로벌 도구 (범용)

1. 브라우저에서 `scripts/coord_picker.html` 열기
2. [파일 열기]로 오버레이 PNG 로드
3. **자동 분석**: [자동 분석] 클릭 → N개 요소 감지 → [하이라이트 ON]으로 확인
   **수동 설정**: 요소 수 입력 → [N개 생성]
   **프리셋 로드**: [설정 불러오기] → `wsop-preset.coord-picker-config.json`
4. Canvas에서 각 요소 드래그 어노테이션
5. [JSON 내보내기] → `overlay-anatomy-coords.json` 다운로드
   [설정 내보내기] → `coord-picker-config.json` 다운로드

### 주석 이미지 재생성
```bash
python scripts/annotate_anatomy.py
# 출력: docs/01-plan/images/prd/overlay-anatomy.png (1920x1200, 11개 박스 + 범례)
```

## Project Status

- Phase 1-3 역공학 분석 완료 (88% 커버리지, 839/2,602 유의미 타입)
- EBS PRD v28.0.0 완성 (기획-기술 분리 완료, Master PRD 아카이브)
- Design Doc v4.0.0 완성 (기획 콘텐츠 제거, PRD 이관 콘텐츠 수신)
- RFID 모니터 도구 구현 완료
- 오버레이 해부도 좌표 OpenCV+Vision 보정 완료 (2026-02-23)
- 다음: 실제 구현 시작
