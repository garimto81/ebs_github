---
title: "Lobby 톤 cascade audit — CC v4.3 Broadcast Dark Amber 채택의 Lobby 영향 평가"
status: AUDIT (write-only, 구현 NO)
owner: stream:S2 (Lobby) — Cycle 19 Wave 5
tier: internal
last-updated: 2026-05-13
audience-target: Conductor + S2/S3/S1 + 디자인 의사결정자
narrative-spine: "CC PRD v4.3 톤 결정 → Lobby cross-PRD cascade → 3 옵션 분석 → 권고 (시각 SSOT 신설)"
related-decisions:
  - Q2 (2026-05-07) — "Lobby B&W refined minimal 톤 통일" — CC PRD Ch.11
  - Cycle 19 PR #412 (2026-05-13) — "CC PRD v4.3 — Broadcast Dark Amber OKLCH 톤 채택"
related-docs:
  - ../../1. Product/Lobby.md (v3.0.4)
  - ../../1. Product/Command_Center.md (v4.3)
  - ../../2. Development/2.1 Frontend/Lobby/References/EBS_Lobby_Design/styles.css
  - ../../../team1-frontend/lib/foundation/theme/lobby_mockup_tokens.dart
issue: "#431 [S2 cycle-19 Wave-5] Lobby 톤 cascade audit"
trigger: "Cycle 19 PR #412 머지 후 cross-stream tone 정합 평가 (write-only)"
---

# Lobby 톤 cascade audit — CC v4.3 Broadcast Dark Amber 채택의 Lobby 영향 평가

> **본 보고서는 write-only audit. Lobby 코드 / PRD / token 파일 어느 것도 수정하지 않음. 3 옵션 분석 후 권고만 제시. 최종 채택 옵션 결정은 사용자(거버넌스 영역).**

---

## 1. Context — 무엇이 일어났는가

### 1.1 시점 순서

```
  2026-05-07            2026-05-13                     2026-05-13 (오늘)
       │                     │                                │
       ▼                     ▼                                ▼
  ┌──────────┐         ┌──────────────┐              ┌──────────────────┐
  │ Q2 결정   │         │ Cycle 19      │              │ Wave 5 audit     │
  │           │         │ PR #412       │              │ (본 보고서)       │
  │ "Lobby   │         │              │              │                  │
  │ B&W      │ ◄──충돌──┤ CC PRD v4.3  │              │ 두 결정 비교 +    │
  │ refined  │         │ Broadcast    │              │ 3 옵션 분석       │
  │ minimal  │         │ Dark Amber   │              │                  │
  │ 톤 통일" │         │ OKLCH 채택    │              │                  │
  │           │         │              │              │                  │
  │ CC PRD   │         │ CC PRD Ch.11 │              │                  │
  │ Ch.11    │         │ 시안 → 정본   │              │                  │
  └──────────┘         └──────────────┘              └──────────────────┘
```

> CC PRD Ch.11 자체가 *Q2 결정 ("Lobby B&W refined minimal 톤 통일")* 을 인용하는 챕터다. 그런데 Cycle 19 에서 같은 PRD 가 v4.3 으로 올라가면서 *broadcast amber* 를 production token 으로 굳혔다. Lobby PRD 와 Lobby 코드는 변경 없음 — 따라서 양측이 다른 톤으로 굳어있다.

### 1.2 본 audit 가 발동된 이유

| # | 요인 |
|:-:|------|
| 1 | CC 톤 결정(Cycle 19 PR #412)이 **Lobby 와의 일관성 가정** 을 깬다 |
| 2 | Lobby ↔ CC 운영자 흐름은 **연속적** (Lobby 5 화면 → CC 진입 → CC 종료 → Lobby 복귀) |
| 3 | 12 시간 본방송 환경에서 *시각 톤 전환 충격* 이 운영자 눈/집중도 영향 가능 |
| 4 | `derivative-of` 메커니즘은 **단방향 cascade** 만 잡는다 — *cross-PRD 결정 충돌* 은 사각지대 |
| 5 | Wave 5 = Cycle 19 cross-stream 정합 종결 단계. **두 결정을 한 자리에서 비교** 할 책임 |

---

## 2. 시각 비교 — Lobby tokens vs CC tokens (Cycle 19)

### 2.1 Surface (배경) 4-tier

| layer | Lobby `styles.css` (warm ink) | Lobby `lobby_mockup_tokens.dart` (hex SSOT) | CC `tokens.css` (Cycle 19 v4.3) |
|:-----:|-------------------------------|---------------------------------------------|---------------------------------|
| 가장 깊은 배경 | `oklch(0.985 0.003 80)` 거의 흰색 | `#FFFFFF` body | `oklch(0.16 0.012 240)` **다크 네이비** |
| 보조 배경 | `oklch(0.965 0.004 80)` | `#FAFAFA` hover/ebs col | `oklch(0.20 0.014 240)` |
| 카드/seat | `oklch(0.945 0.005 80)` | (해당 layer 없음) | `oklch(0.24 0.014 240)` |
| raised/hover | (해당 layer 없음, `--line` 으로 구분) | (`#F0F0F0` 등 line 으로 구분) | `oklch(0.29 0.014 240)` |
| dark rail | `oklch(0.16 0.01 80)` **rail-bg** | `#1A1A1A` **headerBg** | (해당 layer 없음, 전체가 어두움) |

> **관측**: Lobby 는 *밝은 body + 어두운 rail/header* 의 **이중 표면**. CC 는 *전체 다크 네이비 + 양각 panel*. **chroma 차이**: Lobby 0.003~0.013 (거의 무채색), CC 0.012~0.014 (Hue 240° 미세 청색조).

### 2.2 Accent (강조)

| 역할 | Lobby | CC (Cycle 19 v4.3) |
|------|-------|---------------------|
| primary accent | `--ink: oklch(0.18 0.01 80)` (검정) — *색이 아닌 contrast 로 강조* | `--accent: oklch(0.78 0.16 65)` **broadcast amber** |
| accent strong | (해당 layer 없음) | `oklch(0.72 0.18 60)` |
| accent soft | (해당 layer 없음) | `oklch(0.78 0.16 65 / 0.18)` glow/soft fill |
| 운영 함의 | 운영자 시선이 *형태/위치* 로 유도됨 | 운영자 시선이 *amber glow* 로 자석처럼 끌림 |

### 2.3 Status (기능 색상)

| 상태 | Lobby `styles.css` | CC `tokens.css` |
|------|-------------------|-----------------|
| OK / Live | `--live: oklch(0.66 0.16 145)` on-air green | `--ok: oklch(0.74 0.14 150)` |
| Warn | `--warn: oklch(0.78 0.14 75)` amber | `--warn: oklch(0.80 0.16 80)` |
| Danger / Err | `--danger: oklch(0.60 0.18 28)` | `--err: oklch(0.66 0.20 25)` |
| Info | `--info: oklch(0.58 0.13 250)` | `--info: oklch(0.72 0.13 230)` |

> **관측**: Status 색상은 **거의 동일한 hue family** (녹 145/150, 황 75/80, 적 28/25, 청 250/230). chroma 와 lightness 만 다름 (CC 는 어두운 배경 위에 떠야 하므로 lightness 가 약간 더 높음). 즉 *status 의미론은 호환* — 운영자가 두 화면에서 같은 색을 같은 의미로 해석.

### 2.4 한 줄 요약 표

```
  +-------------------------------+--------------------+--------------------+
  | 톤 차원                       | Lobby             | CC (Cycle 19 v4.3) |
  +-------------------------------+--------------------+--------------------+
  | 본문 배경 lightness          | 0.985 (거의 흰)   | 0.16 (거의 검정)   |
  | 본문 배경 chroma             | 0.003 (무채)      | 0.012 (미세 청)    |
  | 본문 배경 hue                | 80 (warm)         | 240 (cool)         |
  | accent 채도                  | 0 (없음, 검정 ink)| 0.16 (broadcast)   |
  | accent hue                   | -                 | 65 (amber)         |
  | 분위기                       | refined paper     | broadcast cockpit  |
  | 시선 유도                    | 위치/형태         | amber glow         |
  | Status 색상 family           | 145/75/28/250     | 150/80/25/230     |
  | Status 호환성                | 거의 동일 (의미론 호환)                 |
  +-------------------------------+--------------------+--------------------+
```

---

## 3. 인지 부조화 평가 — 운영자가 겪는 톤 전환 충격

### 3.1 운영자 일상 흐름

```
  06:00         07:00         08:00 ~ 20:00         20:00         21:00
   │             │                 │                  │             │
   ▼             ▼                 ▼                  ▼             ▼
  Login       Lobby 5            CC 진입 +           Lobby 복귀    Logout
              화면 시퀀스         (12 시간)           (다음 테이블)
              (5 분)
   ─ 흰 ─    ─ 흰 (+ 다크 ─    ─ 다크 네이비 ─    ─ 흰 ─        ─ 흰 ─
              header) ─        + amber accent
```

> **하루 4~6 회 전환**. Lobby ↔ CC 사이를 오가는 시점:
> - 첫 진입 (Lobby → CC)
> - 비상 진입 (CC ↔ Lobby, RFID 꺼졌을 때)
> - 변경 진입 (CC → Lobby, 게임 바뀔 때)
> - 종료 진입 (CC → Lobby, 방송 끝)

### 3.2 12 시간 본방송 환경 영향

| 측면 | 영향 분석 |
|------|----------|
| **눈 피로 (밝기 점프)** | Lobby 0.985 L → CC 0.16 L = 약 **6 배 lightness 점프**. 운영실 조도가 어둡다면 (방송 환경 기본) CC 진입 시 동공이 적응 — 0.5~1 초 시각 부담 |
| **잔상 효과** | 12 시간 CC 응시 후 Lobby 복귀 시 *amber afterimage* 가 흰 배경에서 잠시 보이는 시각 잔상 가능 |
| **시선 유도 차이** | Lobby = 위치/형태로 정보 위계 / CC = amber glow 로 강조. 두 화면 사이 *시각 문법 차이* 가 인지 부담 (운영자가 "어디 봐야 하나" 학습 비용 분리) |
| **Status 의미론 일관성** | 다행히 status 색 (녹/황/적/청) 은 두 화면이 거의 동일 family — *기능 의미론 일관성은 보존* |
| **집중도** | CC 의 amber glow 는 *방송 환경에 맞춘 의도된 강조* — 시청자가 보지 않는 운영자 전용 화면이므로 정당화 가능. 하지만 Lobby 도 운영자 전용이라 같은 논리 적용 가능 (= 둘 다 broadcast 톤?) |
| **운영자 학습 부담** | 신규 운영자가 *두 시각 시스템* 을 따로 학습해야 함. 단일 톤이면 학습 비용 절반 |

### 3.3 인지 부조화 점수 (정성 평가)

```
  +-------------------------+--------+-----------------------------+
  | 차원                    | 점수   | 근거                        |
  +-------------------------+--------+-----------------------------+
  | 밝기 점프 (눈 부담)     |  중간  | 6 배 lightness 점프         |
  | Hue 점프 (warm→cool)    |  중간  | 80°→240° 반대 방향          |
  | Accent 시각 문법 차이   |  높음  | 없음 vs amber glow          |
  | Status 의미론 일관성    |  양호  | 거의 동일 family (다행)    |
  | 12 h 환경 누적 영향     |  중간  | afterimage + 적응 누적     |
  +-------------------------+--------+-----------------------------+

  종합: 중간 부조화 — 작동은 가능하나 일관성 부재가 측정 가능한
       운영자 비용 (눈 피로 + 학습 부담) 을 발생시킨다.
```

> **다행 요소**: status 색상이 거의 동일 family. 만약 status 색상까지 어긋났다면 (예: Lobby green = oklch(0.66 0.16 145), CC green = oklch(0.85 0.10 100)) 부조화는 *높음* 으로 올라간다. 현재는 **시각 *분위기* 만 다르고 *기능 의미론* 은 보존** 된 상태 — 사고 위험은 낮으나 *통일성* 결손.

---

## 4. 3 옵션 분석 (구현 NO — 분석만)

### 4.1 옵션 A — Lobby 도 Broadcast Amber OKLCH 채택

```
  현재:  Lobby = warm B&W       CC = broadcast amber
  변경:  Lobby = broadcast amber  CC = broadcast amber (유지)
  결과:  cross-app 단일 톤 (CC 기준)
```

| 항목 | 평가 |
|------|------|
| **장점** | cross-app 시각 일관성 100%. 운영자 학습 비용 최소. *방송 환경 의도* (어두운 cockpit) 통일. CC 가 본방송 시 12 시간 메인 화면이므로 CC 기준 통일이 자연스러움 |
| **단점** | Lobby PRD v3.0.4 본문 재작성 필요 (5 화면 시퀀스 + 모든 mockup screenshot 재캡처). `styles.css` + `lobby_mockup_tokens.dart` 양측 SSOT 재설계. lobby-stream 재작업 2~3 cycle 추정 |
| **충돌하는 결정** | Q2 (2026-05-07) — "Lobby B&W refined minimal 톤 통일" 을 *역방향으로 폐기* 해야 함 (Q2 supersede 결정 필요) |
| **개발 비용** | **HIGH** — 25 PNG 재캡처 + tokens.dart 재정의 + 5 화면 mockup HTML 5 개 재작성 + Flutter ThemeData 매핑 재구현 |
| **운영 비용** | low (한 번 통합 후 미래 일관성) |
| **위험** | Lobby 의 *paper-like refined minimal* 정체성 (`Bloomberg-style warm-neutral palette`) 영구 손실 |

### 4.2 옵션 B — Lobby 유지 + CC 별개 톤 정당화

```
  현재:  Lobby = warm B&W       CC = broadcast amber
  변경:  유지                  유지 (별개 톤이 의도된 것으로 PRD 명시)
  결과:  의도된 톤 분리 + 양측 PRD 에 "운영 컨텍스트 차이" 명시
```

| 항목 | 평가 |
|------|------|
| **장점** | 코드 변경 0. PRD 본문은 *현재 상태 정당화 문구만 추가* (writing-only). 두 화면의 *역할 차이* (Lobby = 5 분 게이트웨이 / CC = 12 시간 cockpit) 를 시각으로 표현 |
| **단점** | 부조화 (중간) 가 운영자에게 영구 남음. 신규 운영자 학습 부담 누적. 향후 BO + Overlay 가 추가되면 *어느 톤* 을 따를지 결정 부담 반복 |
| **충돌하는 결정** | Q2 자체는 "통일" 을 명시했으므로 Q2 도 supersede 필요 — 단 *역방향으로 결정 자체 무효화* (Lobby 유지가 가능하다고 봤기 때문) |
| **개발 비용** | **LOW** — PRD 본문에 정당화 섹션 1~2 페이지 추가만 (CC PRD Ch.11 + Lobby PRD 부록) |
| **운영 비용** | medium (영구 부조화 누적) |
| **위험** | 향후 추가 화면(BO admin, Overlay control panel 등) 마다 *어느 톤* 결정 부담. cascade audit 가 반복 발생 |

### 4.3 옵션 C — 공유 톤 SSOT 신설 (별도 디자인 시스템 PRD)

```
  현재:  Lobby = warm B&W       CC = broadcast amber       (별개 SSOT)
  변경:  Design_System.md 신설 (cross-app 시각 SSOT)
         ├── Lobby = warm B&W   (derivative-of Design_System.md)
         └── CC = broadcast amber (derivative-of Design_System.md)
  결과:  Design_System.md 가 두 톤을 모두 정의 + 어느 톤을 어느 화면에 쓰는지 결정
```

| 항목 | 평가 |
|------|------|
| **장점** | **근본 해결** — 두 톤 사이 *결정 위계* 가 한 곳에 존재. 미래 BO + Overlay 가 같은 SSOT 를 derivative-of 로 참조 가능. **cross-PRD cascade 사각지대** 가 영구 차단 (모든 톤 변경이 Design_System.md 를 통과) |
| **단점** | 신규 PRD 작성 비용. 신규 owner stream 필요 (S1 Foundation 권장 — Foundation.md 와 같은 cross-app SSOT 영역). 이미 결정된 *Q2 vs Cycle 19* 모순을 *Design_System.md 본문에서 해소* 해야 함 (옵션 A 또는 B 의 결정을 본문에 명시) |
| **충돌하는 결정** | Q2 와 Cycle 19 결정 모두 Design_System.md 의 *입력* 으로 흡수. SSOT 자체가 *어느 톤* 을 결정하는 게 아니라 *어느 화면이 어느 톤* 을 결정 |
| **개발 비용** | **MEDIUM** — Design_System.md 신규 작성 (cross-app 시각 SSOT 8~15 페이지 + 두 톤 catalog 통합). Lobby PRD + CC PRD 의 frontmatter 에 `derivative-of: Design_System.md` 추가. 코드 변경 0 |
| **운영 비용** | very low (단일 SSOT 가 모든 미래 톤 결정 흡수) |
| **위험** | Design_System.md 가 *비어있는 wrapper* 가 되어 실효성 없음 — 단, Foundation.md 처럼 *cross-app cross-team SSOT* 가 EBS 에 이미 정착된 패턴이라 위험 낮음 |

### 4.4 옵션 비교 매트릭스

```
  +-----------+--------+-----------+-------------+--------------+----------+
  | 옵션      | 일관성 | 개발 비용 | 운영 비용   | 미래 확장성  | 결정 부담|
  +-----------+--------+-----------+-------------+--------------+----------+
  | A. Lobby  |        |           |             |              |          |
  | broadcast |  높음  | HIGH      | LOW         |  중간        | 1 회     |
  | amber     |        |           |             |              |          |
  +-----------+--------+-----------+-------------+--------------+----------+
  | B. Lobby  |        |           |             |              |          |
  | 유지      |  낮음  | LOW       | MEDIUM      |  낮음        | 매 화면  |
  | 정당화    |        |           |             |              | 반복     |
  +-----------+--------+-----------+-------------+--------------+----------+
  | C. SSOT   |        |           |             |              |          |
  | Design_   |  높음  | MEDIUM    | VERY LOW    |  높음        | 1 회 +  |
  | System.md |        |           |             |              | 영구 차단|
  +-----------+--------+-----------+-------------+--------------+----------+
```

---

## 5. 권고안 — Claude 자율 결정 + 사용자 결정 영역 구분

### 5.1 Claude 자율 권고 (분석 근거 기반)

**권장: 옵션 C — 공유 톤 SSOT 신설 (`docs/1. Product/Design_System.md`)**

근거:

| # | 근거 |
|:-:|------|
| 1 | **본 Cycle 19 사고의 root cause = 단일 시각 SSOT 부재**. Q2 (2026-05-07) 가 *Lobby PRD 가 아닌 CC PRD 내부 챕터* 에 결정으로 박혀있었기 때문에 Cycle 19 PR #412 에서 같은 PRD 의 다른 챕터 결정과 충돌 발생. 단일 SSOT 가 있었다면 Cycle 19 PR 이 *Design_System.md 본문 변경* 으로 cascade audit 자동 발동 |
| 2 | **미래 확장성** — BO (S7) Admin UI, Overlay (S3) graphic 톤, 향후 Mobile companion 등이 모두 같은 cascade 문제 반복. Design_System.md 가 *단일 진입점* 이 되면 cascade audit 가 1 회로 종결 |
| 3 | **EBS 에 이미 같은 패턴 정착** — Foundation.md 가 cross-app cross-team SSOT 로 작동 중. Design_System.md 는 같은 패턴의 *시각 차원 SSOT* — 운영 익숙도 높음 |
| 4 | **결정 충돌의 본질적 해소** — 옵션 A 는 Q2 폐기, 옵션 B 는 Q2 통일 의도 폐기. 둘 다 *지난 결정을 부정* 해야 함. 옵션 C 는 *Q2 와 Cycle 19 양측을 Design_System.md 내부 결정으로 흡수* — 결정 supersede 가 *위계 명시* 형태로 정리됨 |
| 5 | **코드 변경 0** — 옵션 C 채택 후 *어느 톤을 어느 화면에 매핑할지* 는 Design_System.md 본문 결정. 그 결정 자체가 옵션 A (Lobby 도 amber) 또는 옵션 B (별개 유지) 중 하나로 갈 수 있음 — 즉 옵션 C 채택은 *옵션 A/B 결정을 막지 않는다*. 오히려 그 결정의 *영구 보존 위치* 를 제공 |
| 6 | **개발 비용 MEDIUM 의 정당화** — Design_System.md 작성은 *현재 두 톤 token catalog 를 모은 wrapper* 부터 시작 가능 (8~10 페이지). 즉시 production 가치 발생: cascade audit 사각지대 차단 |

### 5.2 사용자 결정 영역 (Claude 자율 NO)

```
  +----------------------------------------------------------+
  | 결정 항목                       | 근거 / 옵션              |
  +----------------------------------------------------------+
  | (1) 옵션 A vs B vs C 선택       | Claude 권고: C          |
  |                                 | 최종 결정: 사용자        |
  +----------------------------------------------------------+
  | (2) 옵션 C 채택 시 owner stream | Claude 권고:            |
  |                                 |   S1 Foundation         |
  |                                 |   (Foundation.md 와    |
  |                                 |    같은 cross-app 영역) |
  |                                 | 대안: 신규 S12 Design   |
  |                                 |   stream                |
  |                                 | 최종 결정: 사용자        |
  +----------------------------------------------------------+
  | (3) Design_System.md 채택 시,   | 옵션 A (Lobby 도 amber) |
  |     Lobby/CC 의 톤 매핑         | vs 옵션 B (별개 유지)    |
  |     (어느 화면이 어느 톤)       | — 본 audit 는           |
  |                                 |   세부 의견 보류:        |
  |                                 |   "시각 SSOT 신설 후     |
  |                                 |    별도 결정"            |
  +----------------------------------------------------------+
  | (4) Q2 결정의 위상              | Q2 를 supersede 할지,   |
  |                                 | Design_System.md 안으로  |
  |                                 | 흡수할지 — 본 audit 는   |
  |                                 | 흡수 권장 (역사 보존)    |
  +----------------------------------------------------------+
  | (5) Cycle 19 PR #412 의 위상    | 이미 머지됨. revert 여부 |
  |                                 | 는 사용자 결정 영역.     |
  |                                 | 본 audit 는 revert       |
  |                                 | 권장 NO (코드 정합 비용  |
  |                                 | + Design_System.md 결정  |
  |                                 | 전까지 잠정 유지)        |
  +----------------------------------------------------------+
```

### 5.3 본 audit 다음 단계 (사용자 결정 후 실행)

```
  사용자가 옵션 결정
       │
       ├── 옵션 A 선택 ──→ S2 cycle 후속: Lobby PRD + tokens 재설계
       │                  (lobby-stream 2~3 cycle)
       │
       ├── 옵션 B 선택 ──→ S10-W cycle 후속: 양 PRD 정당화 섹션 작성
       │                  (writing-only 1 cycle)
       │
       └── 옵션 C 선택 ──→ S1 (또는 신규 S12) 신규:
                          Design_System.md 작성
                          + Lobby/CC PRD frontmatter derivative-of 추가
                          + 그 후 옵션 A/B 본문 결정
                          (2 cycle 추정)
```

---

## 6. 부록 — 관련 자료

### 6.1 참조 PR / 결정

| ID | 날짜 | 내용 |
|----|------|------|
| Q2 | 2026-05-07 | CC PRD Ch.11 — "Lobby B&W refined minimal 톤 통일" 사용자 결정 |
| PR #409 | 2026-05-13 | S10-W docs(cycle-19): CC PRD v4.3 — Broadcast Dark Amber OKLCH 톤 채택 (PRD 본문) |
| PR #412 | 2026-05-13 | S3 feat(cycle-19): CC HTML realign — Broadcast Dark Amber 시안 → 정본 (mockup HTML 정합) |
| PR #414 | 2026-05-13 | S3 feat(cycle-19): U1 Design Token Layer — Broadcast Dark Amber OKLCH 채택 (Flutter 구현) |
| PR #430 | 2026-05-13 | S3 fix(cycle-19): theme wiring — EbsTheme.dark 을 app.dart 에 연결 [hotfix] |

### 6.2 참조 파일

| 경로 | 역할 |
|------|------|
| `docs/1. Product/Lobby.md` v3.0.4 | Lobby 외부 PRD (변경 없음 — derivative-of `2.1 Frontend/Lobby/Overview.md`) |
| `docs/1. Product/Command_Center.md` v4.3 | CC 외부 PRD (Cycle 19 PR #409 변경) |
| `docs/2. Development/2.1 Frontend/Lobby/References/EBS_Lobby_Design/styles.css` | Lobby 디자인 SSOT v2 (Bloomberg warm-neutral oklch) |
| `team1-frontend/lib/foundation/theme/lobby_mockup_tokens.dart` | Lobby mockup hex SSOT (Cycle 11 #379 신규) |

### 6.3 본 audit 가 닿지 않은 영역 (out-of-scope)

| 영역 | 사유 |
|------|------|
| BO (Back Office) 톤 | Cycle 19 결정 영향 평가 별도 audit 필요 (S10-A 권장) |
| Overlay 그래픽 톤 | RIVE_Standards 와 별개 결정 영역 |
| Mobile companion 톤 | 미구현 — 미래 결정 영역 |
| 색맹 접근성 평가 | OKLCH chroma 변경이 색맹 대응에 미치는 영향 별도 audit 필요 |

---

## 7. 자가 점검

| # | 점검 | 통과 |
|:-:|------|:----:|
| 1 | frontmatter (title/status/owner/tier/last-updated) | PASS |
| 2 | 5 섹션 모두 작성 (Context / 시각비교 / 인지부조화 / 3옵션 / 권고안) | PASS |
| 3 | ASCII 다이어그램 우선 (rule 11) | PASS |
| 4 | 사용자 결정 영역 ↔ Claude 자율 결정 영역 명확 구분 | PASS |
| 5 | write-only (Lobby 코드 / PRD / token 파일 변경 0) | PASS |
| 6 | scope 준수 (docs/4. Operations/Reports/ 신규 1 파일만) | PASS |
| 7 | Q2 와 Cycle 19 결정 충돌 명시 + 양측 supersede 시나리오 | PASS |
| 8 | 비유 (호텔 로비 / paper-like / cockpit) 사용으로 비전문가 이해 가능 | PASS |

---

## Changelog

| 날짜 | 버전 | 변경 |
|------|:---:|------|
| 2026-05-13 | v1.0 | 최초 작성 (S2 Cycle 19 Wave 5 audit, write-only) |
