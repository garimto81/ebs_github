---
title: NOTIFY-S1 — CC v4.0 정체성 cascade가 Foundation §Ch.5.4 에 영향
owner: stream:S3 (Command Center)
target: stream:S1 (Foundation)
tier: notify
status: OPEN
last-updated: 2026-05-07
---

# NOTIFY-S1 — CC v4.0 정체성 cascade가 Foundation §Ch.5.4 에 영향

## 트리거

`docs/1. Product/Command_Center_PRD.md` v4.0 (2026-05-07) cascade. S3 stream 이 Command Center 정본 + 30+ feature 문서에 v4.0 정체성 (1×10 그리드 / 6 키 / 4 영역 위계 / 5-Act 시퀀스) 정합 완료. Foundation §Ch.5.4 ("실시간 조종석 Command Center") 가 v1.x 기술 ("8 액션 버튼 + 10 좌석") 으로 남아 있음.

## 영향 위치

- `docs/1. Product/Foundation.md` Line 874:
  ```
  ![Command Center — 8 액션 버튼 + 10 좌석](images/foundation/app-command-center.png)
  ```
- `docs/1. Product/Foundation.md` §Ch.5.4 본문 — 8 액션 버튼 / 타원형 테이블 기술이 잔존할 가능성 (§5.4 전체 검토 필요)

## 권장 변경 (S1 자율 판단)

### Option A — Caption 정합

이미지 caption 만 v4.0 으로 갱신:
```
![Command Center — 6 키 동적 매핑 + 1×10 가로 그리드 (v4.0)](images/foundation/app-command-center.png)
```

이미지 자체는 v1.x 일 수 있으나, caption 이 v4.0 정체성을 명시하면 추후 이미지 교체 시 자연스럽게 정합.

### Option B — 본문 §Ch.5.4 v4.0 정체성 명시

§Ch.5.4 본문에 다음 추가 (1~2 문단):

> v4.0 (2026-05-07) 부터 Command Center 는 **1×10 가로 그리드** 좌석 배치 + **6 키 동적 매핑** (N · F · C · B · A · M) + **4 영역 위계** (StatusBar 52px / TopStrip 158px / PlayerGrid 가변 / ActionPanel 124px) + **5-Act 시퀀스** (IDLE → PreFlop → Flop/Turn/River → Showdown → Settlement) 으로 재설계. 정본은 `docs/2. Development/2.4 Command Center/Command_Center_UI/Overview.md §3.0`, 외부 PRD 는 `docs/1. Product/Command_Center_PRD.md` v4.0.

### Option C — 이미지 교체

`images/foundation/app-command-center.png` 를 v4.0 PRD 의 스크린샷 (`images/cc/2026-05-07-redesign/01-idle-full.png` 또는 `02-preflop-full.png`) 으로 교체. 단, 색상은 다크 broadcast 톤이므로 Lobby B&W refined minimal 톤으로 재캡처 권장.

## SSOT 참조

- `docs/1. Product/Command_Center_PRD.md` v4.0 (외부 PRD)
- `docs/2. Development/2.4 Command Center/Command_Center_UI/Overview.md §3.0` (정본 SSOT)
- `docs/2. Development/2.4 Command Center/Command_Center_UI/UI.md §"v4.0 정체성"` (정본 SSOT)
- `docs/4. Operations/Cascade_Plan_S3_CC_2026-05-07.md` (cascade 계획)

## 권한 경계

- S3 (Command Center) 영역: `docs/2. Development/2.4 Command Center/**` — cascade 완료
- S1 (Foundation/Product) 영역: `docs/1. Product/**` — S1 자율 결정 (본 NOTIFY 는 알림만)

## Acceptance

S1 이 위 Option A/B/C 중 자율 선택 후 close. close 시 본 NOTIFY 의 status 를 `RESOLVED` 로 갱신.
