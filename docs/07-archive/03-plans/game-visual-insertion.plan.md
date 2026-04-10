# 22종 게임 PRD 시각 가이드 캡처 삽입 계획

> **Version**: 1.0.0
> **Date**: 2026-03-30
> **배경**: 게임 규칙 PRD 3개 파일에 텍스트 카드 표기([A♠][K♥])만 있어 이해가 어려움. HTML 시각 가이드에서 필요한 부분만 캡처하여 .md 파일에 인라인 삽입.

---

## 구현 범위

### 대상 파일

| .md 파일 | HTML 소스 | 삽입 수 (HIGH) | 삽입 수 (MEDIUM) |
|----------|----------|:---:|:---:|
| PRD-GAME-01-community-card.md | community-card-visual.html | 6 | 6 |
| PRD-GAME-02-draw.md | draw-visual.html | 5 | 5 |
| PRD-GAME-03-stud.md | stud-visual.html | 6 | 4 |
| **합계** | | **17** | **15** |

### 우선순위 정책

- **Wave 1**: HIGH 17개 (텍스트만으로 이해 곤란한 핵심 시나리오)
- **Wave 2**: MEDIUM 15개 (이해를 보강하는 비교/규칙 시각화)
- LOW 3개는 생략 (ROI 낮음)

---

## 실행 방법

### Step 1: Playwright로 HTML 섹션별 캡처

```bash
# 각 HTML 파일을 브라우저에서 열고 섹션별 스크린샷
npx playwright screenshot \
  --selector ".section:nth-of-type(N)" \
  --viewport-size "720x1280" \
  visual/community-card-visual.html \
  ../../08-rules/games/visual/screenshots/cc-01.png
```

**캡처 전략**: HTML 파일의 각 `<div class="section">` 또는 `<div class="poker-table">`을 개별 selector로 캡처.

### Step 2: 이미지 저장 경로

```
docs/00-prd/games/../../08-rules/games/visual/screenshots/
├── cc-01-holecards.png       ← Community Card 캡처
├── cc-02-flop.png
├── cc-03-turn.png
├── ...
├── dr-01-initial-hand.png    ← Draw 캡처
├── dr-02-exchange-1.png
├── ...
├── st-01-3rd-street.png      ← Stud 캡처
├── st-02-4th-street.png
└── ...
```

**파일명 규칙**: `{계열}-{순번}-{설명}.png`

### Step 3: .md 파일에 이미지 삽입

텍스트 카드 표기 **아래에** 이미지를 추가 (텍스트는 유지 — 이미지 로딩 실패 시 fallback):

```markdown
> 내 홀카드: [A♠][K♥]
> 보드(Flop): [A♦][7♣][2♠]

![Flop 상태 — 홀카드 2장 + 보드 3장](../../08-rules/games/visual/screenshots/cc-02-flop.png)
```

---

## Wave 1: HIGH 17개 — 삽입 상세 매핑

### Community Card (cc-01 ~ cc-06)

| ID | 삽입 위치 (줄 번호 뒤) | HTML 캡처 대상 | 캡처 내용 |
|----|:---:|----------|----------|
| cc-01 | 49 | 포커 테이블 — 홀카드 배분 | 3인 테이블, 각자 face-down 2장 |
| cc-02 | 83 | Flop 단계 | [A♠][K♥] + 보드 [A♦][7♣][2♠] |
| cc-03 | 94 | Turn 단계 | 보드 4장, K♦ 노란 테두리 |
| cc-04 | 105 | River 단계 | 보드 5장 완성, 10♣ 노란 테두리 |
| cc-05 | 148 | 승부 — 양측 홀카드 비교 | A [A♠][K♥] vs B [Q♦][Q♣] + 보드 |
| cc-06 | 152 | 승부 — 결과 배너 | Two Pair > One Pair, A 승리 |

### Draw (dr-01 ~ dr-05)

| ID | 삽입 위치 | HTML 캡처 대상 | 캡처 내용 |
|----|:---:|----------|----------|
| dr-01 | 68 | 초기 5장 | K♠ Q♥ 빨간 테두리(버릴 카드) |
| dr-02 | 70 | 1차 교환 후 | 8♣ 3♥ 노란 테두리(새 카드) |
| dr-03 | 75 | 2차 교환 후 → Stand Pat | 7-5 Low 완성, 초록 테두리 |
| dr-04 | 108 | Lowball 랭킹 테이블 | 최강~최약 5단계 카드 이미지 |
| dr-05 | 117 | 승부 비교 | A(7-5) vs B(8-6), A 승리 |

### Stud (st-01 ~ st-06)

| ID | 삽입 위치 | HTML 캡처 대상 | 캡처 내용 |
|----|:---:|----------|----------|
| st-01 | 49 | 3rd Street | 비공개2 + 공개1, Bring-in 표시 |
| st-02 | 70 | 4th Street | B의 J 페어 강조 |
| st-03 | 78 | 5th Street | A도 K 페어 등장 |
| st-04 | 86 | 6th Street | 공개 4장, C 폴드 |
| st-05 | 95 | 7th Street | 마지막 비공개 카드 |
| st-06 | 117 | 쇼다운 | 7장 전체 공개, Best 5 강조 |

---

## Wave 2: MEDIUM 15개 — 삽입 상세 매핑

### Community Card (cc-07 ~ cc-12)

| ID | 삽입 위치 | 캡처 내용 |
|----|:---:|----------|
| cc-07 | 137 | 핸드 랭킹 10단계 카드 이미지 전체 |
| cc-08 | 198 | Short Deck: Flush > Full House 역전 비교 |
| cc-09 | 250 | Pineapple: 3장→버림→2장 과정 |
| cc-10 | 290 | Omaha ❌ 잘못된 2+3 선택 |
| cc-11 | 290 | Omaha ✅ 올바른 2+3 선택 |
| cc-12 | 346 | Hi-Lo 팟 50/50 분배 다이어그램 |

### Draw (dr-06 ~ dr-10)

| ID | 삽입 위치 | 캡처 내용 |
|----|:---:|----------|
| dr-06 | 111 | 2-3-4-5-6(Straight ❌) vs 2-3-4-5-7(✅) |
| dr-07 | 164 | 2-7 vs A-5: 같은 카드 다른 평가 |
| dr-08 | 202 | Badugi 4-card > 3-card > 2-card 계층 |
| dr-09 | 187 | Perfect Badugi ♠♥♦♣ 전부 다름 |
| dr-10 | 190 | Failed Badugi ♠♠ 중복, 죽은 카드 |

### Stud (st-07 ~ st-10)

| ID | 삽입 위치 | 캡처 내용 |
|----|:---:|----------|
| st-07 | 152 | Hi-Lo Low 자격: ≤8 초록 / >8 빨강 |
| st-08 | 179 | Razz: A-2-3-4-5가 Stud=Straight vs Razz=최강 |
| st-09 | 179 | Razz: K-K-K-A-Q가 Stud=강 vs Razz=최약 |
| st-10 | 187 | Razz 승부: 7-5 Low vs 8-6 Low |

---

## 기술 사양

### 캡처 설정

| 항목 | 값 |
|------|-----|
| viewport | 720 x auto |
| format | PNG |
| DPI | 2x (Retina) |
| max-width | 680px |
| background | 투명 or #1a1a2e (다크 유지) |

### .md 이미지 삽입 패턴

```markdown
<!-- 텍스트 카드 표기 (fallback) -->
> 내 홀카드: [A♠][K♥]
> 보드(Flop): [A♦][7♣][2♠]

<!-- 시각 가이드 캡처 -->
<img src="../../08-rules/games/visual/screenshots/cc-02-flop.png" alt="Flop 상태 — 홀카드 2장 + 보드 3장" width="600">
```

**원칙**:
- 텍스트 카드 표기는 삭제하지 않음 (이미지 로딩 실패 시 fallback)
- `<img>` 태그로 width 제어 (max 600px)
- alt 텍스트에 한글 설명 포함

### 줄 수 영향 예측

| 파일 | 현재 | 추가 (Wave 1) | 추가 (Wave 2) | 합계 |
|------|:---:|:---:|:---:|:---:|
| PRD-GAME-01 | 428 | +12줄 | +12줄 | 452 |
| PRD-GAME-02 | 259 | +10줄 | +10줄 | 279 |
| PRD-GAME-03 | 199 | +12줄 | +8줄 | 219 |

모든 파일 500줄 이하 유지.

---

## 실행 순서

```
Step 1: screenshots/ 디렉토리 생성
Step 2: Playwright로 HTML 파일 열기 + 섹션별 캡처 (32장)
Step 3: .md 파일에 Wave 1 이미지 17개 삽입 (HIGH)
Step 4: 검증 (이미지 렌더링, alt 텍스트, 줄 수)
Step 5: .md 파일에 Wave 2 이미지 15개 삽입 (MEDIUM)
Step 6: 최종 검증
```

---

## 위험 요소

| 위험 | 완화 |
|------|------|
| Playwright 캡처 시 CSS 렌더링 차이 | `--viewport-size 720x1280` 고정, 2x DPI |
| 이미지 파일 크기 bloat | PNG 최적화 (pngquant), 타겟 < 50KB/장 |
| GitHub에서 상대 경로 이미지 미표시 | `<img src>` 대신 `![alt](path)` 마크다운 문법 사용 |
| HTML 소스 변경 시 캡처 out-of-sync | 캡처 스크립트화, HTML 수정 시 재실행 |

---

## 예상 영향 파일

| 파일 | 변경 유형 |
|------|----------|
| `docs/00-prd/games/../../08-rules/games/visual/screenshots/` | 신규 디렉토리 + 32개 PNG |
| `docs/00-prd/games/PRD-GAME-01-community-card.md` | 이미지 태그 12개 추가 |
| `docs/00-prd/games/PRD-GAME-02-draw.md` | 이미지 태그 10개 추가 |
| `docs/00-prd/games/PRD-GAME-03-stud.md` | 이미지 태그 10개 추가 |
