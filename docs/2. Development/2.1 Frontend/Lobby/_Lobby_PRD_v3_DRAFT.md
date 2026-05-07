---
title: "EBS Lobby — 김 운영자의 12 시간"
status: DRAFT (first 200 lines, 2026-05-07)
version: 3.0.0-draft.1
tier: external
audience: 외부 stakeholder + Lobby 개발자 (narrative ↔ 부록 분리)
narrative-spine: "09:30 ~ 18:50, 운영실의 하루"
supersedes: ./Lobby_PRD.md (v2.0.1)
last-updated: 2026-05-07
---

# EBS Lobby — 김 운영자의 12 시간

> **관제탑은 사람이다. 12 테이블의 모든 진실이 한 사람의 화면에 모이고, 거기서 흩어진다.**

오전 9시 30분, 운영실 문이 열린다. 의자에 앉기 전, 김 운영자는 12 개의 모니터를 차례로 본다. 그중 가운데 큰 화면 한 개가 **EBS Lobby**. 나머지 11 개는 각 테이블의 Command Center — Lobby 의 자식들이다.

이 문서는 그 12 시간을 따라간다.

![Lobby 한 개가 N 개 Command Center 를 동시에 본다 — 1:N 모니터링 관계](visual/screenshots/ebs-lobby-cc-relationship.png)

> *FIG · 운영실의 한 화면 (Lobby) ↔ 각 테이블 PC (CC N 개)*

---

## 이 문서가 데려가는 곳

<table role="presentation" width="100%">
<tr>
<td width="50%" valign="top" align="left">

**입구 — 지금 당신의 상태**

EBS 라는 단어를 들었습니다. RFID, Command Center, Featured Table 같은 말은 처음 봅니다. 누가 무엇을 어떻게 하는지 모릅니다.

</td>
<td width="50%" valign="top" align="left">

**출구 — 12 시간 후**

당신은 김 운영자가 09:30 부터 18:50 까지 어떤 화면을 보고, 어떤 알림에 어떻게 반응하고, 어떤 권한으로 무엇을 켜고 끄는지 머릿속에서 그릴 수 있습니다. 그리고 그 시스템을 직접 만들 수 있습니다.

</td>
</tr>
</table>

---

## 목차 — 12 시간

```
  09:00 ─┐
         │  PROLOGUE          운영실의 첫 빛
  10:30 ─┤
         │  ACT I             12 줄을 한 눈에 (셋업 → 방송 시작)
         │    Ch.1  09:55     124 줄이 한 화면에
         │    Ch.2  10:15     첫 알림 — #72 RFID Err
         │    Ch.3  10:28     [Launch ⚡] — 한 클릭의 4 가지
         │    Ch.4  10:30     Active CC 펄스가 켜진다
  14:00 ─┤
         │  ACT II            12 줄을 깊이 보기 (방송 중)
         │    Ch.5            Grid 일반 시야
         │    Ch.6            Floor Map = 몸이 어디 있나
         │    Ch.7            CC Focus = 한 테이블만 큰 화면
  14:32 ─┤
         │  ACT III           12 줄이 흔들릴 때
         │    Ch.8  14:32     #72 RFID desync — 알림 도착
         │    Ch.9  14:33     Mock 모드 — 방송은 멈추지 않는다
         │    Ch.10 14:35     Operator B idle 8분 — 권한이 작동한다
  18:30 ─┤
         │  ACT IV            12 줄을 닫는 법
         │    Ch.11 18:32     모든 테이블 COMPLETED
         │    Ch.12 18:45     Hand JSON Export — 142 hands 떠난다
  18:50 ─┘
         │  EPILOGUE          운영실의 마지막 빛

         부록 A~G              Lobby 개발자가 알아야 할 모든 것
```

> **이 문서의 약어**: BO (Back Office, 중앙 서버) · CC (Command Center, 테이블 PC 운영 화면) · RFID (무선 카드 인식) · NDI/SDI (방송 영상 신호) · LIVE/IDLE/ERROR (CC 3 상태). 부록 G 에 전체 사전.

---

# PROLOGUE — 운영실의 첫 빛

> *그가 의자에 앉기 전에, 12 모니터는 이미 무언가를 알고 있었다.*

09:30. 김 운영자가 운영실 문을 연다. 천장의 형광등이 깜빡이고, 12 모니터의 화면 보호기가 동시에 사라진다.

그가 의자에 앉기 전, 한 화면이 그를 부른다 — 가운데 큰 모니터, EBS Lobby. 나머지 11 모니터는 각 테이블의 PC, 즉 11 개의 Command Center 다.

오늘은 **WPS · EU 2026 / Event #5 — Europe Main Event / Day2** 의 진행 일이다. 1,807 명이 등록했고, 838 명이 재진입했고, 918 명이 살아남았다. 124 개의 테이블이 운영된다. 그중 3 개가 방송에 올라간다 — Featured Table.

이 124 개 테이블 중 어디에서 거대한 팟이 열리고, 어디에서 Featured Table 에 걸맞은 핸드가 펼쳐지고, 어디에서 RFID 리더가 desync 됐는지 — 김 운영자는 한 화면에서 알아야 한다.

> 그것이 Lobby 가 존재하는 이유다.

---

# ACT I — 12 줄을 한 눈에

> *셋업 30분, 방송 시작까지.*

## Ch.1 — 09:55 124 줄이 한 화면에

김 운영자가 EBS Lobby 의 사이드바에서 **Series** 를 누른다.

```
  Home  >  WPS · EU 2026  >  Event #5  >  Day2  >  Tables
```

세 번의 클릭 — Series 카드, Event 카드, Day2 — 끝에 화면 가득 124 줄이 펼쳐진다.

![124 테이블이 한 화면에 — KPI 5 + Levels strip + 9-seat grid + RFID/Deck/Out/CC 5 컬럼 + Waiting List 12](visual/screenshots/ebs-lobby-04-tables.png)

> *FIG · Tables 그리드 (Grid view) — 운영자가 가장 많이 보는 화면*

124 줄. 한 줄이 한 테이블이다. 김 운영자는 이 화면을 하루에 12 시간 본다.

### 한 줄 안에 담긴 진실

124 줄 중 가장 위, `#071 ★` 가 김 운영자의 시선을 끈다. **별표 (★) 는 Featured Table 의 표시** — 메인 카메라가 잡는 핵심 테이블이라는 뜻이다.

```
  +======================================================+
  | #071 ★ FT  | 1 2 3 4 5 6 7 8 9 | 9 | Rdy | 52/52 | NDI | LIVE · Op.A · #47 |
  +======================================================+
       │           │                  │      │       │     │       │
       │           │                  │      │       │     │       └ CC 운영자 + 진행 hand 번호
       │           │                  │      │       │     └ 출력 신호 (NDI / SDI)
       │           │                  │      │       └ 덱 등록 (52 장 매핑)
       │           │                  │      └ RFID 상태 (Rdy / Err / off)
       │           │                  └ 좌석 점유 합 (9/9)
       │           └ 9 좌석 (a 활성 / e 빈 / r 탈락 / d 딜러 / w 대기)
       └ 테이블 ID + Featured + 라이브 표시
```

이 한 줄이 한 테이블의 모든 진실을 압축한다. 김 운영자가 124 줄을 차례로 훑으면서 — 어느 줄이 빨갛게 깜빡이는지, 어느 줄이 노란 경고를 띠는지, 어느 줄이 LIVE 인 지 — 그것이 그의 일이다.

### 화면 위 4 줄의 KPI

124 줄 위에는 **KPI 5 박스** 가 있다.

| KPI | 값 | 의미 |
|------|------|------|
| Players | 918 / 919 | 살아남은 / 등록 (어젯밤 자정 기준) |
| Tables | 124 | 진행 중 |
| Waiting | 12 | 자리 기다리는 사람 (avg 3분) |
| Active CC | 3 / 12 | 방송 송출 중 (Featured 3 + 가능 12) |
| Avg Stack | 164,553 | 27.4 BB |

KPI 박스 아래에는 **Levels strip** 이 있다.

```
  Now · L17     6,000 / 12,000     ante 12,000 · 60min
  Next · L18    8,000 / 16,000     ante 16,000 · 60min
  L19          10,000 / 20,000     ante 20,000 · 60min
                                                          [L18 in 22:48]
```

지금 블라인드, 다음 블라인드, 그 다음 블라인드. 우측에 다음 레벨 시작까지 남은 시간. 22 분 48 초.

### 정상은 보이지 않게, 비정상만 강조한다

124 줄 중 **115 줄** 은 회색이다. 평범하게 IDLE — 아직 운영자가 할당되지 않은 셋업 전 상태. 김 운영자가 신경 쓰지 않아도 되는 줄.

그의 눈은 자동으로 다른 곳에 간다.
