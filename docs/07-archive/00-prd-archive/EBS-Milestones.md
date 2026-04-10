# EBS 개발 마일스톤

> **Version**: 1.0.0
> **Date**: 2026-03-31
> **원본**: [PRD-EBS_Foundation.md](PRD-EBS_Foundation.md) v33.1.0에서 분리

---

## 2026 (H1 + H2)

```mermaid
flowchart TD
    subgraph H1["2026 H1 (12~5월) — 인프라 POC"]
        R["RFID 하드웨어<br/>12대 리더 연결"]
        S1["서버 기초<br/>세션 관리"]
    end
    subgraph H2["2026 H2 (7~12월) — Hold'em 완벽 완성 → 2027-01 런칭"]
        Z["EBS Zero<br/>방송 지원 + Key Player"]
        E["게임 엔진<br/>Hold'em"]
        S2["EBS 서버"]
        subgraph UI["UI 3종"]
            C["Console"]
            K["RIVE 1단계<br/>(.riv 직접 임포트)"]
            A["Command Center"]
        end
        subgraph EX["추가 개발 @"]
            HE["승률 계산<br/>Monte Carlo"]
            GR["등급 엔진<br/>A/B/C 판정"]
            JE["JSON Export<br/>★ L1 최종"]
            MC["수동 카드 입력<br/>RFID 폴백"]
        end
    end
    R --> E
    S1 --> S2
    S2 --> UI
    S2 --> EX
```

## 2027-2030 (전체 조감도)

```mermaid
flowchart TD
    subgraph Y27H1["2027 H1 — 9종 확장 + Vegas"]
        G22["9종 게임 확장<br/>HORSE + 8-Game"]
        VGS["Vegas 이벤트<br/>2027-06"]
    end
    subgraph Y27H2["2027 H2 — 스킨 에디터 + BO"]
        SK["스킨 에디터 2단계<br/>자체 에디터"]
        BO["Back Office<br/>관리 시스템"]
        WS["WSOPLIVE 연동<br/>선수·대회 동기화"]
    end
    G22 --> SK
    VGS --> BO
    SK --> WS
```

```mermaid
flowchart TD
    subgraph Y28["2028 H1 — 프로덕션"]
        PROD["모든 기능<br/>EBS 대체"]
        VEGAS["Vegas 투입<br/>WSOP 메인"]
    end
    subgraph Y29["2029 — AI 무인화"]
        CAM["카메라 AI<br/>자동 전환"]
        VIS["액션 감지 AI<br/>하이라이트 마킹"]
        OPR["운영자 AI<br/>AT 자동화"]
        MON["편성 AI<br/>스케줄 무인화"]
    end
    PROD --> CAM
    VEGAS --> VIS
```

## 5개년 요약

| 기간 | 핵심 목표 | System | 파이프라인 | 비즈니스 마일스톤 |
|:----:|----------|:------:|:---------:|-----------------|
| 26 H1 | RFID POC + 기초 서버 | SYSTEM 1 | L0 | 인프라 POC 완료 |
| 26 H2 | Hold'em 완벽 완성 → **2027-01 런칭** | SYSTEM 1 | L0→L1 | Hold'em 1종 프로덕션 런칭 |
| 27 H1 | 9종 게임 확장 → **2027-06 Vegas** | SYSTEM 1 | L1→L2 | Vegas 이벤트 투입 (HORSE+8-Game) |
| 27 H2 | 13종 추가 + 스킨 에디터(2단계) + BO + WSOPLIVE | SYSTEM 1 | L2→L5 | 22종 완성 + 자체 에디터 + 백오피스 |
| 28 H1 | **프로덕션** — AI 4개 영역 무인화 | SYSTEM 2 | AI 주입 | 프로덕션 AI 무인화 |
| 28 H2 | OTT HLS/VOD 런칭 | SYSTEM 3 | 배포 | OTT 콘텐츠 배포 |

---

## Changelog

| 버전 | 날짜 | 변경 내용 |
|------|------|-----------|
| 1.0.0 | 2026-03-31 | Foundation PRD v33.1.0에서 분리 |
