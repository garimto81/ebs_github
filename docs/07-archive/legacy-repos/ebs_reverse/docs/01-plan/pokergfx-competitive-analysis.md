# 포커 방송 시스템 경쟁 환경 분석

> **Version**: 1.0.0
> **Date**: 2026-02-16
> **문서 유형**: 경쟁 환경 분석 (Competitive Landscape Analysis)
> **관련 문서**: pokergfx-prd-v2.md (Master PRD)

---

## Executive Summary

포커 방송용 카드 인식 기술은 세 가지 접근법으로 나뉜다. **RFID 기반**, **Computer Vision 기반**, 그리고 **하이브리드**. 상용 시스템인 PokerGFX는 RFID 전용 아키텍처를 채택했고, 커뮤니티에서는 세 접근법 모두를 활용한 다양한 프로젝트가 진행되고 있다.

### 오픈소스 현황 요약

| 영역 | 프로젝트 수 | 완성도 | 대표 프로젝트 |
|------|------------|--------|--------------|
| **RFID DIY** | 4개 주요 프로젝트 | Beta~Production | whywaita/rfid-poker (유일한 전체 공개) |
| **Arduino/RPi RFID** | 3개+ | Prototype | Raserber/application-visualisation-cartes-poker |
| **Computer Vision** | 15개+ | Research~Beta | cadyze/card-vision (YOLOv8, mAP 90%) |

RFID 방식은 정확도(99%+)와 신뢰성에서 우위를 점하지만 전용 하드웨어가 필요하다. Computer Vision은 표준 카드를 사용할 수 있지만 조명 조건과 카메라 앵글에 민감하다. 현재까지 PokerGFX 수준의 22개 게임 변형 지원, GPU 렌더링, 다중 앱 동기화를 구현한 오픈소스 프로젝트는 존재하지 않는다.

---

## 목차

1. [Executive Summary](#executive-summary)
2. [RFID 기반 DIY 프로젝트](#2-rfid-기반-diy-프로젝트)
3. [Arduino/Raspberry Pi RFID 프로젝트](#3-arduinoraspberry-pi-rfid-프로젝트)
4. [Computer Vision 기반 카드 인식](#4-computer-vision-기반-카드-인식)
5. [기술 비교 매트릭스](#5-기술-비교-매트릭스)
6. [PokerGFX 차별화 요소 분석](#6-pokergfx-차별화-요소-분석)
7. [시사점 및 전략적 권고](#7-시사점-및-전략적-권고)
8. [Source Links](#8-source-links)

---

# 2. RFID 기반 DIY 프로젝트

## 2.1 Poker Chip Forum DIY RFID Table

커뮤니티 기반 RFID 포커 테이블 프로젝트 중 가장 규모가 크고 상세한 하드웨어 설계 정보를 제공한다. 88 페이지에 달하는 포럼 스레드에서 2019년부터 2024년 이후까지 지속적으로 개발이 진행되었다.

**Forum Thread**: https://www.pokerchipforum.com/threads/experimenting-with-a-diy-rfid-table-and-broadcast-overlay.88715/

### 기술 스택

| 계층 | 초기 (v1) | 현재 (v2) |
|------|----------|----------|
| **Backend** | Node.js | Go (rewrite) |
| **Frontend** | Angular | HTML/CSS/JS (경량화) |
| **MCU** | ESP32 | ESP32 (유지) |
| **RFID Chip** | ST25R95 | ST25R95 (유지) |
| **통신** | WiFi → HTTPS + WebSocket | WiFi → HTTPS + WebSocket |

### 하드웨어 설계

이 프로젝트의 핵심 가치는 하드웨어 설계에 있다. 상용 시스템에 근접한 안테나 멀티플렉싱을 DIY 수준에서 구현했다.

| 구성요소 | 사양 |
|---------|------|
| **안테나** | 13개 (플레이어 10 + 보드 2 + 머크 1) |
| **멀티플렉서** | ADG1607 / NX3L4051 아날로그 MUX |
| **PCB** | Custom PCB 설계 |
| **MCU** | ESP32 (WiFi 내장) |
| **RFID** | ST25R95 (ISO14443A/B, ISO15693) |

### 아키텍처

```
┌─────────┐     WiFi      ┌──────────┐    WebSocket    ┌──────────┐
│  ESP32  │──────────────→│ Go Server│───────────────→│ Browser  │
│ ST25R95 │   HTTPS/WS    │  (HTTPS) │                │(Chroma)  │
│ 13 Ant. │               └──────────┘                └────┬─────┘
│ ADG1607 │                                                │
└─────────┘                                           ┌────▼─────┐
                                                      │   OBS    │
                                                      │ (Overlay)│
                                                      └──────────┘
```

### 현황

- **Status**: Beta (Node/Angular 버전 동작), Go rewrite 진행 중
- **GitHub**: 아직 미공개 (공개 예정)
- **강점**: 안테나 멀티플렉싱 설계가 상용 시스템에 가장 근접
- **약점**: 코드 비공개, Hold'em 전용

---

## 2.2 whywaita/rfid-poker

현재까지 유일하게 **전체 소스코드가 공개**된 완전한 RFID 포커 시스템이다. 하드웨어 펌웨어부터 웹 프론트엔드까지 수직 통합되어 있다.

**GitHub**: https://github.com/whywaita/rfid-poker

### 기술 스택 구성비

| 언어 | 비율 | 용도 |
|------|------|------|
| Go | 61.8% | 백엔드 서버, API, 게임 로직 |
| TypeScript/Next.js | 22.2% | 웹 프론트엔드 |
| C++ (M5Stack) | 13.7% | RFID 리더 펌웨어 |
| 기타 | 2.3% | Docker, Config |

### 하드웨어

| 구성요소 | 모듈 | 사양 |
|---------|------|------|
| **MCU** | M5Stack Core2 | ESP32 기반, LCD 내장 |
| **RFID** | Unit RFID2 (WS1850S) | 13.56MHz, ISO14443A |
| **카드** | MIFARE Ultralight EV1 | NFC 태그 부착 |
| **인터페이스** | I2C | M5Stack ↔ RFID2 |

### API 설계

| Endpoint | Method | 용도 |
|----------|--------|------|
| `/ws` | GET | WebSocket 실시간 카드 데이터 |
| `/device/boot` | POST | RFID 디바이스 등록 |
| `/card` | POST | 카드 인식 이벤트 전송 |

### 설정

- **UID 매핑**: 설정 파일에서 RFID UID와 카드(Suit + Rank) 매핑
- **데이터베이스**: MySQL
- **배포**: Docker 지원

### 현황

| 항목 | 내용 |
|------|------|
| Commits | 190+ |
| Status | Active development |
| Game Support | Texas Hold'em |
| License | 공개 |

**참고 의의**: 유일한 전체 공개 시스템으로, EBS 구현 시 RFID-서버-프론트엔드 통합 패턴의 1차 참고 대상이다.

---

## 2.3 Smart Poker Table (Ivo Ovcharov)

$300 미만의 예산으로 가정용 포커 방송 시스템을 구축한 1인 프로젝트. Hacker News에서 주목받았다.

**Website**: https://www.smartpokertable.com / https://www.rfidpokertable.com/
**Portfolio**: https://www.ivodev.com/project/smartpokertable

### 사양

| 항목 | 내용 |
|------|------|
| **총 비용** | < $300 |
| **Backend** | Node.js |
| **Hardware Controller** | Arduino |
| **외부 제어** | Elgato Stream Deck |
| **데모 영상** | https://www.youtube.com/watch?v=5QU8MC7q8FQ |

### 미디어 노출

| 플랫폼 | 링크 | 시기 |
|---------|------|------|
| Show HN | https://news.ycombinator.com/item?id=40528317 | 2024년 6월 |
| Show HN | https://news.ycombinator.com/item?id=40289142 | 2024년 5월 |

### 현황

- **GitHub**: 소스 비공개
- **강점**: 극저가 구현, Stream Deck 통합으로 딜러 UX 우수
- **약점**: 소스 비공개, 확장성 제한

---

## 2.4 Supporting Libraries

### RFID/NFC 라이브러리

| Repository | Tech | 용도 | Stars |
|-----------|------|------|-------|
| [pokusew/nfc-pcsc](https://github.com/pokusew/nfc-pcsc) | Node.js | ACR122 USB NFC 리더 제어 | - |
| [esprfid/esp-rfid](https://github.com/esprfid/esp-rfid) | ESP8266 | RC522/PN532/Wiegand + WebSocket | - |
| [miguelbalboa/rfid](https://github.com/miguelbalboa/rfid) | Arduino | MFRC522 라이브러리 | 4k+ |
| [stm32duino/ST25R95](https://github.com/stm32duino/ST25R95) | STM32 | ST25R95 NFC RFAL 스택 | - |
| [QuentinCG/Arduino-RFID-Card-Reader-Library](https://github.com/QuentinCG/Arduino-RFID-Card-Reader-Library) | Arduino | 125KHz RFID 리더 | - |

### 핸드 평가 라이브러리

| Repository | Language | Algorithm | 비고 |
|-----------|----------|-----------|------|
| [zekyll/OMPEval](https://github.com/zekyll/OMPEval) | C++ | Monte Carlo + Full Enumeration | 고성능 |
| [HenryRLee/PokerHandEvaluator](https://github.com/HenryRLee/PokerHandEvaluator) | C++ | Perfect Hash (~100KB 테이블) | 메모리 효율 |
| [kmurf1999/rust_poker](https://github.com/kmurf1999/rust_poker) | Rust | Monte Carlo + Exact | Rust 생태계 |
| [ihendley/treys](https://github.com/ihendley/treys) | Python | 5/6/7 card lookup | 프로토타이핑용 |
| [whywaita/poker-go](https://github.com/whywaita/poker-go) | Go | NLH 전용 | rfid-poker 종속 |
| [uoftcprg/pokerkit](https://github.com/uoftcprg/pokerkit) | Python | Game simulation + analysis | 다변형 지원 |

---

## 2.5 RFID 하드웨어 에코시스템

### 리더 모듈 비교

| 모듈 | 주파수 | 프로토콜 | 인터페이스 | 인식 범위 | 가격 |
|------|--------|----------|-----------|----------|------|
| **MFRC522** | 13.56MHz | ISO14443A | SPI/I2C/UART | 0-3cm | $2-5 |
| **PN532** | 13.56MHz | ISO14443A/ISO15693 | SPI/I2C/HSU | 30-50mm | $10-15 |
| **WS1850S** | 13.56MHz | ISO14443A/ISO15693 | I2C | 0-3cm | $15-20 |
| **ST25R95** | 13.56MHz | ISO14443A/B, ISO15693 | SPI | varies | $5-10 |
| **TRF7960A** | 13.56MHz | Multi-protocol | SPI | varies | TI Ref Design |

**PokerGFX 비교**: SkyeTek 전문 리더를 사용하며, 가격대가 위 모듈들의 10-100배에 달하지만 인식 거리와 안정성에서 압도적이다.

### RFID 카드/태그 옵션

| 유형 | 제품 | 가격 | 보안 수준 |
|------|------|------|----------|
| **상용 RFID 카드** | Faded Spade RFID Deck | $60+/덱 | 높음 |
| **상용 태그** | FM11RF08, MIFARE Classic 1K | $0.30-1.00/장 | 중간 |
| **NFC 스티커** | NTAG213/215, MIFARE Ultralight | $0.10-0.50/장 | 낮음 |
| **고보안 태그** | MIFARE DESFire EV2/EV3 | $1-3/장 | 높음 |

> **보안 경고**: MIFARE Classic은 2024년 Quarkslab 분석에서 하드웨어 레벨 백도어가 발견되었다 (FM11RF08 칩). 방송용으로는 MIFARE DESFire 이상을 권장한다.

---

# 3. Arduino/Raspberry Pi RFID 프로젝트

## 3.1 Raserber/application-visualisation-cartes-poker

프랑스 UGA(Universite Grenoble Alpes) FAME 프로젝트의 교육용 포커 카드 인식 시스템.

**GitHub**: https://github.com/Raserber/application-visualisation-cartes-poker

### 하드웨어

| 구성요소 | 사양 |
|---------|------|
| **MCU** | Arduino UNO R3 |
| **RFID** | RC522 모듈 (1-3대 동시) |
| **통신** | SPI (공유 MOSI/MISO/SCK, 리더별 고유 NSS) |
| **디스플레이** | Electron.js 데스크톱 애플리케이션 |

### SPI 멀티 리더 배선

```
Arduino UNO R3
├── MOSI (Pin 11) ────── 공유 ──── RC522 #1, #2, #3
├── MISO (Pin 12) ────── 공유 ──── RC522 #1, #2, #3
├── SCK  (Pin 13) ────── 공유 ──── RC522 #1, #2, #3
├── SS1  (Pin 10) ────── 전용 ──── RC522 #1
├── SS2  (Pin  9) ────── 전용 ──── RC522 #2
└── SS3  (Pin  8) ────── 전용 ──── RC522 #3
```

### 교육적 가치

SPI 기반 다중 RFID 리더 연결의 기초 패턴을 보여준다. 다만 Arduino UNO의 GPIO 제한(디지털 핀 14개)으로 3대 이상 확장이 어렵다.

---

## 3.2 Bob's Electronics RFID Playing Card Reader

시각 장애인을 위한 접근성 도구로 개발된 RFID 카드 리더.

**Source**: https://bobparadiso.com/2015/07/27/rfid-playing-card-reader/

| 항목 | 내용 |
|------|------|
| **하드웨어** | Raspberry Pi + SPI RFID 리더 |
| **용도** | 시각 장애인용 카드 인식 |
| **핵심 기능** | Google TTS를 통한 카드 음성 안내 |

방송 시스템과 직접적 관련은 적지만, RFID 카드 매핑 및 인식 로직의 단순한 참고 구현으로 활용 가능하다.

---

## 3.3 Multi-Reader 연결 전략

여러 RFID 리더를 하나의 MCU에 연결하는 것은 포커 테이블 구현의 핵심 과제다. 두 가지 주요 방식이 있다.

### SPI Mode

| 항목 | 내용 |
|------|------|
| **공유 라인** | MOSI, MISO, SCK |
| **전용 라인** | Slave Select (SS) — 리더당 1개 GPIO |
| **전류** | 리더당 ~100mA |
| **최대 수** | GPIO 수에 의존 (ESP32: ~20개 가능) |

```
MCU ──── MOSI ──┬── Reader #1  (SS1)
         MISO ──┤── Reader #2  (SS2)
         SCK  ──┤── Reader #3  (SS3)
                ├── ...
                └── Reader #N  (SSN)
```

### I2C Mode (멀티플렉서)

| 항목 | 내용 |
|------|------|
| **멀티플렉서** | TCA9548A (8채널) |
| **최대 확장** | 동일 주소 디바이스 64대 (MUX 8개 cascade) |
| **장점** | 2핀(SDA, SCL)으로 다수 연결 |
| **단점** | SPI 대비 속도 저하 |

```
MCU ── I2C ── TCA9548A ──┬── Ch0: RFID Reader #1
                         ├── Ch1: RFID Reader #2
                         ├── Ch2: RFID Reader #3
                         ├── ...
                         └── Ch7: RFID Reader #8
```

### 주의사항

저가 MFRC522 모듈은 SPI MISO 라인을 제대로 해제하지 않는 문제가 보고되었다. 해결 방법:

1. **버퍼 IC 추가**: 74HC125 등 tri-state 버퍼로 MISO 라인 격리
2. **아날로그 MUX 사용**: ADG1607(Poker Chip Forum 방식)으로 안테나 레벨에서 멀티플렉싱
3. **모듈 교체**: PN532 등 SPI 표준을 올바르게 구현하는 모듈 사용

---

## 3.4 안테나 설계 참고 자료

포커 테이블용 커스텀 안테나 설계 시 참고할 주요 자료:

| 자료 | 출처 | 내용 |
|------|------|------|
| **SLOA167** | Texas Instruments | TRF7960A RFID 멀티플렉서 구현 예제 |
| **TomPaynter/RFID_Antenna** | [GitHub](https://github.com/TomPaynter/RFID_Antenna) | TI SLOA135A 기반 KiCAD PCB 안테나 설계 |
| **AN2866** | STMicroelectronics | 13.56MHz 커스텀 안테나 설계 가이드 |

### 안테나 설계 핵심 파라미터

| 파라미터 | 권장 값 | 비고 |
|---------|---------|------|
| **인덕턴스** | 1-1.5uH | 리더 칩 매칭 네트워크 기준 |
| **공진 주파수** | 13.56MHz 약간 상회 | 카드 로딩 효과 보상 |
| **Q Factor** | 20-40 | 너무 높으면 대역폭 부족 |
| **안테나 크기** | 카드 크기(85x54mm) 이상 | 커플링 면적 확보 |

---

# 4. Computer Vision 기반 카드 인식

## 4.1 PokerVision 프로젝트

전통적 Computer Vision 기법으로 포커 카드를 인식하는 프로젝트.

| Repository | Tech | 기능 | Status |
|-----------|------|------|--------|
| [wb-08/PokerVision](https://github.com/wb-08/PokerVision) | Python/OpenCV | PokerStars 테이블 인식, 분석 | 48 stars, 19 forks |
| [MemDbg/poker-vision](https://github.com/MemDbg/poker-vision) | Image + OCR | 평면 위 카드 인식 | - |
| [Loutrinator/VPO-PokerVision](https://github.com/Loutrinator/VPO-PokerVision) | - | 핸드 감지, 승자 판정 | - |

wb-08/PokerVision은 온라인 포커(PokerStars) 화면을 인식하는 도구로, 물리적 카드 인식과는 다른 접근법이다. 라이브 방송 시스템에 직접 적용하기는 어렵지만 OCR 기반 카드 인식 로직을 참고할 수 있다.

---

## 4.2 YOLO 기반 프로젝트

Deep Learning 기반 실시간 객체 탐지 모델(YOLO)을 카드 인식에 적용한 프로젝트들이다. 현재 Computer Vision 카드 인식의 최전선에 해당한다.

| Repository | Model | Dataset | mAP | 비고 |
|-----------|-------|---------|-----|------|
| [cadyze/card-vision](https://github.com/cadyze/card-vision) | YOLOv8 | 6,000+ (augmented) | 90% | **코너 라벨링 혁신** |
| [TeogopK/Playing-Cards-Object-Detection](https://github.com/TeogopK/Playing-Cards-Object-Detection) | YOLOv8m | 20,000 synthetic + real | 95-99% | 5개 모델 비교, RTX A2000 |
| [Stephy-Cheung/Yolov4_project](https://github.com/Stephy-Cheung/Yolov4_project) | YOLOv4 | Custom | - | Blackjack 응용 |
| [MininduLiyanage/Poker-Hand-Identifier](https://github.com/MininduLiyanage/Poker-Hand-Identifier) | YOLOv8+OpenCV | - | - | 포커 전용 모델 |

### cadyze/card-vision 상세

이 프로젝트의 핵심 혁신은 **코너 라벨링(Corner-Only Labeling)**이다. 카드 전체가 아닌 좌상단 코너 영역(Suit + Rank가 표시된 곳)만 bounding box로 라벨링하여, 겹친 카드도 인식할 수 있다.

```
┌──────────────┐
│ ┌──┐         │   ← 코너 영역만 라벨링
│ │A♠│         │      (전체 카드 영역 X)
│ └──┘         │
│              │
│              │
│      ♠       │
│              │
└──────────────┘
```

### TeogopK/Playing-Cards-Object-Detection 상세

5가지 YOLO 모델 변형을 체계적으로 비교한 학술 수준의 프로젝트:

| 모델 | mAP@50 | 추론 속도 | 비고 |
|------|--------|----------|------|
| YOLOv8n | ~95% | 최고속 | 경량 |
| YOLOv8s | ~97% | 고속 | 균형 |
| YOLOv8m | ~99% | 중간 | **최고 정확도** |
| YOLOv8l | ~98% | 저속 | 과적합 경향 |
| YOLOv8x | ~98% | 최저속 | 불필요한 복잡도 |

합성(synthetic) 데이터와 실제 데이터를 혼합한 20,000장 데이터셋이 핵심이다.

---

## 4.3 전통적 OpenCV 프로젝트

Template Matching과 윤곽선 검출 등 고전적 기법을 사용하는 프로젝트들.

| Repository | Tech | 정확도 | 비고 |
|-----------|------|--------|------|
| [EdjeElectronics/OpenCV-Playing-Card-Detector](https://github.com/EdjeElectronics/OpenCV-Playing-Card-Detector) | Python/OpenCV/RPi | ~94% | Template matching, 어두운 배경 필수 |
| [predrag-njegovanovic/poker-hand-recognition](https://github.com/predrag-njegovanovic/poker-hand-recognition) | Python 2.7/OpenCV 3.2/Keras | - | ML classification 결합 |
| [naderchehab/card-detector](https://github.com/naderchehab/card-detector) | Python/OpenCV | - | Template matching |

### 한계

전통적 OpenCV 방식은 다음 조건에서 성능이 급격히 저하된다:

- 조명 변화 (그림자, 반사광)
- 카드 겹침 (Occlusion)
- 카드 회전 (45도 이상)
- 배경이 밝거나 복잡한 경우

방송 환경에서는 조명을 통제할 수 있으므로 일부 한계가 완화되지만, RFID 대비 근본적으로 취약하다.

---

## 4.4 Deep Learning 프로젝트

YOLO 외의 Deep Learning 아키텍처를 적용한 프로젝트들.

| Repository | Framework | 성능 | 비고 |
|-----------|-----------|------|------|
| [jeremyimmanuel/Playing-Card-Detector](https://github.com/jeremyimmanuel/Playing-Card-Detector) | Mask R-CNN | 94.4% mAP | Instance segmentation |
| [0xN1nja/Playing-Cards-Classification](https://github.com/0xN1nja/Playing-Cards-Classification) | TensorFlow CNN | 99.3% train / 69.9% val | **과적합 문제** |
| [Dhrumil29/Poker_Hand_Recognition](https://github.com/Dhrumil29/Poker_Hand_Recognition) | ML | 99.6% accuracy | - |
| [dharm1k987/Card_Recognizer](https://github.com/dharm1k987/Card_Recognizer) | OpenCV + TensorFlow | - | 웹캠 실시간 |

### 주의: 과적합 문제

0xN1nja/Playing-Cards-Classification의 사례가 대표적이다. 훈련 정확도 99.3%이지만 검증 정확도가 69.9%로, 일반화 성능이 극히 낮다. 카드 인식 모델 개발 시 데이터 다양성(각도, 조명, 배경, 카드 디자인)이 정확도보다 중요하다.

---

## 4.5 방송 오버레이 통합

### Floptician (Tom Pitts)

Computer Vision 카드 인식을 실제 포커 방송 오버레이로 통합한 가장 완성도 높은 사례.

**Source**: https://medium.com/@tom_pitts/all-in-on-ai-transforming-a-poker-livestream-with-computer-vision-3ed7834706aa

### 아키텍처

```
┌──────────┐     Frame      ┌──────────┐    Card Data    ┌────────────────┐
│  Webcam  │───────────────→│  YOLOv8  │───────────────→│ BoardProcessor │
│ (1080p)  │                │  Model   │                │  (Game Logic)  │
└──────────┘                └──────────┘                └───────┬────────┘
                                                                │
                                                          OBS WebSocket
                                                                │
                                                        ┌───────▼────────┐
                                                        │  HTML Overlay  │
                                                        │ (Browser Src)  │
                                                        └───────┬────────┘
                                                                │
                                                          Chroma Key
                                                                │
                                                        ┌───────▼────────┐
                                                        │     OBS        │
                                                        │   (Stream)     │
                                                        └────────────────┘
```

### 핵심 요소

| 항목 | 내용 |
|------|------|
| **학습 데이터** | ~1,000장 |
| **모델** | YOLOv8 |
| **오버레이** | HTML + CSS (OBS Browser Source) |
| **합성** | Chroma Key (녹색 배경 제거) |
| **제어** | OBS WebSocket API |

이 아키텍처의 핵심은 **OBS WebSocket을 통한 외부 프로그램의 방송 제어**다. PokerGFX의 전용 GPU 렌더링과 달리, 범용 도구(OBS)의 API를 활용하여 동일한 결과를 저비용으로 달성한다.

---

## 4.6 데이터셋 및 사전 학습 모델

| Dataset | 이미지 수 | 클래스 | 포맷 | 비고 |
|---------|----------|--------|------|------|
| [geaxgx/playing-card-detection](https://github.com/geaxgx/playing-card-detection) | Synthetic 생성 | 52 | YOLO v3 | 434 stars, MIT License |
| Augmented Startups (Roboflow) | 10,100+ | 52 | YOLOv5/v7/v8/v9/v11, COCO, TF | 다중 포맷 |
| Roboflow 100 Poker Cards | Benchmark | 52 | Multiple | 벤치마크 표준 |

### 합성 데이터 생성 전략

실제 카드 촬영만으로는 데이터 다양성이 부족하다. 효과적인 전략:

1. **카드 이미지 합성**: 카드 템플릿을 다양한 배경에 합성
2. **Augmentation**: 회전, 크롭, 색상 변환, 노이즈 추가
3. **Real + Synthetic 혼합**: TeogopK 프로젝트처럼 20,000장 규모 구성
4. **Domain-Specific**: 포커 테이블 펠트 배경, 방송 조명 조건 반영

---

## 4.7 학술 연구

| 논문 | 방법 | 핵심 발견 |
|------|------|----------|
| **Poker Watcher** (IEEE 2021) | EfficientDet + Sandglass Block | 카드가 프레임의 0.7%만 차지 — 소형 객체 탐지 개선 필요 |
| **Stanford CS231n** (2024) | YOLOv8 vs Grounded SAM+CNN | SAM+CNN이 실제 환경에서 더 강건 |
| **DeepGamble** (arXiv 2020) | Mask R-CNN + RPi + GCP | Edge(RPi) → Cloud(GCP) 마이크로서비스 아키텍처 |

### Poker Watcher의 시사점

포커 테이블 전체를 촬영하면 카드는 프레임의 0.7%에 불과하다. 이는 일반적인 객체 탐지 모델이 고전하는 영역이다. 해결 방법:

1. **카드 영역 ROI(Region of Interest) 설정**: 전체 프레임이 아닌 카드가 놓이는 영역만 크롭하여 추론
2. **고해상도 입력**: 4K 카메라로 촬영 후 카드 영역 크롭
3. **Anchor-Free 모델**: FCOS, CenterNet 등 소형 객체에 강한 모델 사용

---

# 5. 기술 비교 매트릭스

## 5.1 RFID vs Computer Vision vs PokerGFX

| Aspect | PokerGFX (상용) | DIY RFID (<$300) | whywaita/rfid-poker | Computer Vision (YOLO) |
|--------|-----------------|-------------------|---------------------|----------------------|
| **정확도** | 99.9% | 99%+ (RFID 고유) | 99%+ | 90-99% (조건 의존) |
| **레이턴시** | <200ms | ~500ms | ~1s | 50-200ms |
| **비용** | $5,000-15,000+ | $200-300 | $150-200 | $50-100 (카메라만) |
| **하드웨어** | SkyeTek 전문 리더 12대 | MFRC522/PN532 | M5Stack Core2 | 웹캠 |
| **카드** | 전용 RFID 카드 | DIY NFC 스티커 | MIFARE Ultralight | 표준 카드 |
| **게임 지원** | 22개 변형 | Hold'em 전용 | Hold'em 전용 | 모든 게임 (시각적) |
| **확장성** | 멀티 테이블 | 싱글 테이블 | 싱글 테이블 | 카메라 의존 |
| **설치** | 전문 설치 | DIY (수시간) | DIY (수시간) | 수분 |
| **신뢰성** | 방송 등급 | 가정용 | 가정용 | 조명 의존 |
| **렌더링** | DirectX 11 GPU | Browser CSS | Next.js | HTML/CSS |
| **보안** | AES-256 + Dual Canvas | 없음 | 없음 | 없음 |
| **프로토콜** | Binary TCP (113+ cmd) | WebSocket/JSON | WebSocket/JSON | OBS WebSocket |
| **오픈소스** | 비공개 | 비공개/일부 | **전체 공개** | 다수 공개 |

## 5.2 아키텍처 비교

### PokerGFX (상용)

```
┌─────────────────────────────────────────────────────────────────┐
│                    PokerGFX 7-App Ecosystem                     │
│                                                                 │
│  ┌──────────┐  Binary TCP   ┌──────────────┐  DirectX 11       │
│  │  RFID    │──(AES-256)──→│    Server     │──(GPU Render)──→ Output
│  │ 12x SkyeTek              │  (.NET 4.x)  │                   │
│  └──────────┘               │  22 Games    │  ┌────────────┐   │
│                             │  113+ Cmds   │→│Action Tracker│  │
│                             │  Hand Eval   │  ├────────────┤   │
│                             │  Statistics  │→│   Viewer    │   │
│                             │  Dual Canvas │  ├────────────┤   │
│                             └──────────────┘→│ Skin Editor │   │
│                                              ├────────────┤   │
│                                             →│  +4 Apps   │   │
│                                              └────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 커뮤니티 표준 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│              Community Standard Architecture                 │
│                                                              │
│  ┌──────────┐    WiFi/USB    ┌──────────┐    WebSocket      │
│  │  RFID    │───────────────→│  Server  │──────────────→    │
│  │ MFRC522  │   or Serial    │ (Go/Node)│               │   │
│  │ /PN532   │                │ Hold'em  │     ┌─────────▼─┐ │
│  └──────────┘                │ JSON API │     │  Browser   │ │
│                              └──────────┘     │ (HTML/CSS) │ │
│       OR                                      │ Chroma Key │ │
│                                               └─────────┬─┘ │
│  ┌──────────┐    Frame       ┌──────────┐               │   │
│  │  Webcam  │───────────────→│  YOLOv8  │───→ OBS ◄─────┘   │
│  │ (1080p)  │                │  Model   │   (Stream)        │
│  └──────────┘                └──────────┘                    │
└─────────────────────────────────────────────────────────────┘
```

### 핵심 차이

| 항목 | PokerGFX | 커뮤니티 |
|------|----------|---------|
| **통신** | Binary TCP + AES-256 암호화 | WebSocket + JSON (평문) |
| **렌더링** | DirectX 11 GPU 직접 제어 | Browser CSS + OBS 합성 |
| **앱 구조** | 7개 전용 앱 동기화 | 단일 앱 (서버+뷰어) |
| **게임 엔진** | 22개 변형, 상태 머신 | Hold'em 하드코딩 |
| **보안** | Dual Canvas, Trustless Mode | 없음 |
| **배포** | .NET Framework + Costura.Fody | Docker / npm / go build |
| **난독화** | ConfuserEx + Dotfuscator | 없음 |

---

# 6. PokerGFX 차별화 요소 분석

PokerGFX가 $5,000-15,000 이상의 가격표를 정당화하는 기술적 요소를 분석한다.

## 6.1 22개 게임 변형 엔진

| 카테고리 | 게임 수 | 예시 |
|---------|---------|------|
| Hold'em 계열 | 5 | Texas Hold'em, Omaha, Omaha Hi-Lo, Short Deck, Pineapple |
| Stud 계열 | 4 | 7-Card Stud, Stud Hi-Lo, Razz, Mexican Poker |
| Draw 계열 | 5 | 5-Card Draw, 2-7 Triple Draw, Badugi, Badeucy, Badacey |
| Mixed 계열 | 4 | HORSE, 8-Game, Dealer's Choice, Mixed NLH |
| 기타 | 4 | Chinese Poker, OFC, Big O, Sviten Special |

커뮤니티 프로젝트 중 Hold'em 이외의 게임을 지원하는 시스템은 없다. PokerGFX의 GameTypes 아키텍처(26개 파일, 게임별 규칙/배팅/핸드평가 분리)는 이 프로젝트의 핵심 역공학 대상이다.

## 6.2 전문 안테나 멀티플렉싱

| 항목 | PokerGFX | DIY |
|------|----------|-----|
| **리더** | SkyeTek 전문 모듈 | MFRC522 ($2) |
| **안테나 정밀도** | +/-0.8mm PCB | +/-3mm 수작업 |
| **멀티플렉서** | 전용 보드 | ADG1607 (Poker Chip Forum) |
| **동시 인식** | 12대 병렬 | 1-3대 순차 |
| **인식 거리** | 30mm+ | 10-20mm |

## 6.3 GPU 렌더링 파이프라인

PokerGFX는 Browser CSS가 아닌 DirectX 11 GPU 직접 렌더링을 사용한다.

```
Game State → Render Queue → DirectX 11 → Dual Canvas Output
                                │
                         ┌──────┴──────┐
                         │             │
                    Table Canvas   Broadcast Canvas
                   (홀카드 숨김)    (홀카드 공개)
```

| 항목 | GPU 렌더링 (PokerGFX) | Browser CSS (커뮤니티) |
|------|----------------------|----------------------|
| **프레임률** | 60fps 보장 | 브라우저 의존 |
| **레이턴시** | <16ms (1 frame) | 16-50ms |
| **애니메이션** | 하드웨어 가속 | CSS transition |
| **해상도** | 4K 네이티브 | 브라우저 제한 |
| **Dual Output** | 네이티브 지원 | 불가능 |

## 6.4 7개 앱 동기화 에코시스템

| 앱 | 역할 | 커뮤니티 대응 |
|----|------|-------------|
| **Server** | 중앙 제어, 게임 엔진 | 서버 (단일) |
| **Action Tracker** | 딜러 입력 (터치스크린) | 없음 |
| **Viewer Overlay** | 방송 그래픽 출력 | Browser overlay |
| **Skin Editor** | 그래픽 커스터마이징 | CSS 수정 |
| **Table Manager** | 다중 테이블 관리 | 없음 |
| **Stats Viewer** | 플레이어 통계 | 없음 |
| **Config Tool** | 시스템 설정 | Config 파일 |

커뮤니티 프로젝트는 "서버 + 브라우저 뷰어" 2개 구성이 최대다.

## 6.5 AES-256 암호화 프로토콜

| 항목 | PokerGFX | 커뮤니티 |
|------|----------|---------|
| **암호화** | AES-256 CBC | 없음 (평문 JSON) |
| **명령어** | 113+ Binary 명령 — *역공학 초기 분류. PRD v2에서 외부 99개 + 내부 ~31개로 재분류* | 5-10개 REST/WS |
| **직렬화** | Length-Prefixed Binary | JSON |
| **Discovery** | UDP Multicast :15000 | 수동 IP 입력 |
| **보안 모드** | Trustless (현장 유출 차단) | 없음 |

## 6.6 Dual Canvas 보안 모델

PokerGFX만의 고유 기능. 하나의 서버에서 두 개의 독립적인 비디오 출력을 생성한다.

```
                    ┌───────────────────────┐
                    │     Game Engine       │
                    │  (Card Data + Stats)  │
                    └──────────┬────────────┘
                               │
                    ┌──────────┴────────────┐
                    │                       │
             ┌──────▼──────┐        ┌───────▼──────┐
             │ Table Canvas │        │ Broadcast    │
             │ (현장 모니터) │        │ Canvas       │
             │              │        │ (방송 출력)   │
             │ ♠♥♣♦ = ??   │        │ ♠♥♣♦ = A♠K♥ │
             │ 홀카드 숨김   │        │ 홀카드 공개   │
             └──────────────┘        └──────────────┘
```

현장에 있는 모니터에는 홀카드 정보가 표시되지 않아, 플레이어나 관중이 상대의 카드를 볼 수 없다. 이 보안 모델은 방송 사고를 원천 차단한다.

---

# 7. 시사점 및 전략적 권고

## 7.1 구현 참고 우선순위

| 순위 | 프로젝트 | 참고 가치 | 이유 |
|------|---------|----------|------|
| **1** | whywaita/rfid-poker | RFID-서버-프론트엔드 전체 통합 | 유일한 전체 공개 시스템 |
| **2** | Poker Chip Forum DIY | 하드웨어 설계 (안테나 MUX) | 상용 수준 안테나 멀티플렉싱 |
| **3** | Floptician | CV 방송 통합 아키텍처 | OBS WebSocket 통합 패턴 |
| **4** | cadyze/card-vision | YOLO 학습/추론 파이프라인 | 코너 라벨링 혁신 |
| **5** | HenryRLee/PokerHandEvaluator | 핸드 평가 알고리즘 | Perfect Hash, 메모리 효율 |

## 7.2 기술 선택 가이드

### RFID 경로 (권장)

| 계층 | 권장 기술 | 대안 |
|------|----------|------|
| **서버** | Go | Node.js |
| **통신** | WebSocket + Binary Protocol | REST + JSON |
| **MCU** | ESP32 | M5Stack Core2 |
| **RFID** | ST25R95 / PN532 | MFRC522 (저가, 품질 이슈) |
| **카드** | MIFARE DESFire (보안) | NTAG213 (저가) |
| **프론트엔드** | Next.js / HTML+CSS | Electron |

### Computer Vision 경로 (보조)

| 계층 | 권장 기술 | 대안 |
|------|----------|------|
| **모델** | YOLOv8m | YOLOv11, EfficientDet |
| **데이터** | 합성 + 실제 혼합 (10,000+) | Roboflow 사전 데이터 |
| **추론** | ONNX Runtime / TensorRT | PyTorch |
| **통합** | OBS WebSocket API | NDI Protocol |

### 하이브리드 경로 (최적)

```
┌──────────┐                    ┌──────────────┐
│   RFID   │───(Primary)──────→│              │
│ (99.9%)  │                    │     EBS      │──→ 방송 출력
│          │                    │    Server    │
└──────────┘                    │              │
                                │              │
┌──────────┐                    │              │
│    CV    │───(Fallback)──────→│              │
│ (95%+)   │   + Validation     │              │
└──────────┘                    └──────────────┘
```

RFID를 주 인식 수단으로, Computer Vision을 보조(검증 및 fallback)로 사용하는 하이브리드 접근이 최적이다.

## 7.3 EBS 차별화 전략

커뮤니티 프로젝트 대비 EBS가 집중해야 할 고유 영역:

### 1차 차별화 (역공학 기반)

| 영역 | 현재 오픈소스 | 우리의 목표 |
|------|------------|-----------|
| **게임 엔진** | Hold'em 전용 | 22개 변형 (역공학 완료) |
| **렌더링** | Browser CSS | GPU 렌더링 파이프라인 |
| **프로토콜** | WebSocket/JSON | Binary TCP + 암호화 |
| **앱 생태계** | 서버+뷰어 (2개) | 7개 앱 동기화 |
| **보안** | 없음 | Dual Canvas + Trustless |

### 2차 차별화 (추가 혁신)

| 영역 | 설명 |
|------|------|
| **하이브리드 인식** | RFID + CV 이중화 (기존 시스템에 없음) |
| **오픈소스** | 전체 공개로 커뮤니티 기여 유도 |
| **현대적 스택** | .NET 4.x → 최신 크로스플랫폼 기술 |
| **클라우드 옵션** | 온프레미스 + 클라우드 하이브리드 배포 |
| **API First** | 서드파티 통합을 위한 공개 API |

---

# 8. Source Links

## 8.1 RFID DIY 프로젝트

| 프로젝트 | URL |
|---------|-----|
| Poker Chip Forum DIY RFID Table | https://www.pokerchipforum.com/threads/experimenting-with-a-diy-rfid-table-and-broadcast-overlay.88715/ |
| whywaita/rfid-poker | https://github.com/whywaita/rfid-poker |
| Smart Poker Table | https://www.smartpokertable.com |
| Smart Poker Table (alt) | https://www.rfidpokertable.com |
| Ivo Ovcharov Portfolio | https://www.ivodev.com/project/smartpokertable |
| Smart Poker Table (HN #1) | https://news.ycombinator.com/item?id=40528317 |
| Smart Poker Table (HN #2) | https://news.ycombinator.com/item?id=40289142 |
| Smart Poker Table Demo | https://www.youtube.com/watch?v=5QU8MC7q8FQ |

## 8.2 RFID/NFC 라이브러리

| Repository | URL |
|-----------|-----|
| pokusew/nfc-pcsc | https://github.com/pokusew/nfc-pcsc |
| esprfid/esp-rfid | https://github.com/esprfid/esp-rfid |
| miguelbalboa/rfid | https://github.com/miguelbalboa/rfid |
| stm32duino/ST25R95 | https://github.com/stm32duino/ST25R95 |
| QuentinCG/Arduino-RFID-Card-Reader-Library | https://github.com/QuentinCG/Arduino-RFID-Card-Reader-Library |

## 8.3 핸드 평가 라이브러리

| Repository | URL |
|-----------|-----|
| zekyll/OMPEval | https://github.com/zekyll/OMPEval |
| HenryRLee/PokerHandEvaluator | https://github.com/HenryRLee/PokerHandEvaluator |
| kmurf1999/rust_poker | https://github.com/kmurf1999/rust_poker |
| ihendley/treys | https://github.com/ihendley/treys |
| whywaita/poker-go | https://github.com/whywaita/poker-go |
| uoftcprg/pokerkit | https://github.com/uoftcprg/pokerkit |

## 8.4 Arduino/RPi RFID 프로젝트

| Repository | URL |
|-----------|-----|
| Raserber/application-visualisation-cartes-poker | https://github.com/Raserber/application-visualisation-cartes-poker |
| Bob's Electronics RFID Card Reader | https://bobparadiso.com/2015/07/27/rfid-playing-card-reader/ |
| TomPaynter/RFID_Antenna | https://github.com/TomPaynter/RFID_Antenna |

## 8.5 Computer Vision - PokerVision

| Repository | URL |
|-----------|-----|
| wb-08/PokerVision | https://github.com/wb-08/PokerVision |
| MemDbg/poker-vision | https://github.com/MemDbg/poker-vision |
| Loutrinator/VPO-PokerVision | https://github.com/Loutrinator/VPO-PokerVision |

## 8.6 Computer Vision - YOLO 기반

| Repository | URL |
|-----------|-----|
| cadyze/card-vision | https://github.com/cadyze/card-vision |
| TeogopK/Playing-Cards-Object-Detection | https://github.com/TeogopK/Playing-Cards-Object-Detection |
| Stephy-Cheung/Yolov4_project | https://github.com/Stephy-Cheung/Yolov4_project |
| MininduLiyanage/Poker-Hand-Identifier | https://github.com/MininduLiyanage/Poker-Hand-Identifier |

## 8.7 Computer Vision - 전통 OpenCV

| Repository | URL |
|-----------|-----|
| EdjeElectronics/OpenCV-Playing-Card-Detector | https://github.com/EdjeElectronics/OpenCV-Playing-Card-Detector |
| predrag-njegovanovic/poker-hand-recognition | https://github.com/predrag-njegovanovic/poker-hand-recognition |
| naderchehab/card-detector | https://github.com/naderchehab/card-detector |

## 8.8 Computer Vision - Deep Learning

| Repository | URL |
|-----------|-----|
| jeremyimmanuel/Playing-Card-Detector | https://github.com/jeremyimmanuel/Playing-Card-Detector |
| 0xN1nja/Playing-Cards-Classification | https://github.com/0xN1nja/Playing-Cards-Classification |
| Dhrumil29/Poker_Hand_Recognition | https://github.com/Dhrumil29/Poker_Hand_Recognition |
| dharm1k987/Card_Recognizer | https://github.com/dharm1k987/Card_Recognizer |

## 8.9 데이터셋

| Dataset | URL |
|---------|-----|
| geaxgx/playing-card-detection | https://github.com/geaxgx/playing-card-detection |

## 8.10 방송 통합 / 기사

| 자료 | URL |
|------|-----|
| Floptician (Tom Pitts) | https://medium.com/@tom_pitts/all-in-on-ai-transforming-a-poker-livestream-with-computer-vision-3ed7834706aa |

---

> **Document End** | Version 1.0.0 | 2026-02-16
