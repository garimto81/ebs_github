# PokerGFX System Architecture Reference

> **Version**: 9.1.0
> **Date**: 2026-02-16
> **Status**: reference
> **문서 유형**: 시스템 아키텍처 참조 문서
> **대상 독자**: 기획자, 프로덕트 매니저, 개발 리드, 이해관계자
> **벤치마크**: PokerGFX Server v3.2.985.0

> **범위 고지**: 이 문서는 PokerGFX 시스템 아키텍처의 참조 자료다. 기능 범위와 버전 결정은 [ebs-console.prd.md](../00-prd/ebs-console.prd.md)가 관할한다.

이 문서는 포커 방송 그래픽 시스템이 무엇이고, 어떻게 설계되어야 하는지를 설명한다. 문서만 읽고 시스템의 구조와 각 모듈의 역할을 개념적으로 이해할 수 있도록 작성되었다.

---

## Executive Summary

### 제품 정의

PokerGFX Clone은 라이브 포커 방송을 위한 실시간 그래픽 오버레이 시스템이다. RFID 카드 인식, GPU 렌더링, 다중 앱 동기화를 하나의 플랫폼으로 통합하여, 포커 테이블 위의 보이지 않는 정보를 시청자에게 시각적으로 전달한다.

### 핵심 가치

| 가치 | 설명 |
|------|------|
| **Hidden Information의 시각화** | 뒤집어진 홀카드를 RFID로 읽어 시청자에게 실시간 공개 |
| **방송 보안** | Dual Canvas로 현장과 방송을 물리적으로 분리, 정보 유출 차단 |
| **22개 게임 규칙 엔진** | Texas Hold'em부터 Badugi까지 모든 변형 게임을 하나의 시스템으로 처리 |
| **End-to-End 200ms** | 카드가 테이블에 놓이는 순간부터 방송 화면 표시까지 200ms 이내 |

### 범위

- **포함**: 서버 엔진, Action Tracker, Viewer Overlay, Skin Editor, 보조 앱 6종
- **제외**: 하드웨어 제조 (RFID 리더, 안테나, 전용 테이블), 토너먼트 관리 시스템

### 성공 지표

| 지표 | 목표 |
|------|------|
| 카드 인식 정확도 | 99.9% (52장 기준) |
| End-to-End 레이턴시 | 200ms 이내 |
| 동시 접속 클라이언트 | 7대 이상 |
| 지원 게임 수 | 22개 변형 |
| 기능 커버리지 | P0 85개 + P1 48개 + P2 18개 = 151개 |

---

## 목차

### Part I: 시장과 배경
1. [포커 방송은 왜 다른가](#1-포커-방송은-왜-다른가)
2. [카드 인식 기술의 진화](#2-카드-인식-기술의-진화)
3. [시장 환경과 경쟁 구도](#3-시장-환경과-경쟁-구도)
4. [왜 자체 개발인가](#4-왜-자체-개발인가)

### Part II: 시스템 비전
5. [시스템 전체 조감도](#5-시스템-전체-조감도)
6. [핵심 개념 3가지](#6-핵심-개념-3가지)
7. [7개 앱 생태계](#7-7개-앱-생태계)
8. [사용자 역할과 워크플로우](#8-사용자-역할과-워크플로우)

### Part III: 카드 인식
9. [테이블 하드웨어 배치](#9-테이블-하드웨어-배치)
10. [카드 인식 흐름](#10-카드-인식-흐름)

### Part IV: 게임 엔진
11. [22개 포커 게임 지원](#11-22개-포커-게임-지원)
12. [베팅 시스템](#12-베팅-시스템)
13. [핸드 평가 엔진](#13-핸드-평가-엔진)
14. [통계 엔진](#14-통계-엔진)

### Part V: 사용자 인터페이스
15. [Server: 데이터 허브](#15-server-데이터-허브)
16. [Action Tracker](#16-action-tracker)
17. [Viewer Overlay](#17-viewer-overlay)
18. [그래픽 커스터마이징](#18-그래픽-커스터마이징)

### Part VI: 기술 인프라
19. [GPU 렌더링 파이프라인](#19-gpu-렌더링-파이프라인)
20. [네트워크 프로토콜](#20-네트워크-프로토콜)
21. [비디오 파이프라인](#21-비디오-파이프라인)
22. [보안: Dual Canvas](#22-보안-dual-canvas)

### Part VII: 운영
23. [방송 준비 워크플로우](#23-방송-준비-워크플로우)
24. [게임 진행 워크플로우](#24-게임-진행-워크플로우)
25. [긴급 상황 복구](#25-긴급-상황-복구)
26. [핸드 히스토리](#26-핸드-히스토리)

### 부록
- [A. 22개 게임 전체 카탈로그](#부록-a-22개-게임-전체-카탈로그)
- [B. 113+ 프로토콜 명령 카탈로그](#부록-b-113-프로토콜-명령-카탈로그)
- [C. 151개 기능 카탈로그](#부록-c-151개-기능-카탈로그)
- [D. 용어 사전](#부록-d-용어-사전)
- [E. 참고 자료](#부록-e-참고-자료)
- [F. 다이어그램 목록](#부록-f-다이어그램-목록)

---

# Part I: 시장과 배경

## 1. 포커 방송은 왜 다른가

### 방송 그래픽의 공통 기반

모든 스포츠 방송은 동일한 기본 구조를 공유한다: 카메라로 경기를 촬영하고, 데이터를 수집하고, 그래픽으로 시청자에게 정보를 전달한다. 축구든 야구든 포커든, 카메라 영상 위에 오버레이를 합성하는 파이프라인은 같다.

종목마다 다른 것은 **데이터의 성격**이다. 축구는 스코어와 시간, 야구는 투구 속도와 타율, 포커는 카드와 승률. 각 종목의 방송 시스템은 이 데이터 요구사항에 맞춰 설계된다.

### Hidden Information Problem

포커와 다른 스포츠의 결정적 차이는 **Hidden Information**이다. 플레이어의 홀카드가 뒤집어져 있어서 카메라로 촬영할 수 없다.

![일반 스포츠 vs 포커 방송의 정보 흐름 비교 — 포커는 RFID라는 별도의 데이터 수집 경로가 필수적이다](../images/prd/prd-info-comparison.png)

| 구분 | 일반 스포츠 | 포커 |
|------|------------|------|
| **핵심 정보** | 공개됨 (공 위치, 점수) | 비공개 (홀카드) |
| **그래픽의 역할** | 정리 및 표시 | **생성** 및 표시 |
| **정보 획득** | 카메라 영상 | RFID 센서 |
| **연산 필요** | 거의 없음 | 실시간 확률 계산 |
| **보안 요구** | 없음 | 현장 유출 차단 필수 |
| **게임 규칙** | 1개 (해당 종목) | 22개 변형 |

축구 중계에서 점수판을 표시하려면 점수를 입력하면 된다. 포커 중계에서 홀카드를 표시하려면 **테이블 아래 숨겨진 RFID 리더가 뒤집어진 카드를 전자적으로 읽어야 한다**.

### 보안의 역설

포커 방송에는 독특한 역설이 존재한다.

- **시청자에게**: 홀카드를 보여줘야 한다
- **현장에**: 홀카드를 절대 보여주면 안 된다

현장 모니터에 홀카드가 표시되면 플레이어가 상대의 카드를 볼 수 있고, 게임의 공정성이 파괴된다. 그래서 포커 방송 시스템은 **두 개의 별도 화면**을 동시에 생성해야 한다. 하나는 현장용(홀카드 숨김), 하나는 방송용(홀카드 공개). 이것이 Dual Canvas 개념이다.

### 자동화가 필요한 이유

카드 인식 계층이 추가되면서, 수동 운영만으로는 처리하기 어려운 데이터량이 발생한다.

| 요구사항 | 배경 |
|----------|------|
| 매 핸드 최대 20장 카드 인식 | 10명 x 홀카드 2장이 매 핸드마다 반복된다 |
| 실시간 액션 추적 | Fold, Bet, Raise가 초 단위로 발생한다 |
| 승률 재계산 | 보드 카드가 나올 때마다 모든 플레이어의 Equity가 변동한다 |
| 보안 딜레이 | 생방송 중 홀카드 정보 유출을 방지해야 한다 |

### 왜 전용 시스템이 필요한가

일반 방송 그래픽 도구(CasparCG, vMix 등)로 포커 방송을 할 수 없는 이유:

| 요구사항 | 설명 |
|----------|------|
| RFID 하드웨어 드라이버 | 리더 12대 제어 |
| 카드 자동 인식 엔진 | 52장 실시간 추적 |
| 22개 게임 규칙 엔진 | 게임별 상태 관리 |
| 핸드 평가 알고리즘 | 등급 + 승률 계산 |
| Dual Canvas GPU 렌더링 | 현장/방송 분리 |
| Trustless 보안 모드 | 현장 유출 차단 |
| 7개 앱 동기화 프로토콜 | 역할별 앱 연동 |
| 딜러용 터치스크린 UI | 게임 진행 입력 |

이것이 **전용 시스템**이 필요한 이유다. PokerGFX는 단순한 그래픽 오버레이가 아니라, RFID 하드웨어부터 GPU 렌더링까지 수직 통합된 포커 전용 방송 엔진이다.

---

## 2. 카드 인식 기술의 진화

이 문제는 포커 방송이 시작된 이래 핵심 과제였고, 해결 방식은 기술과 함께 진화해 왔다.

### 기술 진화 타임라인

| 시기 | 이벤트 |
|------|--------|
| 1995 | Henry Orenstein, Hole Card Camera 특허 취득 |
| 1999 | Late Night Poker (Channel 4, UK), 최초의 홀카드 방송 |
| 2002 | ESPN WSOP 방송, Hole Card Camera 채택 |
| 2003 | World Poker Tour 런칭, 홀카드 방송의 대중화 |
| 2012 | European Poker Tour, RFID 테이블 도입 — 전자 인식 시대 개막 |
| 2013 | WSOP, RFID 기술 라이브 스트리밍에 적용 |
| 2014~2018 | WSOP, 30분 딜레이 프로토콜 + RFID 카드 운용 |
| 2024~현재 | RFID가 모든 주요 토너먼트의 표준으로 정착 |

![WPT 홀카메라 방송 — 테이블 유리판 아래 카메라가 플레이어의 홀카드를 촬영한다](03_Reference_ngd/web_screenshots/hole-card-cam-history.jpeg)
> *World Poker Tour 홀카메라 방송 화면. 테이블 레일에 내장된 소형 카메라가 카드를 직접 촬영하여 시청자에게 보여준다. (출처: casino.org)*

### 1세대 Hole Camera의 한계

- 카메라 각도와 조명에 의존 — 카드가 정확한 위치에 있어야 인식 가능
- 딜러가 카드를 특정 위치에 놓아야 하므로 게임 속도 저하
- 이미지 인식 정확도 제한
- 유리판 설치로 테이블 구조 변경 필요
- 10인 테이블에서 20장 카드를 동시 촬영하기 어려움

### 2세대 RFID의 장점

- 물리적 접촉 없이 전자적으로 카드 식별
- 인식 지연 ~50ms, 오류율 0%
- 테이블 표면 아래 매립으로 외관 변화 없음
- 10인 x 2장 = 20장 홀카드 동시 추적
- 게임 흐름 무중단

![WSOP Paradise 2025 RFID 방송 — RFID 시스템이 홀카드, 승률, 플레이어 정보를 자동으로 오버레이한다](03_Reference_ngd/web_screenshots/wsop-paradise-2025-rfid-broadcast.png)
> *WSOP Paradise 2025 Super Main Event 방송 화면. RFID 안테나가 카드를 자동 인식하여 홀카드, 팟 사이즈, 블라인드, 필드 정보가 실시간으로 표시된다. (출처: WSOP/PokerGO)*

**본 시스템은 현재 업계 표준인 RFID를 기본 구현으로 채택하되, 카드 인식 계층을 추상화하여 미래 기술로 교체 가능하게 설계한다.**

---

## 3. 시장 환경과 경쟁 구도

### 포커 방송 시장 규모

| 지표 | 수치 |
|------|------|
| 온라인 포커 시장 규모 (2024) | USD 3.86~7.98B |
| 토너먼트 부문 비중 | 전체 온라인 포커 매출의 41% (2025) |
| 라이브 스트리밍 시장 (2024) | USD 113.21B → USD 600.12B (2032, CAGR 23.28%) |
| WSOP 2024 메인 이벤트 | **10,112명** 참가 (역대 최대), 상금 풀 $94M |
| WSOP 2025 | 100개 라이브 브래슬릿 이벤트 (역대 최대 시리즈) |

### 경쟁 제품 분석

![PokerGFX 기반 방송 스튜디오 — 전용 RFID 테이블과 방송 장비가 하나의 시스템으로 통합된다](03_Reference_ngd/web_screenshots/pokergfx-overview.jpg)
> *PokerGFX 시스템이 탑재된 포커 방송 스튜디오. RFID 안테나가 내장된 전용 테이블과 모니터가 통합되어 하나의 프로덕션 시스템을 구성한다. (출처: habwin.com)*

| 시스템 | 사용처 | 특징 | 시장 위치 |
|--------|--------|------|----------|
| **PokerGFX** | WSOP, WPT, 대부분의 주요 토너먼트 | Windows .NET, RFID 통합, 4K UHD, 자동 카메라 전환 | **시장 지배적** |
| **wTVision PokerStats CG** | EPT, Italian Poker Tour | RFID 테이블 연동, 실시간 승률 계산 | 프리미엄 토너먼트 |
| **WPT 자체 시스템** | World Poker Tour | WPT 내부 개발, 고유 그래픽 스타일, 암호화 안테나 | WPT 전용 |
| **각 방송사 자체 시스템** | Hustler Casino Live 등 | 개별 요구에 맞춘 커스텀 개발 | 개별 운영 |

이들은 모두 동일한 기본 파이프라인을 공유한다: `카드 인식 → 서버 데이터 처리 → 방송 그래픽 생성`. 차이점은 그래픽 품질, 통계 깊이, 운영 편의성, 커스터마이징 자유도에 있다.

### DIY/오픈소스 동향

시장에서 주목할 점은 **저비용 솔루션에 대한 수요**다.

- Poker Chip Forum 커뮤니티의 DIY RFID 테이블 + 방송 오버레이 프로젝트
- Arduino/Raspberry Pi 기반 RFID 카드 리더 프로젝트
- PokerVision (GitHub): 컴퓨터 비전 기반 카드 인식 시도

![DIY RFID 포커 테이블 — 자체 제작한 RFID 테이블과 오버레이 시스템의 동작 예시](03_Reference_ngd/web_screenshots/diy-rfid-poker-table-thumbnail.jpg)
> *$300 미만으로 제작한 DIY RFID 포커 테이블. 자체 개발한 소프트웨어로 홀카드, 승률, 플레이어 정보 오버레이를 생성한다. EBS가 목표로 하는 시스템과 유사한 구조. (출처: YouTube / HN)*

---

## 4. 왜 자체 개발인가

### 핵심 동인: 경쟁사의 PokerGFX 인수

2024년 12월 30일, PokerGO가 PokerGFX를 Alcotrack Pty LTD로부터 인수했다.

PokerGFX는 WSOP을 포함한 대다수 라이브 포커 방송의 핵심 그래픽 시스템이다. 동시에 PokerGO는 2017년부터 WSOP 독점 방송권을 보유한 미디어 파트너이자, 자체 PGT를 운영하는 경쟁 이벤트 주최자다. 이 인수는 **미션 크리티컬한 방송 도구가 경쟁사의 통제 하에 놓였음**을 의미한다.

| 리스크 | 설명 |
|--------|------|
| **Vendor Lock-in** | 방송 그래픽 시스템의 가격, 기능, 업데이트 일정이 경쟁사의 사업 판단에 종속 |
| **데이터 유출 우려** | 게임 데이터, 플레이어 통계, 운영 정보가 경쟁사 소유 시스템을 경유 |
| **기능 차별화 제한** | PokerGO가 자사 PGT 방송에 우선 적용하는 신기능을 동시에 활용할 수 없을 가능성 |
| **사업 연속성** | 파트너십 변경 시 대안 시스템 부재 — 전환 비용과 시간이 막대 |

**자체 개발은 선택이 아니라, 방송 인프라 자주권 확보를 위한 전략적 필수 사항이다.**

### 전략적 기회: 데이터 내재화

현재 모든 게임 데이터 — 핸드 히스토리, 플레이어 통계, 방송 이력 — 가 PokerGFX 내부에 갇혀 있다.

| 영역 | 현재 (PokerGFX) | 자체 시스템 목표 |
|------|-----------------|-----------------|
| **데이터 소유권** | 경쟁사 시스템에 종속 | 자사 DB 완전 소유 |
| **분석 활용** | 제한적 내보내기 | 자유로운 데이터 분석 및 시각화 |
| **콘텐츠 제작** | 수동 | 데이터 기반 자동 콘텐츠 생성 |
| **히스토리 축적** | 시즌별 단절 | 연도별 누적 — 장기 자산화 |

### 기술적 개선 기회

| 영역 | PokerGFX (현행) | 자체 시스템 목표 |
|------|-----------------|-----------------|
| 플랫폼 | Windows .NET 4.x 전용 | 크로스플랫폼 |
| 아키텍처 | 모놀리식 데스크탑 | 모듈러 서버-클라이언트 |
| 프로토콜 | 자체 바이너리 (암호화 취약) | gRPC + Protobuf |
| 보안 | MITM 취약, AWS 키 하드코딩, AES Zero IV | 현대적 보안 표준 |
| 배포 | 설치형 | 컨테이너/클라우드 |

### 벤치마크 전략

**PokerGFX의 기능 세트를 벤치마크로 삼아 동일 수준의 시스템을 자체 구현한다.** PokerGFX를 선택한 이유는 현재 실제 운영 환경에서 검증되었으며, 역공학을 통해 기능이 가장 상세하게 분석되어 있기 때문이다. 역공학 결과 88% 커버리지(839/2,602 타입)가 확보되어 있다.

---

# Part II: 시스템 비전

## 5. 시스템 전체 조감도

### 3계층 아키텍처

시스템은 3개 계층으로 구성된다: **하드웨어**(RFID 리더), **서버 엔진**(데이터 처리), **클라이언트 앱**(사용자 인터페이스).

| 계층 | 구성 요소 | 역할 |
|------|----------|------|
| **Layer 1: Hardware** | RFID Reader x12, GPU Card, Capture Card, Video Switcher | 물리적 데이터 수집 및 영상 입출력 |
| **Layer 2: Server Engine** | Game Engine, State Manager, Hand Eval, GPU Renderer, Protocol Server, Skin System, Output Manager | 모든 데이터 처리의 중심 |
| **Layer 3: Client Apps** | Action Tracker, ActionClock, StreamDeck, Commentary Booth, Pipcap, HandEvaluation | 사용자별 전용 인터페이스 |

### 6개 모듈 구성

![시스템 모듈 구조](01_Mockups_ngd/pokergfx-module-overview.png)

| 모듈 | 역할 | 사용자 |
|------|------|--------|
| **Card Recognition** | 테이블 위의 카드를 읽는다 (현재 RFID) | 하드웨어 (자동) |
| **Server** | 모든 데이터를 관리한다 — 카드 매핑, 게임 상태, 통계, 보안 | 시스템 (자동) |
| **Action Tracker** | 운영자가 게임 진행을 추적한다 | 운영자 |
| **Viewer Overlay** | 시청자가 보는 방송 화면을 만든다 | 시청자 (자동) |
| **GFX Console** | 비디오 I/O, 통계, 스킨, 시스템을 관리한다 | 엔지니어/운영자 |
| **ATEM Switcher** | 비디오 스위칭 하드웨어를 제어한다 (Blackmagic ATEM COM) | 시스템 (자동) |

이 구조에서 핵심은 **Server가 모든 데이터의 허브**라는 점이다. 카드 인식 시스템이 읽은 카드, 운영자가 입력한 액션, 계산된 통계 — 모두 Server를 거친다.

### 데이터 흐름

카드 한 장이 테이블에 놓이는 순간부터 시청자 화면에 표시되기까지:

```
RFID 감지 ──► 카드 매핑 ──► 게임 엔진 ──► 핸드 평가 + 승률 ──► GPU 렌더링 ──► 방송 출력
  ~50ms        ~30ms       상태 갱신        ~50ms (병렬)         ~70ms
                                                            ─────────────────────
                                                            Total: ~200ms
```

![핸드 생명주기 시퀀스](01_Mockups_ngd/pokergfx-hand-lifecycle.png)

---

## 6. 핵심 개념 3가지

PokerGFX를 이해하는 데 가장 중요한 3가지 개념이 있다.

### 6.1 RFID 카드 인식

**"테이블 위에 놓인 뒤집힌 카드를 어떻게 아는가"**

카드 52장 + 1장(Joker)에 각각 RFID 태그(NXP NTAG215, 13.56MHz)가 내장되어 있다. 각 태그는 고유한 7-byte UID를 가지며, 이 UID가 어떤 카드인지 매핑 테이블로 변환된다.

![RFID IC 회로 — 카드에 내장된 패시브 RFID 태그의 안테나와 마이크로칩](03_Reference_ngd/web_screenshots/rfid-live-poker-event.jpg)
> *RFID 태그의 안테나 패턴과 IC. 각 카드에 이러한 패시브 태그가 내장되어 있으며, 고유 UID를 저장한다. (출처: habwin.com)*

### 6.2 Dual Canvas

**"같은 게임을 두 가지 화면으로 동시에 렌더링한다"**

| 속성 | Live Canvas | Delayed Canvas |
|------|-------------|---------------|
| **대상** | 현장 모니터 | 방송 송출 |
| **홀카드** | 숨김 (??) | 공개 (A♠K♥) |
| **승률** | 미표시 | 표시 (67.3%) |
| **핸드 등급** | 미표시 | 표시 (Pair of Kings) |
| **지연** | 실시간 | N초 지연 (보통 30~60초) |
| **이름/칩/베팅** | 표시 | 표시 |

**Trustless Mode**: Live Canvas에는 어떤 상황에서도 홀카드를 표시하지 않는 보안 모드. Showdown이 끝난 후에만 Live에 카드가 공개된다.

### 6.3 실시간 승률 계산

**"현재 카드 상태에서 각 플레이어가 이길 확률을 즉시 계산한다"**

| 방식 | 설명 | 채택 여부 |
|------|------|----------|
| **Exhaustive Enumeration** | 가능한 모든 보드 조합 전수 탐색. Pre-Flop에서 연산 불가 | 불가 |
| **Monte Carlo Simulation** | 10,000회 무작위 시뮬레이션. ~200ms 이내. 정확도 ±1% | **채택** |
| **PocketHand169 LUT** | 169개 핸드 타입의 사전 계산된 승률표 | **Pre-Flop 전용** |

---

## 7. 7개 앱 생태계

포커 방송 현장에는 여러 역할의 사람이 동시에 일한다. 각자 다른 앱이 필요하다.

| App | 역할 | 사용자 |
|-----|------|--------|
| **GfxServer** | 모든 상태의 단일 원본. 게임 엔진, RFID, GPU 렌더링 | 방송 감독, GFX 운영자 |
| **ActionTracker** | 딜러용 터치스크린. 게임 진행 입력 | 딜러 |
| **HandEvaluation** | 독립 평가 서비스. Monte Carlo CPU 부하 분산 | 시스템 (자동) |
| **ActionClock** | Shot Clock + Time Bank 외부 디스플레이 | 플레이어 |
| **StreamDeck** | Elgato StreamDeck 물리 버튼으로 빈번한 작업 수행 | GFX 운영자 |
| **Pipcap** | 카드 이미지 캡처. 스킨용 Pip 생성 | 스킨 디자이너 |
| **CommentaryBooth** | 해설자 전용. 전체 홀카드 + 승률 + 핸드 랭크 실시간 표시 | 해설자 |

7개 앱이 하나의 서버에 연결되어 실시간 동기화된다. 딜러가 Action Tracker에서 "Raise"를 누르면, GfxServer가 상태를 갱신하고, 모든 연결된 앱에 즉시 전파된다.

---

## 8. 사용자 역할과 워크플로우

### 5가지 사용자 역할

| 역할 | 주 사용 앱 | 핵심 과업 |
|------|-----------|----------|
| **방송 감독** | GfxServer, StreamDeck | 게임 유형 선택, 스킨 로드, 출력 설정, 전체 방송 흐름 관리 |
| **GFX 운영자** | GfxServer, StreamDeck | 그래픽 제어, 수동 카드 입력, 오버레이 전환, 통계 표시 |
| **딜러** | ActionTracker | 게임 진행 입력: 베팅 액션, 핸드 시작/종료, 특수 상황 처리 |
| **해설자** | CommentaryBooth | 전체 홀카드, 승률, 핸드 랭크 확인하여 실시간 해설 |
| **시스템 관리자** | GfxServer (System 탭) | 서버 설정, RFID 구성, 네트워크, 라이선스 관리 |

### 사용자 여정: 하나의 핸드

```
방송 감독: 게임 유형 선택 → 스킨 로드 → 출력 설정 → "GO"
                                                    ↓
딜러 (AT): ← New Hand ← 카드 딜 ← 베팅 액션 입력 ← Flop/Turn/River ← Showdown
                 ↓           ↓            ↓               ↓              ↓
GfxServer:   테이블 초기화   RFID 인식    팟 계산        보드 표시      승자 결정
                 ↓           ↓            ↓               ↓              ↓
시청자:      칩 표시      홀카드 표시   팟 금액       보드 카드     승자 하이라이트
                                                                        ↓
해설자 (CB):     모든 카드 + 승률 실시간 확인 → 실시간 해설 ──────────────┘
```

---

# Part III: 카드 인식

## 9. 테이블 하드웨어 배치

### RFID 리더 12대 배치

PokerGFX 기준으로 **26개 안테나**가 12대 리더에 분산되어 있다:

| 리더 | 수량 | 안테나 | 역할 |
|------|:----:|:------:|------|
| Seat Reader | 10대 | 각 2개 | 플레이어 홀카드 2장 감지 |
| Board Reader | 1대 | 4개 | Flop(3) + Turn(1) + River(1) 감지 |
| Muck Reader | 1대 | 2개 | 폴드/버린 카드 감지 |
| **합계** | **12대** | **26개** | |

![RFID 센서 보드 — 테이블 표면 아래에 매립되는 리더 모듈](03_Reference_ngd/web_screenshots/rfid-sensor-board-table.png)
> *RFID 센서 보드. 테이블 펠트 아래에 설치되어 카드의 RFID 태그를 읽는다. (출처: macaumr.com)*

### 카드 태그 사양

| 사양 | 값 |
|------|-----|
| 태그 IC | NXP NTAG215 |
| 주파수 | 13.56 MHz (HF, NFC Forum Type 2) |
| 메모리 | 504 bytes |
| UID | 7 bytes (고유 식별자) |
| 읽기 범위 | ~3cm |
| 총 수량 | 52장 + 1장 (Joker) |
| 카드 규격 | CR80 (85.6mm x 54mm), Photo Quality PVC |

---

## 10. 카드 인식 흐름

### End-to-End 인식 타임라인

```
시간 ──────────────────────────────────────────────────►
0ms        50ms       80ms       130ms      200ms

┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
│ RFID   │ │ 전송   │ │ 처리   │ │ 평가   │ │ 렌더   │
│ 감지   │►│        │►│        │►│        │►│        │
│ 안테나 │ │WiFi/USB│ │Card Map│ │Hand +  │ │GPU     │
│ 태그   │ │→서버   │ │Tag→카드│ │Win%    │ │Compose │
│ 인식   │ │        │ │State   │ │(병렬)  │ │Output  │
└────────┘ └────────┘ └────────┘ └────────┘ └────────┘
  ~50ms      ~30ms      ~50ms               ~70ms
```

### Dual Transport

RFID 리더와 서버 간 통신은 2가지 경로를 지원한다.

| 속성 | WiFi (TCP) | USB (HID) |
|------|-----------|-----------|
| 속도 | ~10ms | ~30ms |
| 안정성 | 보통 | 높음 |
| 보안 | TLS 1.3 | 물리 연결 |
| 역할 | **Primary** | **Fallback** |

WiFi 실패 시 자동으로 USB 폴백한다.

### 카드 상태 관리

52장 카드는 4가지 상태를 순환한다:

```
DECK (미감지) ──Detect──► DETECTED (감지) ──Assign──► ASSIGNED (좌석 배정)
     ▲                                                    │
     └──────────── Reset ──── REVEALED / MUCKED ◄─────────┘
```

전체 52장 추적 예시 (10인 Hold'em): 홀카드 20장(ASSIGNED) + 보드 0~5장(DETECTED) + Muck 가변(MUCKED) + 나머지(DECK) = **항상 52장**

### Register Deck: 덱 등록

새 카드 덱을 투입할 때마다 52장의 UID를 DB에 등록해야 한다. Server의 메인 화면에 **Register Deck** 버튼이 있으며, 이를 누르면 순차적으로 카드를 스캔하여 UID를 기록한다. 한 번 등록된 덱은 교체 전까지 유효하다.

---

# Part IV: 게임 엔진

## 11. 22개 포커 게임 지원

### 3대 계열 분류

포커 22가지 변형 게임은 3대 계열로 분류된다.

| 속성 | Community Card (13개) | Draw (7개) | Stud (3개) |
|------|----------------------|------------|------------|
| **홀카드 수** | 2~6장 | 4~5장 | 7장 (3+4) |
| **커뮤니티 카드** | 최대 5장 | 없음 | 없음 |
| **카드 교환** | 없음 | 1~3회 | 없음 |
| **공개 카드** | 커뮤니티 전체 | 없음 | 4장 (3rd~6th) |
| **베팅 라운드** | 4 (Pre~River) | 2~4 | 5 (3rd~7th) |
| **RFID 추적** | 홀카드 + 보드 | 홀카드만 | 홀카드 + 공개 |
| **대표 게임** | Texas Hold'em | 2-7 Triple Draw | 7-Card Stud |

### 게임 상태 머신

모든 포커 게임은 상태 머신으로 동작한다.

- **Community Card**: IDLE → SETUP_HAND → PRE_FLOP → FLOP → TURN → RIVER → SHOWDOWN → HAND_COMPLETE
- **Draw**: IDLE → SETUP_HAND → DRAW_ROUND 1 → DRAW_ROUND 2 → ... → SHOWDOWN → HAND_COMPLETE
- **Stud**: IDLE → SETUP_HAND → 3RD_STREET → 4TH → 5TH → 6TH → 7TH → SHOWDOWN → HAND_COMPLETE

각 상태 전환에서 RFID 감지, 베팅 액션, 승률 재계산이 트리거된다.

> 전체 22개 게임 목록은 [부록 A](#부록-a-22개-게임-전체-카탈로그) 참조.

---

## 12. 베팅 시스템

### 3가지 베팅 구조

| 구조 | 최소 베팅 | 최대 베팅 | 적용 게임 예시 |
|------|----------|----------|--------------|
| **No Limit** | Big Blind | All-in (전 칩) | NL Hold'em, NL Omaha |
| **Pot Limit** | Big Blind | 현재 팟 크기 | PLO (Pot Limit Omaha) |
| **Fixed Limit** | Small Bet / Big Bet | 고정 단위 (Cap: 보통 4 Bet) | Limit Hold'em, Stud |

### 7가지 Ante 유형

| Ante 유형 | 납부자 | 설명 |
|-----------|--------|------|
| **Standard** | 전원 | 전체 플레이어가 동일 금액 납부 |
| **Button** | 딜러만 | 딜러 버튼 위치 플레이어만 납부 |
| **BB Ante** | Big Blind만 | BB가 전원 Ante를 대납 |
| **BB Ante (BB 1st)** | Big Blind만 | BB Ante + BB가 먼저 행동 |
| **Live Ante** | 전원 | Standard + Ante가 팟에 포함 |
| **TB Ante** | SB + BB | Two Blind 합산 Ante |
| **TB Ante (TB 1st)** | SB + BB | TB Ante + SB/BB 먼저 행동 |

### 특수 규칙 4가지

| 규칙 | 설명 |
|------|------|
| **Bomb Pot** | 전원 합의 금액 납부 → Pre-Flop 건너뛰고 바로 Flop |
| **Run It Twice** | All-in 후 남은 보드를 2회 전개, 팟 절반씩 분할 |
| **7-2 Side Bet** | 7-2 오프슈트(최약 핸드)로 이기면 사이드벳 수취 |
| **Straddle** | 자발적 3번째 블라인드 (보통 2x BB) |

---

## 13. 핸드 평가 엔진

### 핸드 등급 체계

| 등급 | 이름 | 확률 |
|:----:|------|-----:|
| 9 | Royal Flush | 0.0002% |
| 8 | Straight Flush | 0.0013% |
| 7 | Four of a Kind | 0.024% |
| 6 | Full House | 0.14% |
| 5 | Flush | 0.20% |
| 4 | Straight | 0.39% |
| 3 | Three of a Kind | 2.11% |
| 2 | Two Pair | 4.75% |
| 1 | One Pair | 42.26% |
| 0 | High Card | 50.12% |

### 17개 게임별 평가기 라우팅

| 평가기 | 대상 게임 | 설명 |
|--------|----------|------|
| **Standard High** | Hold'em, Omaha, Stud, Draw (12개) | 높은 핸드가 승리 |
| **Hi-Lo Splitter** | Omaha HL, Stud HL, Courchevel HL (5개) | High + Low 동시 평가, 팟 분할 |
| **Lowball** | Razz, 2-7 Draw, A-5 Draw, Badugi (5개) | 낮은 핸드가 승리 (역전) |

### Lookup Table 기반 O(1) 평가

```
카드 5장 ──► Bitmask 인코딩 ──► LUT Index ──► 등급 + 값
```

- 538개 테이블, ~2.1MB 메모리
- 시간 복잡도: O(1) (테이블 참조만)
- 일반 알고리즘 대비 ~100배 속도 향상

---

## 14. 통계 엔진

### 실시간 Equity 계산

모든 플레이어의 홀카드와 보드 카드가 인식되면, 시스템은 각 플레이어의 승률을 실시간으로 계산한다.

| 스트리트 | 알려진 카드 | 계산 방법 |
|----------|-------------|-----------|
| Preflop | 홀카드만 | PocketHand169 LUT 또는 Monte Carlo |
| Flop | 홀카드 + 3장 | Turn/River 조합 시뮬레이션 |
| Turn | 홀카드 + 4장 | River 1장 시뮬레이션 |
| River | 홀카드 + 5장 | 확정 (승자 결정) |

2~10명 동시 계산을 지원하며, 타이 확률과 아웃츠 분석도 포함된다.

### 플레이어 통계

세션 동안 축적된 핸드 데이터로 플레이어별 통계를 계산한다.

| 통계 | 의미 |
|------|------|
| **VPIP** | 자발적으로 팟에 참여한 비율 |
| **PFR** | 프리플롭에서 레이즈한 비율 |
| **AGR** | 공격적 플레이 비율 |
| **WTSD** | 쇼다운까지 간 비율 |
| **3Bet%** | 3벳 빈도 |
| **CBet%** | 컨티뉴에이션 벳 빈도 |
| **WIN%** | 핸드 승률 |
| **AFq** | 공격 빈도 |

이 통계는 GFX Console의 리더보드에 표시되거나, Viewer Overlay에 LIVE Stats로 노출될 수 있다.

---

# Part V: 사용자 인터페이스

## 15. Server: 데이터 허브

Server는 시스템의 중심이다. 단일 윈도우 데스크탑 앱으로, 좌측에 방송 Preview, 하단에 7개 탭, 우측에 핵심 컨트롤이 배치된다.

![PokerGFX Server 메인 화면](01_Mockups_ngd/01-main-window.png)

### 메인 화면 구성

| 영역 | 기능 |
|------|------|
| **Preview** | 크로마키 배경 위에 오버레이가 실시간 렌더링되는 미리보기 |
| **상태 표시** | CPU/GPU 사용률, Error, Lock 상태 |
| **Secure Delay** | 보안 딜레이 활성화 체크박스 |
| **Register Deck** | 카드 덱 일괄 등록 |
| **Action Tracker** | Action Tracker 앱 실행 버튼 |
| **Reset Hand** | 현재 핸드 초기화 + 설정 + Lock |
| **Tag Player** | 특정 플레이어 태그 부여 |

### 7개 탭 구조

| 탭 | 기능 수 | 역할 |
|:--:|:-------:|------|
| **Sources** | 10 | 비디오 소스 설정, NDI 입력, 캡처 카드 |
| **Outputs** | 12 | Dual Canvas, NDI/HDMI/SDI 출력, Trustless, Chroma Key |
| **GFX 1** | 24 | 핵심 게임 제어 (좌석, 카드, 팟, 승률, 베팅 액션) |
| **GFX 2** | 13 | 플레이어 통계 (VPIP, PFR, AF), 토너먼트 정보 |
| **GFX 3** | 13 | 방송 연출 (자막, 로고, 티커, PIP, 리플레이) |
| **Commentary** | 7 | 해설자 전용 (전체 홀카드, 승률, 핸드 랭크) |
| **System** | 16 | 서버 설정, RFID 구성, 네트워크, 라이선스 |

### Server의 핵심 역할

```
                    ┌─────────────┐
   카드 인식기 ───→ │             │ ───→  Viewer Overlay (방송 화면)
   (RFID 리더)      │   SERVER    │
Action Tracker ←──→ │             │ ←──→  GFX Console (설정/관리)
                    │  카드 매핑   │
                    │  게임 상태   │ ───→  핸드 히스토리 DB
                    │  통계 계산   │
                    │  보안 딜레이  │ ───→  녹화/NDI 출력
                    └─────────────┘
```

각 탭의 상세 UI는 아래 문서에서 확인할 수 있다:
- [Sources 탭](PokerGFX-UI-Analysis.md#2-sources-탭)
- [Outputs 탭](PokerGFX-UI-Analysis.md#3-outputs-탭)
- [GFX 1~3 탭](PokerGFX-UI-Analysis.md#4-gfx-1-탭)
- [System 탭](PokerGFX-UI-Analysis.md#8-system-탭)

---

## 16. Action Tracker

Action Tracker는 딜러가 실시간으로 포커 게임 진행을 추적하는 독립 앱이다. Server와 네트워크로 연결되어 있으며, 별도 터치스크린 모니터에서 실행된다.

![Action Tracker 와이어프레임](01_Mockups_ngd/13-action-tracker-wireframe.png)

**실제 PokerGFX Action Tracker 스크린샷:**

![Setup 모드 — 10인 좌석, 게임 타입/블라인드 설정, AUTO 모드 토글](03_Reference_ngd/action_tracker/at-01-setup-mode.png)
> *Setup Mode: 게임 시작 전 좌석 배치, CAP/ANTE/BTN BLIND/DEALER/SB/BB/3B 설정, HOLDEM/SINGLE BOARD 선택. 좌측 하단의 MIN CHIP/7 DEUCE/BOMB POT/# BOARDS/HIT GAME은 특수 룰 설정.*

![Preflop 액션 — 딜러가 터치스크린에서 플레이어 액션을 입력한다](03_Reference_ngd/action_tracker/at-02-action-preflop.png)
> *Action Mode (Preflop): Seat 1 선택 상태. FOLD/CALL/RAISE-TO/ALL IN 4개 액션 버튼. 상단에 플레이어 홀카드 아이콘, 중앙에 "(1) SEAT 1 - STACK 1,000,000" 표시. MISS DEAL/HIDE GFX 특수 버튼.*

![수동 카드 선택 — 52장 카드 그리드에서 직접 카드를 지정한다](03_Reference_ngd/action_tracker/at-03-card-selector.png)
> *Manual Card Selector: RFID 인식 실패 또는 수동 모드 시 사용. 4수트 x 13랭크 = 52장 전체 표시. 선택된 카드(7♥ 6♠)가 상단에 표시되며 OK 버튼으로 확정.*

![Postflop 액션 — 보드 카드가 표시되고 액션 버튼이 상황에 맞게 변경된다](03_Reference_ngd/action_tracker/at-04-action-postflop.png)
> *Action Mode (Postflop): Seat 2 차례. 중앙에 인식된 카드 3장(7♥ 6♠ 4♥) 표시. Preflop과 달리 FOLD/CHECK/BET/ALL IN 4개 버튼으로 변경 — 콜할 대상이 없으므로 CALL 대신 CHECK, RAISE-TO 대신 BET이 표시된다.*

![통계 뷰 — 플레이어별 VPIP%, PFR%, AGRFq%, WTSD%, WIN 통계](03_Reference_ngd/action_tracker/at-05-statistics-register.png)
> *Statistics/Register View: 10인 좌석별 STACK, VPIP%, PFR%, AGRFq%, WTSD%, WIN 통계. LIVE/GFX 전환, HAND 번호 표시, FIELD/REMAIN/TOTAL 토너먼트 정보, STRIP STACK/STRIP WIN/TICKER 방송용 데이터 토글.*

![RFID 카드 등록 — "PLACE THIS CARD ON ANY ANTENNA" 안내와 함께 등록할 카드를 표시한다](03_Reference_ngd/action_tracker/at-06-rfid-registration.png)
> *RFID Card Registration: 52장 카드를 하나씩 안테나에 올려 UID를 매핑하는 화면. A♠ 카드를 등록 대기 중이며, CANCEL로 중단 가능. 모든 카드의 RFID UID가 매핑되면 자동 인식 모드로 전환된다.*

### 화면 구성

| 영역 | 위치 | 기능 |
|------|------|------|
| **연결 상태** | 상단 | Network, Table, Stream, Record 상태 표시 |
| **게임 설정** | 상단 | 게임 타입 (Holdem/PLO/Short Deck), 블라인드, 핸드 번호 |
| **좌석 그리드** | 중앙 | 10인 원형 배치 — 이름, 스택, 홀카드, 상태 |
| **액션 버튼** | 중앙 | FOLD / CHECK / CALL / BET / RAISE / ALL-IN |
| **베팅 입력** | 중앙 | 금액 직접 입력, +/- 조정, Quick Bet (MIN/POT/ALL-IN) |
| **보드** | 하단 | 커뮤니티 카드 5장 표시 |
| **특수 컨트롤** | 하단 | HIDE GFX, TAG HAND, ADJUST STACK, CHOP, RUN IT 2x, MISS DEAL |

### 운영 워크플로우

**Pre-Start (게임 시작 전)**

```
이벤트 이름 입력 → 게임 타입 선택 → 블라인드 설정
        ↓
10명 플레이어 이름/스택 입력
        ↓
딜러 버튼 위치 지정
        ↓
"TRACK THE ACTION" 버튼으로 추적 시작
```

**핸드 진행**

```
카드 인식 시스템이 홀카드 감지 → 좌석 그리드에 카드 표시
        ↓
운영자가 블라인드 포스팅 확인 (SB/BB 자동 할당)
        ↓
Preflop: 각 플레이어 액션 입력 (Fold/Call/Raise...)
        ↓
카드 인식 시스템이 Flop 3장 감지 → 보드에 카드 표시
        ↓
Flop → Turn → River: 액션 입력 반복
        ↓
쇼다운: 승자 결정, 팟 분배
        ↓
딜러 버튼 이동 → 다음 핸드 시작
```

> **AUTO 모드**: 카드 인식 시스템이 카드를 자동으로 감지하고, 보드 카드가 나오면 스트리트가 자동으로 진행된다. 운영자는 플레이어 액션만 입력하면 된다.

### 특수 상황 처리

| 상황 | 버튼 | 동작 |
|------|------|------|
| 오버레이 숨기기 | HIDE GFX | 방송 화면에서 모든 GFX 일시 제거 |
| 중요 핸드 표시 | TAG HAND | 현재 핸드에 태그 추가 (나중에 검색 가능) |
| 칩 수정 | ADJUST STACK | 컬러업, 수동 조정 시 특정 플레이어 스택 변경 |
| 팟 분배 | CHOP | 팟을 여러 플레이어에게 분할 |
| 더블 런아웃 | RUN IT 2x | 두 번째 보드 생성 (Run It Twice 합의 시) |
| 미스딜 | MISS DEAL | 현재 핸드 무효화, 카드 재분배 |
| 되돌리기 | UNDO | 마지막 액션 취소 (최대 5단계) |

---

## 17. Viewer Overlay

Viewer Overlay는 시청자가 TV/스트림에서 실제로 보는 그래픽 요소다. 카메라 영상 위에 크로마키로 합성된다.

![Viewer Overlay 와이어프레임](01_Mockups_ngd/14-viewer-overlay-wireframe.png)

![실제 방송 오버레이 — PokerGFX가 생성한 홀카드, 승률, 플레이어 정보가 실시간으로 표시된다](03_Reference_ngd/web_screenshots/pokercaster-broadcast-overlay.webp)
> *PokerGFX 기반 실제 방송 화면. 각 플레이어의 홀카드, 포지션, 칩 스택, 승률, 팟 사이즈, 핸드 번호, 필드 정보가 동시에 표시된다. (출처: pokercaster.com)*

### 오버레이 구성 요소

| 요소 | 위치 | 설명 |
|------|------|------|
| **플레이어 정보** | 각 플레이어 근처 | 이름, 칩 스택, 마지막 액션 |
| **홀카드** | 플레이어 정보 옆 | 카드 인식 시스템이 읽은 카드 이미지 |
| **승률 (Equity)** | 플레이어 정보 옆 | 실시간 승률 퍼센트 |
| **보드 카드** | 화면 중앙 | Flop/Turn/River 커뮤니티 카드 |
| **팟** | 보드 근처 | 현재 팟 사이즈 |
| **이벤트 정보** | 상단 | 이벤트명, 블라인드 레벨 |
| **로고** | 상단/하단 | 이벤트 로고, 방송사 로고 |
| **스트리트 표시** | 보드 근처 | PREFLOP / FLOP / TURN / RIVER |
| **액션 대기자** | 현재 플레이어 | "To Act" 강조 표시 |
| **폴드 표시** | 폴드한 플레이어 | 회색 처리 / 반투명화 |

### 렌더링 파이프라인

```
Server 렌더링 엔진 → 크로마키 배경 위 오버레이 렌더링
→ NDI / 캡처 카드 출력 → 방송 스위처(ATEM)에서 카메라 영상과 합성
→ 최종 방송 화면
```

---

## 18. 그래픽 커스터마이징

모든 시각적 요소는 커스터마이징이 가능하다. 두 가지 에디터가 제공된다.

### Skin Editor — 전체 테마

![Skin Editor](01_Mockups_ngd/09-skin-editor.png)

스킨은 방송 그래픽의 전체 외형을 정의한다. 파일 형식은 .vpt/.skn이며, AES 암호화로 보호된다. 99+ 설정 필드를 포함한다.

| 카테고리 | 주요 설정 |
|----------|----------|
| **Table** | 배경 이미지, 테이블 형태, 펠트 색상, 테두리 |
| **Seat (x10)** | 위치, 이름 폰트, 칩 포맷, 카드 위치, 하이라이트 색상 |
| **Card** | 카드 뒷면, 앞면 스타일, Pip 스타일, 애니메이션 |
| **Board** | 위치, 팟 표시 위치, 카드 간격, 애니메이션 |
| **Font** | 기본/보조 글꼴, 크기, 색상 |
| **Color** | 색상 팔레트, 액션별 색상, 그라데이션 |
| **Animation** | 딜/공개/승리 애니메이션, 전환 시간 |
| **Logo/Branding** | 로고 이미지/위치, 스폰서, 티커, Lower Third |

### Graphic Editor — 개별 요소

![Graphic Editor - Board](01_Mockups_ngd/10-graphic-editor-board.png)
![Graphic Editor - Player](01_Mockups_ngd/11-graphic-editor-player.png)

| 편집 모드 | 기능 수 | 대상 |
|-----------|:-------:|------|
| **GE Board** | 15 | 커뮤니티 카드, 팟, 딜러 버튼 영역 |
| **GE Player** | 15 | 플레이어 이름, 칩, 홀카드, 승률, 핸드 랭크 |

### 4가지 그래픽 요소 타입

| 요소 | 필드 수 | 용도 |
|------|:-------:|------|
| **Image** | 41 | 카드 이미지, 로고, 배경 |
| **Text** | 52 | 플레이어 이름, 칩 카운트, 승률, 팟 |
| **Pip** | 12 | 카드 심볼 (Suit + Rank) |
| **Border** | 8 | 테두리, 구분선, 강조 표시 |

### 애니메이션 시스템

16개 Animation State x 11개 Animation Class: FadeIn/Out, SlideLeft/Right/Up/Down, ScaleIn/Out, FlipHorizontal/Vertical, Pulse, Flash, Bounce, Rotate, Custom.

---

# Part VI: 기술 인프라

## 19. GPU 렌더링 파이프라인

### 5-Thread Producer-Consumer 아키텍처

```
┌─────────────┐
│ Game State  │ (Producer: 게임 상태 변경 이벤트)
└──────┬──────┘
       │
       ├──────────────────────────┐
       ▼                          ▼
┌─────────────┐           ┌─────────────┐
│ Thread 1    │           │ Thread 2    │
│ Live Render │           │ Delay Render│
│ DirectX 11  │           │ DirectX 11  │
│ (현장용)    │           │ (방송용)    │
└──────┬──────┘           └──────┬──────┘
       │    ┌─────────────┐      │
       │    │ Thread 3    │      │
       │    │ Audio Mix   │      │
       │    └──────┬──────┘      │
       ▼           ▼              ▼
┌──────────────────────────────────────┐
│ Thread 4: Write Thread               │
│ GPU Encode (NVENC/AMF/QSV/x264)     │
└──────────────────┬───────────────────┘
                   ▼
┌──────────────────────────────────────┐
│ Thread 5: ProcessDelay Thread        │
│ Delay Buffer (N초 지연 후 출력)       │
└──────────────────────────────────────┘
```

### GPU 코덱 자동 선택

| 우선순위 | 코덱 | GPU | 부하 |
|:--------:|------|-----|------|
| 1 | NVENC | NVIDIA | GPU <5% |
| 2 | AMF | AMD | GPU <5% |
| 3 | QSV | Intel | GPU <5% |
| 4 | x264 | CPU 폴백 | CPU ~30% |

멀티 GPU 환경에서 DXGI SharedHandle을 사용하여 Live와 Delay Canvas를 각각 다른 GPU에서 렌더링 가능 (Zero-Copy Cross-GPU Texture Sharing).

---

## 20. 네트워크 프로토콜

### 4계층 프로토콜 스택

| 계층 | 기술 | 설명 |
|------|------|------|
| **Layer 4: Application** | 113+ 명령어, 5개 gRPC 서비스 | 비즈니스 로직 |
| **Layer 3: Serialization** | Protocol Buffers | 바이너리 직렬화 |
| **Layer 2: Security** | TLS 1.3, AES-256 | 암호화 |
| **Layer 1: Transport** | gRPC over HTTP/2, TCP :8888 | 전송 |

### 5개 gRPC 서비스

| 서비스 | 주요 메서드 |
|--------|-----------|
| **GameService** | NewHand, StartGame, EndGame, SetGameType, GetGameInfo |
| **PlayerService** | AddPlayer, RemovePlayer, UpdateChips, SetSeat, GetStats |
| **CardService** | DealCard, RevealCard, MuckCard, SetBoard, GetDeck |
| **DisplayService** | ShowOverlay, HideOverlay, SetSkin, SetLayout, ToggleTrust |
| **MediaService** | PlayVideo, PlayAudio, SetLogo, SetTicker, CaptureFrame |

### UDP Discovery

클라이언트가 서버를 자동으로 찾는 메커니즘:

```
Client                              Server
  │  UDP Broadcast (:9000)            │
  │  "POKERGFX_DISCOVER"              │
  │──────────────────────────────────►│
  │  UDP Response (:9001)             │
  │  {name, ip, port, version}        │
  │◄──────────────────────────────────│
  │  TCP Connect (:8888)              │
  │──────────────────────────────────►│
  │  TLS Handshake + Auth             │
  │◄─────────────────────────────────►│
  │  GameInfoResponse (전체 상태)      │
  │◄──────────────────────────────────│
```

### Master-Slave 구성

대형 방송에서 여러 서버를 연결하여 부하를 분산한다:
- **Master**: 게임 상태 관리, RFID 제어, 이벤트 발행 (단일 원본)
- **Slave**: 렌더링 전담, Master 상태 Delta Sync로 미러링

> 전체 113+ 프로토콜 명령 목록은 [부록 B](#부록-b-113-프로토콜-명령-카탈로그) 참조.

---

## 21. 비디오 파이프라인

Server는 비디오 입출력도 관리한다. PokerGFX가 단순한 데이터 시스템이 아니라 **방송 프로덕션 도구**이기도 하다는 것을 의미한다.

![방송 카메라 장비 — 4K 지브 카메라와 모니터가 포커 테이블을 촬영한다](03_Reference_ngd/web_screenshots/pokercaster-broadcast-setup.webp)
> *포커 방송 프로덕션 현장. 4K 지브 카메라, SEETEC 모니터, 조명 장비가 포커 테이블을 중심으로 배치된다. (출처: pokercaster.com)*

### 입력 (Sources 탭)

| 입력 소스 | 용도 |
|-----------|------|
| 로컬 캡처 장치 | 카메라 영상 직접 입력 |
| 네트워크 카메라 | IP 기반 원격 카메라 |
| 외부 스위처 (ATEM) | Blackmagic ATEM과 직접 통신 |

카메라 제어 기능:
- **Auto Camera**: 게임 상태에 따라 카메라 자동 전환
- **Board Cam Hide GFX**: 보드 카메라로 전환 시 GFX 자동 숨김
- **Heads Up Split**: 헤즈업 시 화면 자동 분할

### 출력 (Outputs 탭)

| 출력 | 용도 |
|------|------|
| NDI | 네트워크 기반 비디오 출력 (방송 스위처 연결) |
| HDMI / SDI | 물리 비디오 출력 |
| 녹화 | 로컬 파일 저장 |
| Split Recording | 핸드별 자동 분할 녹화 |

---

## 22. 보안: Dual Canvas

포커는 정보 비대칭 게임이다. 홀카드 정보가 실시간으로 유출되면 게임의 무결성이 파괴된다. 따라서 방송 시스템 자체에 보안 딜레이가 내장되어야 한다.

![보안 모드 비교](01_Mockups_ngd/pokergfx-security-modes.png)

### Trustless Mode (보안 모드)

```
카드 감지 → Server 수신 → 딜레이 버퍼 (1~30분) → 방송 화면 표시
                              ↕
               운영자 화면에는 즉시 표시
```

- 방송 화면에 카드 정보가 **설정된 딜레이 후** 표시된다
- 운영자의 Action Tracker에는 **즉시** 표시된다
- Live Canvas에는 어떤 상황에서도 홀카드를 표시하지 않는다
- Showdown이 끝난 후에만 Live에 카드가 공개된다
- 딜레이는 1분~30분 범위에서 동적으로 조절 가능하다

### Realtime Mode (실시간 모드)

```
카드 감지 → Server 수신 → 즉시 전달 → 방송 화면 표시
```

- 카드 정보가 **즉시** 방송 화면에 표시된다
- 방송 자체에 충분한 딜레이(보통 30분 이상)가 확보된 경우 사용한다
- 또는 녹화 방송에 사용한다

### 모드 전환

Server 메인 화면의 **Secure Delay** 체크박스로 전환한다. 방송 도중에도 전환 가능하며, 현재 모드는 Action Tracker와 Server 화면 모두에 인디케이터로 표시된다.

---

# Part VII: 운영

## 23. 방송 준비 워크플로우

방송 시작 전 3명의 담당자가 순차적으로 시스템을 준비한다.

| 단계 | 담당 | 확인 항목 | 정상 기준 |
|:----:|------|----------|----------|
| 1 | 시스템 관리자 | 서버 시작 + 라이선스 | 라이선스 활성 상태 |
| 2 | 방송 감독 | 게임 유형 선택 | 22개 중 1개 선택 |
| 3 | 방송 감독 | 스킨 로드 | .vpt/.skn 로드 성공, 미리보기 정상 |
| 4 | 방송 감독 | RFID 리더 연결 | 12대 전체 `reader_state = ok` |
| 5 | 방송 감독 | 출력 장치 설정 | NDI/HDMI/SDI 출력 정상 |
| 6 | 방송 감독 | Dual Canvas 확인 | Live + Delayed 캔버스 모두 동작 |
| 7 | 방송 감독 | Trustless 모드 | Live Canvas에 홀카드 숨김 확인 |
| 8 | GFX 운영자 | 클라이언트 연결 | Action Tracker, Commentary Booth 접속 |
| 9 | GFX 운영자 | 테스트 스캔 | 카드 1장 → 200ms 내 화면 표시 |

---

## 24. 게임 진행 워크플로우

### 핸드별 반복 루프

```
SETUP_HAND ──► PRE_FLOP ──┬──────────────────────
                           │
   Community Card (13개) ──┼──► FLOP → TURN → RIVER
                           │
   Draw (7개) ─────────────┼──► DRAW_ROUND (1~3회 반복)
                           │
   Stud (3개) ─────────────┼──► 3rd → 4th → 5th → 6th → 7th STREET
                           │
                           └──► SHOWDOWN → HAND_COMPLETE
```

### 특수 상황 분기

| 상황 | 발생 시점 | 처리 |
|------|----------|------|
| **Bomb Pot** | Pre-Flop 직전 | 전원 강제 납부 → Flop 직행 |
| **Run It Twice** | All-in 후 | 보드 2회 전개, 팟 절반 분할 |
| **Miss Deal** | 카드 배분 오류 | 현재 핸드 무효화, 카드 재분배 |

---

## 25. 긴급 상황 복구

### 장애 유형별 대응

| 장애 | 복구 조치 | 결과 |
|------|----------|------|
| RFID 미인식 | 수동 카드 입력 GUI | 정상 진행 |
| 네트워크 끊김 | 자동 재연결 (KeepAlive) | 30초 이내 복구 |
| 렌더링 오류 | 긴급 중지 → 서버 재시작 | 모든 GFX 숨김 |
| 잘못된 카드 인식 | 카드 제거 → 재입력 | 올바른 카드 반영 |
| 서버 크래시 | 게임 상태 자동 복원 (GAME_SAVE) | 마지막 저장점에서 재개 |

### 수동 카드 입력 폴백

RFID 인식 실패 시, GFX 운영자가 GUI에서 직접 카드를 선택한다:
- 4개 Suit x 13개 Rank = 52장 그리드
- 이미 사용된 카드는 선택 불가 (시각적 비활성)
- 좌석 선택 → 카드 클릭 → 적용

---

## 26. 핸드 히스토리

시스템은 모든 핸드의 전체 데이터를 저장한다.

### 저장되는 데이터

| 데이터 | 내용 |
|--------|------|
| 핸드 메타 | 핸드 번호, 시간, 게임 타입, 블라인드 |
| 플레이어 | 이름, 좌석, 시작 스택, 최종 스택 |
| 홀카드 | 각 플레이어의 홀카드 |
| 액션 | 매 스트리트별 모든 액션 (Fold/Check/Call/Bet/Raise/All-In + 금액) |
| 보드 | Flop/Turn/River 카드 |
| 결과 | 승자, 팟 분배 |

### 활용

| 기능 | 설명 |
|------|------|
| **핸드 리플레이** | 과거 핸드를 액션별로 재생 |
| **필터 검색** | 날짜, 플레이어, 팟 사이즈, 태그로 검색 |
| **Export** | 개별 핸드 또는 전체 세션을 CSV/JSON으로 내보내기 |
| **공유 링크** | 특정 핸드를 URL로 공유 |
| **통계 소스** | 플레이어 통계 계산의 원본 데이터 |

---

# 부록

## 부록 A: 22개 게임 전체 카탈로그

### Community Card 계열 (13개)

| # | 게임명 | 홀카드 | 보드 | 특수 규칙 |
|:-:|--------|:------:|:----:|----------|
| 0 | Texas Hold'em | 2장 | 5장 | 표준 |
| 1 | 6+ Hold'em (Straight > Trips) | 2장 | 5장 | 36장 덱, Straight > Trips |
| 2 | 6+ Hold'em (Trips > Straight) | 2장 | 5장 | 36장 덱, Trips > Straight |
| 3 | Pineapple | 3→2장 | 5장 | Flop 전 1장 버림 |
| 4 | Omaha | 4장 | 5장 | 반드시 홀카드 2장 + 보드 3장 사용 |
| 5 | Omaha Hi-Lo | 4장 | 5장 | Hi/Lo 팟 분할 (8-or-better) |
| 6 | Five Card Omaha | 5장 | 5장 | 홀카드 2장 + 보드 3장 사용 |
| 7 | Five Card Omaha Hi-Lo | 5장 | 5장 | Hi/Lo 분할 |
| 8 | Six Card Omaha | 6장 | 5장 | 홀카드 2장 + 보드 3장 사용 |
| 9 | Six Card Omaha Hi-Lo | 6장 | 5장 | Hi/Lo 분할 |
| 10 | Courchevel | 5장 | 5장 | Pre-Flop에 Flop 첫 카드 공개 |
| 11 | Courchevel Hi-Lo | 5장 | 5장 | Hi/Lo + 첫 카드 공개 |

> 주: 12번 인덱스는 Community Card 내 추가 변형으로 예약

### Draw 계열 (7개)

| # | 게임명 | 카드 | 교환 | 특수 규칙 |
|:-:|--------|:----:|:----:|----------|
| 12 | Five Card Draw | 5장 | 1회 | 기본 Draw |
| 13 | 2-7 Single Draw | 5장 | 1회 | Lowball (A=High) |
| 14 | 2-7 Triple Draw | 5장 | 3회 | Lowball 3회 교환 |
| 15 | A-5 Triple Draw | 5장 | 3회 | A-5 Lowball |
| 16 | Badugi | 4장 | 3회 | 4 suit 다른 조합 |
| 17 | Badeucy | 5장 | 3회 | Badugi + 2-7 혼합 |
| 18 | Badacey | 5장 | 3회 | Badugi + A-5 혼합 |

### Stud 계열 (3개)

| # | 게임명 | 카드 | 베팅 라운드 | 특수 규칙 |
|:-:|--------|:----:|:----------:|----------|
| 19 | 7-Card Stud | 7장 | 5 | 3장 비공개 + 4장 공개 |
| 20 | 7-Card Stud Hi-Lo | 7장 | 5 | Hi/Lo 분할 (8-or-better) |
| 21 | Razz | 7장 | 5 | A-5 Lowball Stud |

---

## 부록 B: 113+ 프로토콜 명령 카탈로그

### 9개 카테고리

| 카테고리 | 수량 | 설명 |
|----------|:----:|------|
| Connection | 9 | 서버 연결/인증/상태 (CONNECT, DISCONNECT, AUTH, KEEPALIVE, HEARTBEAT 등) |
| Game | 10 | 게임 시작/종료/타입 변경 (GAME_INFO, NEW_HAND, END_HAND, GAME_TYPE 등) |
| Player | 21 | 좌석/칩/통계 (PLAYER_INFO, PLAYER_CARDS, PLAYER_BET, PLAYER_ACTION 등) |
| Cards | 6 | 카드 딜/공개/Muck (BOARD_CARD, CARD_VERIFY, FORCE_CARD_SCAN 등) |
| Display | 13 | 오버레이/레이아웃 (GFX_ENABLE, FIELD_VISIBILITY, ACTION_CLOCK 등) |
| Media | 9 | 비디오/오디오/로고 (MEDIA_PLAY, CAM, PIP, CAP 등) |
| Betting | 5 | 베팅 액션/팟 (PAYOUT, MISS_DEAL, CHOP, FORCE_HEADS_UP 등) |
| Data | 4 | 설정 동기화 (SKIN_CHUNK, COMM_DL, AT_DL, VTO) |
| History | 5 | 핸드 이력/리플레이 (HAND_HISTORY, HAND_LOG, READER_STATUS 등) |
| **합계** | **82+** | + 31개 내부 명령 = **113+** |

### 16개 실시간 이벤트

서버가 클라이언트에 Push하는 이벤트: OnCardDetected, OnCardRemoved, OnBetAction, OnPotUpdated, OnHandComplete, OnGameStateChanged, OnPlayerAdded, OnPlayerRemoved, OnChipsUpdated, OnWinProbabilityUpdated, OnSkinChanged, OnOverlayToggled, OnTrustlessModeChanged, OnTimerStarted, OnTimerExpired, OnConnectionStatusChanged.

### GameInfoResponse: 단일 상태 메시지 (75+ 필드)

- Game Info: game_type, game_state, hand_number, button_seat, blinds, ante
- Player Info (x10): name, chips, seat, hole_cards, status, bet_amount, win_probability, hand_rank, stats
- Board Info: board_cards, pot_total, side_pots
- Display Info: skin_name, trustless_mode, delay_seconds, overlay_visible

---

## 부록 C: 151개 기능 카탈로그

### 우선순위 분포

| 우선순위 | 수량 | 설명 |
|----------|:----:|------|
| **P0 (핵심)** | 85개 | MVP에 필수. 이것 없이 시스템 작동 불가 |
| **P1 (확장)** | 48개 | 프로 방송에 필요. 첫 릴리스 후 추가 |
| **P2 (고급)** | 18개 | 고급 기능. 요구 시 구현 |

### 11개 화면 기능 분포

| 화면 | P0 | P1 | P2 | 합계 |
|------|:--:|:--:|:--:|:----:|
| Main Window | 6 | 4 | 0 | **10** |
| Sources | 4 | 3 | 3 | **10** |
| Outputs | 6 | 2 | 4 | **12** |
| GFX1 (게임 제어) | 15 | 7 | 2 | **24** |
| GFX2 (통계) | 1 | 8 | 4 | **13** |
| GFX3 (방송 연출) | 2 | 7 | 4 | **13** |
| Commentary | 4 | 3 | 0 | **7** |
| System | 10 | 6 | 0 | **16** |
| Skin Editor | 11 | 4 | 1 | **16** |
| GE Board | 15 | 0 | 0 | **15** |
| GE Player | 11 | 4 | 0 | **15** |
| **합계** | **85** | **48** | **18** | **151** |

> 개별 기능의 상세 설명과 우선순위: [PokerGFX Feature Checklist](PokerGFX-Feature-Checklist.md)
> 각 화면의 스크린샷과 UI 요소 분석: [PokerGFX UI Analysis](PokerGFX-UI-Analysis.md)

---

## 부록 D: 용어 사전

### 포커 용어

| 용어 | 설명 |
|------|------|
| **Hole Card** | 플레이어에게 비공개로 배분되는 카드 |
| **Community Card** | 테이블 중앙에 공개되는 공유 카드 |
| **Flop** | 커뮤니티 카드 3장 동시 공개 |
| **Turn** | 4번째 커뮤니티 카드 |
| **River** | 5번째(마지막) 커뮤니티 카드 |
| **Showdown** | 남은 플레이어들의 카드 공개, 승자 결정 |
| **Fold** | 패를 포기하고 핸드에서 이탈 |
| **Call** | 현재 베팅 금액과 동일하게 베팅 |
| **Raise** | 현재 베팅보다 높게 베팅 |
| **All-in** | 보유 칩 전부 베팅 |
| **Check** | 베팅 없이 차례 넘김 |
| **Blind** | 매 핸드 강제 납부 (SB/BB) |
| **Ante** | 매 핸드 전원 강제 납부 소액 |
| **Pot** | 해당 핸드 누적 총 베팅 금액 |
| **Side Pot** | All-in 플레이어와 나머지 간 별도 팟 |
| **Button** | 딜러 위치 마커 (매 핸드 시계방향 이동) |
| **Muck** | 카드를 공개하지 않고 포기 |
| **Outs** | 핸드를 완성시킬 수 있는 남은 카드 수 |

### 베팅 용어

| 용어 | 설명 |
|------|------|
| **No Limit** | 레이즈 금액 상한 없음 |
| **Fixed Limit** | 정해진 단위로만 베팅/레이즈 |
| **Pot Limit** | 팟 크기 이하로만 레이즈 |
| **Straddle** | 자발적 블라인드 추가 (보통 2x BB) |
| **Bomb Pot** | 전원 납부 후 Pre-Flop 건너뛰고 Flop |
| **Run It Twice** | All-in 후 보드 2회 전개, 팟 분할 |
| **7-2 Side Bet** | 7-2로 이기면 사이드벳 수취 |

### 통계 용어

| 용어 | 설명 |
|------|------|
| **VPIP** | Voluntarily Put $ In Pot — 자발적 팟 참여율 |
| **PFR** | Pre-Flop Raise — Pre-Flop 레이즈 비율 |
| **AF** | Aggression Factor — 공격성 지수 |
| **WTSD** | Went To Showdown — 쇼다운까지 간 비율 |
| **ICM** | Independent Chip Model — 칩 기반 토너먼트 가치 |
| **Equity** | 현재 상태에서의 팟 지분 비율 |

### 시스템 용어

| 용어 | 설명 |
|------|------|
| **Dual Canvas** | Live + Delayed 두 개의 독립 렌더링 화면 |
| **Live Canvas** | 실시간 현장 모니터용 (홀카드 숨김) |
| **Delayed Canvas** | N초 지연 방송 송출용 (홀카드 공개) |
| **Trustless Mode** | Live에서 홀카드를 절대 표시하지 않는 보안 모드 |
| **NDI** | Network Device Interface — 네트워크 비디오 전송 프로토콜 |
| **RFID** | Radio Frequency Identification — 무선 주파수 식별 |
| **NTAG215** | NFC Forum Type 2 태그 규격 (카드 내장) |
| **Skin** | 방송 그래픽의 시각적 테마 패키지 (.vpt/.skn) |
| **Master-Slave** | 다중 서버 구성. Master=원본, Slave=동기화 |
| **Action Tracker** | 딜러용 터치스크린 게임 진행 앱 |
| **Commentary Booth** | 해설자용 홀카드+승률 실시간 뷰어 |
| **Monte Carlo** | 무작위 시뮬레이션 기반 확률 계산 |
| **PocketHand169** | Pre-Flop 2장 조합의 169개 전략적 분류 |
| **Lookup Table** | 사전 계산된 O(1) 조회 테이블 |
| **ATEM** | Blackmagic Design 비디오 스위처 |
| **StreamDeck** | Elgato 물리 버튼 매크로 장치 |

---

## 부록 E: 참고 자료

### 포커 방송 역사

- [Hole cam — Wikipedia](https://en.wikipedia.org/wiki/Hole_cam)
- [Who Invented The Poker Hole Cam? — casino.org](https://www.casino.org/blog/hole-card-cam/)
- [Poker on television — Wikipedia](https://en.wikipedia.org/wiki/Poker_on_television)

### PokerGFX 및 경쟁 제품

- [PokerGFX Official](https://www.pokergfx.io/)
- [PokerGFX market dominance — habwin.com](https://www.habwin.com/en/post/poker-gfx-what-it-is-and-how-it-can-combat-security-vulnerabilities)
- [wTVision RFID Implementation for EPT](https://www.wtvision.com/pokerstarsit-tournament-rfid-table-and-cards-system-used-for-the-first-time-on-a-broadcast)

### RFID 기술

- [Application of RFID playing cards in WSOP — rfidcard.com](https://www.rfidcard.com/application-of-rfid-playing-cards-in-wsop/)
- [The Evolution of Poker Livestreaming — rfpoker.com](https://rfpoker.com/blog/the-evolution-of-poker-livestreaming)
- [NXP NTAG215 Poker Cards — in2tags.com](https://in2tags.com/product/poker-card/nxp-ntag215)

### 시장 규모

- [Online Poker Market Report — Grand View Research](https://www.grandviewresearch.com/industry-analysis/online-poker-market-report)
- [Live Streaming Market Size — Yahoo Finance](https://finance.yahoo.com/news/live-streaming-market-size-surpass-073900911.html)
- [WSOP 2024 record — poker.org](https://www.poker.org/latest-news/8-reasons-why-wsop-2024-could-be-the-biggest-poker-series-ever-aymQt0s3jal2/)

### 방송 플랫폼

- [Hustler Casino Live — poker.org](https://www.poker.org/poker-streams/hustler-casino-live/)
- [WSOP Livestreaming with Hole Cards — wsop.com](https://www.wsop.com/news/wsop-livestreaming-all-summer-with-hole-cards-and-commentary/)

### DIY/오픈소스

- [DIY RFID Table — Poker Chip Forum](https://www.pokerchipforum.com/threads/experimenting-with-a-diy-rfid-table-and-broadcast-overlay.88715/)
- [Arduino RFID Poker Project](https://forum.arduino.cc/t/rfid-nfc-poker-table-card-reader-project/541409)

---

## 부록 F: 다이어그램 목록

### 본 문서에서 참조하는 시각 자료

| 다이어그램 | 파일 | 설명 |
|-----------|------|------|
| 시스템 모듈 구조 | `01_Mockups_ngd/pokergfx-module-overview.png` | 6개 모듈 허브-스포크 구조 |
| 핸드 생명주기 시퀀스 | `01_Mockups_ngd/pokergfx-hand-lifecycle.png` | RFID 태그 → NDI/ATEM 출력 8단계 |
| 보안 모드 비교 | `01_Mockups_ngd/pokergfx-security-modes.png` | Trustless vs Realtime |
| Action Tracker | `01_Mockups_ngd/13-action-tracker-wireframe.png` | 운영자 인터페이스 와이어프레임 |
| Viewer Overlay | `01_Mockups_ngd/14-viewer-overlay-wireframe.png` | 시청자 화면 와이어프레임 |
| Server 메인 화면 | `01_Mockups_ngd/01-main-window.png` | Server 앱 메인 UI |
| Skin Editor | `01_Mockups_ngd/09-skin-editor.png` | 테마 에디터 |
| Graphic Editor (Board) | `01_Mockups_ngd/10-graphic-editor-board.png` | 보드 그래픽 편집 |
| Graphic Editor (Player) | `01_Mockups_ngd/11-graphic-editor-player.png` | 플레이어 그래픽 편집 |

### 웹 수집 참조 이미지

| 이미지 | 파일 | 출처 |
|--------|------|------|
| WPT 홀카메라 방송 | `03_Reference_ngd/web_screenshots/hole-card-cam-history.jpeg` | casino.org |
| WSOP Paradise RFID 방송 | `03_Reference_ngd/web_screenshots/wsop-paradise-2025-rfid-broadcast.png` | WSOP/PokerGO |
| PokerGFX 스튜디오 테이블 | `03_Reference_ngd/web_screenshots/pokergfx-overview.jpg` | habwin.com |
| RFID IC 회로 | `03_Reference_ngd/web_screenshots/rfid-live-poker-event.jpg` | habwin.com |
| RFID 센서 보드 | `03_Reference_ngd/web_screenshots/rfid-sensor-board-table.png` | macaumr.com |
| 실제 방송 오버레이 | `03_Reference_ngd/web_screenshots/pokercaster-broadcast-overlay.webp` | pokercaster.com |
| DIY RFID 오버레이 | `03_Reference_ngd/web_screenshots/diy-rfid-poker-table-thumbnail.jpg` | YouTube |
| 방송 카메라 장비 | `03_Reference_ngd/web_screenshots/pokercaster-broadcast-setup.webp` | pokercaster.com |

### 역설계 레포 참조 다이어그램

아래 다이어그램은 `ebs_reverse` 레포에서 관리한다. 코드 레벨 상세를 포함하므로 기획 문서 범위 밖이다:

- `pokergfx-system-architecture.png` — 전체 시스템 아키텍처
- `pokergfx-service-pipeline.png` — 서비스 파이프라인
- `pokergfx-graphics-hierarchy.png` — 그래픽 계층 구조
- `pokergfx-network-protocol.png` — 네트워크 프로토콜 상세
- `pokergfx-rfid-subsystem.png` — RFID 서브시스템
- PRD 다이어그램 10장 (`images/prd/prd-*.png`) — 3계층 아키텍처, Dual Canvas, 7개 앱 생태계, RFID 테이블 레이아웃 등

> 역공학 상세: `ebs_reverse/docs/02-design/pokergfx-reverse-engineering-complete.md`
> 기술 설계 상세: `ebs_reverse/docs/02-design/features/pokergfx.design.md`

---

## 변경 이력

| 버전 | 날짜 | 변경 내용 |
|------|------|-----------|
| 9.1.0 | 2026-02-16 | Section 16 Action Tracker 실제 스크린샷 6장 추가 |
| 9.0.0 | 2026-02-16 | **ebs + ebs_reverse PRD 통합**: Executive Summary/성공 지표 추가, Part I 시장 배경 전면 보강 (시장 규모, 경쟁 분석, 자체 개발 당위성), Dual Canvas 핵심 개념 추가, 7개 앱 생태계/5가지 사용자 역할 추가, 22개 포커 게임 카탈로그 추가, 베팅 시스템 (7 Ante + 4 특수 규칙) 추가, 핸드 평가 엔진 (LUT O(1)) 추가, GPU 5-Thread 렌더링 파이프라인 추가, 4계층 네트워크 프로토콜 (5 gRPC + 113+ 명령) 추가, 방송 준비/긴급 복구 워크플로우 추가, 151개 기능 카탈로그 (P0/P1/P2) 추가, 용어 사전 + 참고 자료 추가 |
| 8.3.0 | 2026-02-16 | EBS 미확정 기술 비교 자료 삭제 |
| 8.2.0 | 2026-02-16 | Section 1 WSOP Paradise 2025 스크린샷 추가 |
| 8.1.0 | 2026-02-15 | ATEM Switcher 모듈 추가, 핸드 생명주기 시퀀스 다이어그램 추가 |
| 8.0.0 | 2026-02-15 | 웹 리서치 기반 참조 이미지 7장 삽입 |
| 7.0.0 | 2026-02-15 | 카드 인식 기술 관점 전면 재설계, RFID를 "현재 구현"으로 재프레이밍 |

---

**Version**: 9.1.0 | **Updated**: 2026-02-16
