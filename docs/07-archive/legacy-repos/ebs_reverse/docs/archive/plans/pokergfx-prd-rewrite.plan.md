# Work Plan: PokerGFX PRD 순수 제품 사양서 전면 재작성

**Plan ID**: pokergfx-prd-rewrite
**Created**: 2026-02-13
**Status**: READY
**Target File**: `C:\claude\ebs_reverse\docs\01-plan\pokergfx-rfid-vpt-prd.md`
**Estimated Output**: 1000-1200줄

---

## 1. Context

### 1.1 Original Request

기존 PRD(`pokergfx-rfid-vpt-prd.md`, 1249줄)는 역공학 분석 보고서 형태로 작성되어 있다. "분석 커버리지", "디컴파일 도구", "ConfuserEx 난독화 분석", "Reflection 추출" 등의 내용이 포함되어 제품 사양서로 부적합하다. 이를 순수한 제품 요구사항 문서로 전면 재작성한다.

### 1.2 Interview Summary

사용자가 매우 구체적인 명세를 제공함:
- 제거 대상 8개 카테고리 명시
- 보존 대상 9개 카테고리 명시
- 16개 섹션 + 2개 부록 구조 지정
- 위험 요소 2개 식별

### 1.3 Research Findings

**원본 문서 분석 결과:**

| 항목 | 현재 상태 |
|------|----------|
| 총 줄 수 | 1249줄 |
| 섹션 수 | 14개 + 3개 부록 |
| 역공학 표현 | 약 30+ 곳에 산재 |
| 제거 대상 섹션 | 섹션 13 (분석 범위), 섹션 14 (재구현 가이드), 부록 C (분석 문서 목록) |
| 보안 취약점 표 | 섹션 6.6 (12행) - 보안 요구사항으로 전환 필요 |
| 난독화 상세 | 섹션 6.3 (15줄) - 코드 보호 정책으로 전환 필요 |
| Reflection 표현 | 4.1.1, 4.1.3, 4.1.6, 4.1.7, 4.2 헤더에 존재 |
| 보존 필수 기술 데이터 | enum 값, 프로토콜 명세, bitmask, AES 파라미터, 서비스 매핑 등 |

---

## 2. Work Objectives

### 2.1 Core Objective

역공학 분석 보고서를 순수 제품 사양서(Product Specification)로 전환. 모든 기술 데이터를 보존하면서 분석 관점의 서술을 제품 관점으로 변환.

### 2.2 Deliverables

| # | Deliverable | Description |
|---|------------|-------------|
| 1 | `pokergfx-rfid-vpt-prd.md` 전면 교체 | 1000-1200줄의 순수 제품 사양서 |

### 2.3 Definition of Done

- [ ] 역공학 관련 표현 0건 (grep 검증)
- [ ] 기술 데이터 무결성 100% (체크리스트 기반)
- [ ] 16개 섹션 + 2개 부록 구조 완성
- [ ] 1000-1200줄 범위 내

---

## 3. Guardrails

### 3.1 MUST HAVE

| # | Requirement |
|---|------------|
| 1 | 22개 포커 게임 변형 (game enum, ID 0-21) 전체 보존 |
| 2 | 113+ 프로토콜 명령어 카테고리별 표 보존 |
| 3 | 62+ enum 타입 카탈로그 보존 (모든 정수 값 포함) |
| 4 | 282-field config_type 도메인별 매핑 보존 |
| 5 | Bitmask 카드 표현 (64비트 레이아웃, 13비트 연속 배치, suit offset) |
| 6 | GPU 렌더링 파이프라인 (5-thread, dual canvas, DirectX 11) |
| 7 | RFID 듀얼 트랜스포트 아키텍처 (SkyeTek + v2) |
| 8 | 4-Layer DRM 구조 (Login, Offline, Dongle, Remote) |
| 9 | 7-Application Ecosystem 표 |
| 10 | 모든 Service Interface/Implementation 매핑 (Phase 2, 3) |
| 11 | AES 암호화 파라미터 (3개 독립 시스템) |
| 12 | Master-Slave 아키텍처 다이어그램 |
| 13 | 스레드 모델 (15-25개 동시, 동기화 메커니즘) |
| 14 | 외부 서비스 통합 (API endpoints, SDK 목록) |
| 15 | UI 시스템 (43+ Forms, 탭 구조) |
| 16 | 텔레메트리 Store-and-Forward 아키텍처 |
| 17 | 하드코딩된 보안 파라미터 (AES 키/Salt/IV, SKIN_PWD 등) |

### 3.2 MUST NOT HAVE

| # | Prohibition | Grep Pattern |
|---|------------|--------------|
| 1 | "역공학" / "역설계" 표현 | `역공학\|역설계\|reverse.engineer` |
| 2 | "Reflection 추출" 표현 | `Reflection.*추출\|추출.*Reflection` |
| 3 | 분석 커버리지 퍼센티지 | `88%\|95%\|coverage` |
| 4 | 커스텀 분석 도구명 | `il_decompiler\|confuserex_analyzer\|confuserex_deobfuscator\|ReflectionAnalyzer\|extract_reflection` |
| 5 | 분석 문서 목록/참조 | 부록 C 전체 |
| 6 | 재구현 가이드 | 섹션 14 전체 |
| 7 | 보안 취약점 등급 표 | `CRITICAL\|HIGH\|MEDIUM\|LOW` 등급 + "취약점" 조합 |
| 8 | ConfuserEx 상세 분석 | IL preamble, XOR 키 (`7595413275715305912`), 탐지 수 |
| 9 | "Based on: 역공학 분석" 출처 표기 | `Based on.*역공학\|기반으로 작성` |
| 10 | "디컴파일" / "decompile" 표현 | `디컴파일\|decompil` |
| 11 | ".cs 파일" 소스 참조 | `2,887개.*\.cs\|\.cs 파일` |
| 12 | "복원" (코드 복원 맥락) | `복원 불가\|부분 복원\|80% 복원` |

---

## 4. Document Structure (16 Sections + 2 Appendices)

새 문서의 목표 구조:

| # | Section | Source Mapping | Est. Lines | Notes |
|---|---------|---------------|:----------:|-------|
| 1 | 제품 개요 | 기존 1 (개편) | 60 | "Based on" 제거, 제품 정의로 |
| 2 | 시스템 아키텍처 | 기존 2 (유지) | 80 | 다이어그램 보존 |
| 3 | 포커 게임 엔진 | 기존 3.1 (유지) | 70 | 22개 변형, 앤티, GameTypeData |
| 4 | 핸드 평가 엔진 | 기존 3.2 (유지) | 60 | Bitmask, lookup, 알고리즘 |
| 5 | GPU 렌더링 시스템 | 기존 3.3 (유지) | 90 | 5-thread, dual canvas, 코덱 |
| 6 | 그래픽 요소 시스템 | 기존 3.4 (유지) | 60 | Element hierarchy, animation |
| 7 | Skin 시스템 | 기존 3.5 (유지) | 30 | 파일 포맷, 에디터 |
| 8 | RFID 카드 리더 | 기존 3.6 (유지) | 55 | 듀얼 트랜스포트, 프로토콜 |
| 9 | 네트워크 프로토콜 | 기존 3.7 (유지) | 90 | 113+ 명령어, AES, Master-Slave |
| 10 | 외부 통합 | 기존 3.8-3.11 + 8 (통합) | 70 | ATEM, Twitch, LiveApi, 텔레메트리 |
| 11 | 데이터 모델 | 기존 4 (개편) | 80 | "Reflection 추출" 표현 제거 |
| 12 | Service Architecture | 기존 5 (유지) | 60 | Interface/Implementation 매핑 |
| 13 | 보안 체계 | 기존 6 (대폭 개편) | 70 | 취약점 평가 -> 보안 요구사항 전환 |
| 14 | 스레드 모델 | 기존 9 (유지) | 40 | 스레드 맵, 동기화 |
| 15 | UI 시스템 | 기존 10 (유지) | 35 | 43+ Forms, 탭 구조 |
| 16 | 빌드/배포 및 운영 | 기존 11-12 (통합) | 35 | 로깅, 버전 관리, 빌드 |
| A | 부록 A: 소스 디렉토리 구조 | 기존 부록 A (유지) | 35 | PDB 기반 -> "프로젝트 구조"로 |
| B | 부록 B: 내장 DLL 목록 | 기존 부록 B (유지) | 15 | 60개 DLL |
| | **합계** | | **~1035** | 목표 범위 내 |

---

## 5. Task Flow

### 5.1 Dependency Graph

```
Task 1: 원본 데이터 추출 및 정량 체크리스트 생성
    |
    v
Task 2: 문서 전면 재작성 (16개 섹션 + 2개 부록)
    |
    v
Task 3: 무결성 검증 (제거/보존 체크리스트)
```

### 5.2 Detailed Tasks

---

#### Task 1: 원본 데이터 추출 및 정량 체크리스트 생성

**Agent**: explore (haiku)
**Estimated Time**: 5분
**Input**: `C:\claude\ebs_reverse\docs\01-plan\pokergfx-rfid-vpt-prd.md`

**목적**: 재작성 시 데이터 누락을 방지하기 위한 정량적 기준선 설정

**Acceptance Criteria**:
- [ ] 보존 대상 기술 데이터 항목 수 집계 완료
- [ ] 각 enum의 값 개수 확인 (game: 22, AnimationState: 16, lang_enum: 130, etc.)
- [ ] 프로토콜 명령어 카테고리별 수 확인 (113+)
- [ ] config_type 도메인별 필드 확인 (282개)
- [ ] Service Interface/Implementation 매핑 수 확인 (10+11+7+6)

**정량 체크리스트** (Task 3에서 검증용):

| 데이터 항목 | 원본 수치 | 검증 방법 |
|------------|----------|----------|
| game enum 값 | 22개 (0-21) | 표 행 수 카운트 |
| AnimationState enum | 16개 (0-15) | 값 나열 카운트 |
| lang_enum 항목 | 130개 | 명시된 수치 보존 |
| config_type 필드 | 282개 | 명시된 수치 보존 |
| hand_class enum | 10개 (0-9) | 표 행 수 카운트 |
| Enum 카탈로그 타입 수 | 62+ | 표 행 수 카운트 |
| 프로토콜 명령어 수 | 113+ | 명시된 수치 보존 |
| RFID 텍스트 명령 | 22개 | 표 행 수 카운트 |
| GameTypeData 필드 | 78+ | 명시된 수치 보존 |
| Service Interface (Phase 2) | 10개 | 표 행 수 |
| Service Implementation (Phase 2) | 11개 | 표 행 수 |
| Root Services | 6개 | 표 행 수 |
| UI Forms | 43+ | 명시된 수치 |
| 스레드 수 | 15-25 | 표 행 수 |
| 동기화 메커니즘 | 6종 | 표 행 수 |
| 앤티 유형 | 7종 | 표 행 수 |
| 그래픽 레이어 | 4단계 | 표 행 수 |
| GPU 코덱 설정 | 4 GPU 벤더 | 표 행 수 |
| 출력 모드 | 5종 | 표 행 수 |
| 애니메이션 클래스 | 11개 | 표 행 수 |
| 7-App Ecosystem | 7개 | 표 행 수 |
| 하드코딩 Credentials | 8개 | 표 행 수 |
| AES 시스템 | 3개 독립 | 표 행 수 |
| 4-Layer DRM | 4단계 | 구조 보존 |
| 외부 API Endpoints | 9개 | 표 행 수 |
| Third-Party SDK | 10개 | 표 행 수 |
| 입력 디바이스 타입 | 4종 | 표 행 수 |
| 내장 DLL | 60개 | 명시된 수치 |

---

#### Task 2: 문서 전면 재작성

**Agent**: executor-high (opus)
**Estimated Time**: 30분
**Input**: 원본 PRD + Task 1 체크리스트
**Output**: `C:\claude\ebs_reverse\docs\01-plan\pokergfx-rfid-vpt-prd.md` 전면 교체

**작성 원칙**:

1. **서술 관점 전환**:
   - "Reflection 분석으로 추출된 값" -> 값 자체만 기재
   - "코드베이스는 시간 경과에 따른 3단계 아키텍처 진화를 보여준다" -> "시스템은 3세대 아키텍처로 구성된다"
   - "디컴파일 결과 확인" -> 해당 표현 삭제
   - "PDB에서 확인" -> "프로젝트 구조"

2. **헤더 메타데이터 변경**:
   ```
   BEFORE:
   Based on: 역공학 분석 95% coverage (88% static + 7% Reflection)
   Source: 9개 분석 문서, 11개 JSON 데이터, 2,887개 디컴파일 .cs 파일

   AFTER:
   (이 두 줄 완전 삭제. Version, Date만 유지)
   ```

3. **섹션 13 (분석 범위 및 한계) 제거**:
   - 13.1 Coverage 요약 -> 삭제
   - 13.2 미해결 영역 -> "알려진 제한사항"으로 전환 (기술적 제한만, 분석 원인 제거)
   - 13.3 커스텀 도구 체인 -> 완전 삭제

4. **섹션 14 (재구현 가이드) 완전 제거**:
   - 14.1-14.3 전체 삭제

5. **섹션 6 (보안 체계) 개편**:
   - 6.1-6.5: 유지 (4-Layer DRM, 3 AES Systems, WCF 통신)
   - 6.3 난독화 -> "코드 보호 정책"으로 전환 (ConfuserEx/Dotfuscator를 보호 도구로만 언급, XOR 키/탐지 수 제거)
   - 6.6 보안 취약점 요약 -> "보안 요구사항"으로 전환

   **6.6 전환 예시**:
   ```
   BEFORE:
   | CRITICAL | AWS 키 하드코딩 | analytics.dll |
   | HIGH | PBKDF1 사용 (deprecated) | net_conn.dll |

   AFTER:
   보안 요구사항:
   - 클라우드 서비스 인증 정보는 외부 Key Management를 통해 관리
   - 키 유도 함수는 PBKDF2 이상의 표준 사용
   (등급 표기 없이, 보안 정책 방향으로 서술)
   ```

6. **부록 C (분석 문서 목록) 완전 제거**

7. **부록 A 전환**:
   - "소스 디렉토리 구조 (PDB 기반)" -> "프로젝트 소스 구조"
   - "(PDB에서 확인)" 표현 제거

8. **Enum 서술 전환**:
   ```
   BEFORE: #### 4.1.1 game enum (22개 변형, Reflection 추출 정수 값)
   AFTER:  #### 11.1.1 game enum (22개 변형)

   BEFORE: #### 4.1.3 AnimationState enum (16 states, Reflection 추출)
   AFTER:  #### 11.1.3 AnimationState enum (16 states)

   BEFORE: #### 4.1.6 lang_enum (130개 UI 표시 라벨, Reflection 추출)
   AFTER:  #### 11.1.6 lang_enum (130개 UI 표시 라벨)
   ```

9. **푸터 전환**:
   ```
   BEFORE:
   *이 PRD는 PokerGFX RFID-VPT Server v3.2.985.0의 역공학 분석 95% coverage를
   기반으로 작성되었습니다.*

   AFTER:
   (완전 삭제 또는 "이 문서는 PokerGFX RFID-VPT Server v3.2.985.0의 제품 사양을
   기술합니다."로 대체)
   ```

**Acceptance Criteria**:
- [ ] 16개 섹션 + 2개 부록 구조 완성
- [ ] 1000-1200줄 범위 내
- [ ] 모든 기술 데이터 표/다이어그램 보존
- [ ] 역공학 관련 표현 0건

---

#### Task 3: 무결성 검증

**Agent**: architect (opus)
**Estimated Time**: 10분
**Input**: 재작성된 PRD + Task 1 체크리스트
**blockedBy**: Task 2

**검증 항목**:

**A. 제거 검증 (MUST NOT 체크)**:
- [ ] `grep -c "역공학\|역설계" pokergfx-rfid-vpt-prd.md` == 0
- [ ] `grep -c "Reflection.*추출\|추출.*Reflection"` == 0
- [ ] `grep -c "88%\|95%.*coverage\|coverage.*95%"` == 0
- [ ] `grep -c "il_decompiler\|confuserex_analyzer\|confuserex_deobfuscator"` == 0
- [ ] `grep -c "디컴파일\|decompil"` == 0
- [ ] `grep -c "복원 불가\|부분 복원"` == 0
- [ ] 섹션 "분석 범위" 없음
- [ ] 섹션 "재구현 가이드" 없음
- [ ] 부록 C "분석 문서 목록" 없음
- [ ] 보안 취약점 등급 표 (CRITICAL/HIGH/MEDIUM/LOW + "취약점" 조합) 없음

**B. 보존 검증 (MUST HAVE 체크)**:
- [ ] game enum 22개 값 (holdem=0 ~ razz=21) 전체 존재
- [ ] AnimationState 16개 값 (FadeIn=0 ~ Waiting=15) 전체 존재
- [ ] hand_class 10개 값 (High Card=0 ~ Royal Flush=9) 전체 존재
- [ ] Bitmask 카드 표현 (64비트 레이아웃, CLUB_OFFSET=0, DIAMOND_OFFSET=13, HEART_OFFSET=26, SPADE_OFFSET=39)
- [ ] AES 파라미터 3개 시스템 모두 존재
  - System 1: Password, Salt, IV 값
  - System 2: Base64 키 값
  - System 3: SKIN_PWD 값
- [ ] 프로토콜 명령어 "113+" 수치 보존
- [ ] config_type "282" 필드 수치 보존
- [ ] 7-Application Ecosystem 7개 앱 모두 존재
- [ ] 4-Layer DRM 4단계 모두 존재
- [ ] Service Interface 매핑 테이블 (Phase 2: 10개, Root: 6개)
- [ ] 5-Thread Worker Architecture 5개 스레드 모두 존재
- [ ] RFID 22개 텍스트 명령 프로토콜 존재
- [ ] Master-Slave 아키텍처 다이어그램 존재
- [ ] 프로토콜 스택 다이어그램 (4 Layer) 존재
- [ ] GPU 벤더별 코덱 설정 (4 벤더) 존재
- [ ] 하드코딩 Credentials 값 8개 존재
- [ ] 외부 API Endpoints 9개 존재
- [ ] 내장 DLL 목록 (주요 11개 + 전체 60개 수치)
- [ ] ConfigurationPreset 99+ 필드 설명 존재
- [ ] CSV Wire Format 규칙 존재
- [ ] GameTypeData 78+ 필드 5개 카테고리 존재

**C. 구조 검증**:
- [ ] 총 줄 수 1000-1200 범위 내
- [ ] 섹션 번호 1-16 연속
- [ ] 부록 A, B 존재
- [ ] 부록 C 없음

**Acceptance Criteria**:
- [ ] 제거 검증 10/10 통과
- [ ] 보존 검증 21/21 통과
- [ ] 구조 검증 4/4 통과
- [ ] 불일치 발견 시 Task 2로 회귀하여 수정

---

## 6. Commit Strategy

| Commit | Content | Message |
|:------:|---------|---------|
| 1 | PRD 전면 재작성 | `docs(prd): PokerGFX PRD 순수 제품 사양서로 전면 재작성` |

**Commit Message Body**:
```
- 역공학 분석 관련 모든 표현/섹션 제거
- 16개 섹션 + 2개 부록 구조로 재구성
- 보안 취약점 평가 -> 보안 요구사항으로 전환
- ConfuserEx 상세 분석 -> 코드 보호 정책으로 전환
- 모든 기술 데이터 (enum, 프로토콜, bitmask, AES) 무결성 보존
```

---

## 7. Success Criteria

| # | Criterion | Verification |
|---|-----------|-------------|
| 1 | 역공학 표현 0건 | grep 자동 검증 |
| 2 | 기술 데이터 100% 보존 | 정량 체크리스트 대조 |
| 3 | 문서 구조 완결성 | 16섹션 + 2부록 확인 |
| 4 | 줄 수 범위 | wc -l: 1000-1200 |
| 5 | 제품 사양서 톤 | "분석했다" -> "사양이다" 전환 완료 |

---

## 8. Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|-----------|
| 기술 데이터 누락 | HIGH | Task 1에서 27개 항목 정량 체크리스트 생성, Task 3에서 전수 검증 |
| 구조 변경 일관성 | MEDIUM | 섹션 매핑 테이블(Section 4)로 원본-신규 추적성 확보 |
| 보안 섹션 전환 시 데이터 손실 | MEDIUM | AES 파라미터/키 값은 반드시 보존, 등급 표기만 제거 |
| 줄 수 초과/미달 | LOW | 예상 1035줄로 범위 내, +-100줄 여유 |
