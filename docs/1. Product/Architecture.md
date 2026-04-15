---
title: Architecture
owner: conductor
tier: internal
last-updated: 2026-04-15
---

# EBS Architecture

> stub — 상세 내용은 [Foundation.md](Foundation.md) "Architecture" 섹션 참조.

## 개요

EBS Core는 3 입력 → 실시간 오버레이 출력으로 정의된다:

```
WSOP LIVE(대회정보) + RFID(카드) + Command Center(액션) → Game Engine → Overlay Graphics
```

- **실시간 라이브 시스템** (경쟁: PokerGFX)
- **시간축 경계**: EBS = 실시간 라이브, 포스트프로덕션 ≠ EBS (경쟁: Adobe)
- **API 계층**: WSOP LIVE→API→EBS+소비자 / EBS→API→소비자 (단방향)
- **기술 스택**: Flutter + Rive (크로스 플랫폼), FastAPI Backend, Pure Dart Game Engine, Quasar Lobby

## 상세

[Foundation.md §Architecture](Foundation.md) 참조.

## 소프트웨어 컴포넌트 (5-App + 1 Feature Module)

| 컴포넌트 | 팀 | 기술 |
|----------|----|----|
| Lobby (+ Settings, Graphic Editor) | team1 | Quasar (Vue 3) |
| Backend (BO) | team2 | FastAPI |
| Game Engine | team3 | Pure Dart |
| Command Center | team4 | Flutter |
| Overlay (Skin Consumer) | team4 | Flutter + Rive |

## 화면 계층 (RBAC)

| 역할 | 권한 |
|------|------|
| Admin | 전체 |
| Operator | 할당 테이블 CC만 |
| Viewer | 읽기 전용 |
