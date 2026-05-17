---
title: EBS Security Posture — Operational Integrity vs PokerGFX DRM
owner: conductor
tier: internal
last-updated: 2026-05-17
version: 1.0.0
mirror: none
confluence-sync: none
derivative-of: ../../1. Product/Foundation.md (§A.4 Hole Card Visibility 4단 방어 + §C.2 RFID 자체 시스템)
related-docs:
  - ../../1. Product/Foundation.md (§A.4 + §C.2)
  - ../../1. Product/Command_Center.md (Ch.10 Hole Card Visibility)
  - ./Architecture_Generations.md (동시 cascade)
pokergfx-source: pokergfx-reverse-engineering-complete.md (line 1909-2134 — 4계층 DRM + 15 취약점)
---

# EBS Security Posture

> **본 문서의 위치**: EBS 의 보안 모델 = **Operational Integrity (운영 무결성)**. PokerGFX 의 4계층 DRM (제품 라이선스 보호) 과 **직교 관계**. 본 문서가 두 모델의 차이 명시화 + EBS 의 의도된 회피 정책 보존.
>
> **mirror: none** — Confluence 업로드 제외.

---

## 1. EBS 보안 모델 = Operational Integrity

### 1.1 정의

> **운영 무결성 (Operational Integrity)** = 시청자보다 운영자가 먼저 정보를 보지 못하게 + 라이브 방송 중 부정 차단.

### 1.2 EBS 4단 방어 (Foundation §A.4)

| Layer | 메커니즘 | 목적 |
|:-----:|----------|------|
| 1 | RBAC (Admin / Operator / Viewer) | 권한 분리 — 일반 운영자 = 홀카드 비공개 |
| 2 | 2-eyes principle (2 인 승인) | 시니어 view 활성 시 두 명 동시 승인 필요 |
| 3 | 60-min Timer | 권한 자동 만료 (갱신 시 재승인) |
| 4 | 물리 영역 차단 | CC 모니터 = 시청자/딜러 시야 차단 부스 |

### 1.3 본 모델의 핵심 가치

- **시청자 권리 보호**: 시청자가 미공개 정보를 운영자보다 늦게 알면 안 됨
- **도박 무결성**: 정보 유출 방지 = 정직한 베팅 보장
- **방송 신뢰**: 시청자가 운영자 부정 의심 시 방송 가치 0

---

## 2. PokerGFX DRM 모델 (참조용)

### 2.1 PokerGFX 4계층 DRM (line 1916-1929)

| Layer | 메커니즘 | 목적 |
|:-----:|----------|------|
| 1 | Email/Password 인증 | 기본 인증 |
| 2 | Offline Session 캐시 | 네트워크 장애 대비 |
| 3 | USB 동글 (KEYLOK) | 하드웨어 바인딩 |
| 4 | License 시스템 (Basic/Pro/Enterprise) | 기능 게이팅 |

### 2.2 PokerGFX 모델의 핵심 가치

- **제품 라이선스 보호**: 불법 복제 방지
- **수익 모델**: License tier 별 기능 제어
- **앱 무결성**: ConfuserEx + Dotfuscator 2중 난독화

---

## 3. 두 모델의 직교 관계 (Orthogonal)

### 3.1 비교 매트릭스

| 축 | PokerGFX 4계층 DRM | EBS 4단 방어 |
|----|-------------------|--------------|
| **보호 대상** | 제품 자체 | 운영 무결성 |
| **위협 모델** | 불법 복제 / 라이선스 위반 | 내부 부정 / 정보 유출 |
| **검증 시점** | 앱 시작 시 | 실시간 (홀카드 표시 시) |
| **우회 시 영향** | 불법 사용 (회사 손실) | 방송 사고 / 도박 무결성 (시청자 신뢰) |
| **운영 보안 | ❌ 미보장 | ✅ 핵심 |
| **외부 시스템 통합** | 별도 필요 | 자체 RFID + RBAC 통합 |

### 3.2 EBS 가 PokerGFX DRM 미차용 이유

1. **본 프로젝트 인텐트** (MEMORY.md): "기획서 완결 + 자체 RFID 시스템 구축" — 라이선스 비즈니스 아님
2. **운영 환경 차이**: PokerGFX = 다양한 카지노 배포 (라이선스 필요), EBS = WSOP LIVE 운영 (단일 운영자)
3. **보안 우선순위**: 운영 무결성 (도박 신뢰) > 제품 라이선스 (비즈니스)
4. **15 취약점 회피**: PokerGFX DRM = 15 보안 취약점 동반 (§4 참조). EBS 가 차용하면 같은 취약점 상속

### 3.3 두 모델 직교 시각화

```
   보안 모델 직교 시각화
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   
              제품 보호 축 (PokerGFX 강함)
                       ↑
                       │
                       │ PokerGFX
                       │ (DRM 4계층)
                       │
   ────────────────────┼──────────────────→ 운영 보호 축
                       │                    (EBS 강함)
                       │ EBS
                       │ (4단 방어)
                       │
   
   ▶ 두 축이 직교. 한 축이 다른 축을 대체 불가.
   ▶ 이상적 = 두 축 모두 강함. 그러나 EBS 는 운영 무결성 우선 선택.
```

---

## 4. PokerGFX 15 보안 취약점 회피

### 4.1 PokerGFX 의 15 취약점 (line 2118-2134)

| # | 영역 | 취약점 | 심각도 |
|---|------|--------|:------:|
| 1 | net_conn | 하드코딩 Password/Salt/IV | **CRITICAL** |
| 2 | net_conn | CBC without HMAC (Padding Oracle) | HIGH |
| 3 | net_conn | PBKDF1 사용 (deprecated) | HIGH |
| 4 | PokerGFX.Common | Zero IV (동일 평문 → 동일 암호문) | HIGH |
| 5 | PokerGFX.Common | 하드코딩 Base64 키 | HIGH |
| 6 | config | SKIN_PWD 바이너리 내장 | HIGH |
| 7 | boarssl | **InsecureCertValidator (MITM)** | **CRITICAL** |
| 8 | boarssl | TLS 1.0/1.1 지원 (POODLE, BEAST) | HIGH |
| 9 | boarssl | RC4, 3DES cipher suite (Sweet32) | MEDIUM |
| 10 | analytics | AWS 키 하드코딩 | **CRITICAL** |
| 11 | analytics | EncryptFile 미구현 (stub) | MEDIUM |
| 12 | RFID | **WiFi 비밀번호 평문 전송** | HIGH |
| 13 | RFID | 펌웨어 서명 미검증 | HIGH |
| 14 | UDP | 브로드캐스트 서버 위치 노출 | LOW |
| 15 | KEYLOK | LaunchAntiDebugger (우회 가능) | LOW |

### 4.2 EBS 의 회피 매트릭스

| PokerGFX 취약점 | EBS 회피 방법 |
|----------------|---------------|
| net_conn 하드코딩 키 (CRITICAL #1) | EBS = 자체 통신 (Foundation §B.3 REST + WS) — 별도 보안 spec |
| boarssl InsecureCertValidator (CRITICAL #7) | EBS = 자체 RFID (ST25R3911B + ESP32) — TLS 직접 사용 X |
| RFID WiFi 평문 (HIGH #12) | EBS = USB 직결 — WiFi 비사용 |
| RFID 펌웨어 미검증 (HIGH #13) | EBS = 자체 HW 펌웨어 → 자체 서명 가능 (NFR) |
| analytics AWS 하드코딩 (CRITICAL #10) | EBS = analytics 미정의 (또는 분리 시스템) |
| KEYLOK 동글 (LOW #15) | EBS = 동글 없음 — 라이선스 모델 아님 |

→ **EBS 자체 시스템 구축 = PokerGFX 보안 취약점 의도적 회피**.

### 4.3 본 프로젝트 인텐트와의 부합

본 프로젝트 인텐트 (MEMORY.md "EBS = 자체 RFID 시스템 구축"):

- **하드웨어**: ST25R3911B + ESP32 기반 자체 개발
- **소프트웨어**: Python/FastAPI + Flutter/Dart + Rive 자체 개발
- **완제품 도입 제안 절대 금지**

→ 보안 차원 정당화: PokerGFX 의 15 취약점 모두 회피 + Operational Integrity 우선 보장.

---

## 5. EBS 보안 SSOT 위치

| 보안 영역 | SSOT 위치 |
|----------|----------|
| **Hole Card Visibility 4단 방어** | Foundation.md §A.4 + Command_Center.md Ch.10 |
| **RBAC 3 등급** | Lobby.md 부록 E |
| **RFID 자체 시스템** | Foundation.md §C.2 |
| **인증 + 세션** | Backend `Auth_and_Session.md` |
| **본 doc** | 보안 모델 전체 + DRM 직교 + PokerGFX 회피 |

---

## 6. PokerGFX 정본 인용 위치

`C:/claude/ebs-archive-backup/07-archive/legacy-repos/ebs_reverse/docs/02-design/pokergfx-reverse-engineering-complete.md`:

| line | 내용 |
|------|------|
| 62 | "4계층 DRM" 요약 |
| 1909-1995 | 4계층 DRM 상세 + KEYLOK 47 fields |
| 1999-2011 | 3개 독립 AES 암호화 |
| 2013-2060 | ConfuserEx + Dotfuscator 2중 난독화 |
| 2118-2134 | **15 보안 취약점 목록** ★ |
| 1903-1905 | InsecureCertValidator (CRITICAL) |

---

## 7. 변경 이력

| 날짜 | 버전 | 변경 |
|------|------|------|
| 2026-05-17 | 1.0.0 | 본 doc 신규 작성 (Foundation §A.4 + §C.2 cascade) |
