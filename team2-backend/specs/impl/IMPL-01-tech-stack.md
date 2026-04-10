# IMPL-01 Tech Stack — 3-앱 기술 스택 선정 근거

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-08 | 신규 작성 | Lobby, CC, BO, Engine, Overlay 기술 스택 선정 근거 및 대안 기각 사유 |
| 2026-04-09 | TBD 해소 | Lobby 프레임워크 Next.js 15, 상태 관리 Zustand, UI shadcn/ui 확정 |
| 2026-04-09 | Docker 서버 기본화 | BO+Lobby Docker 컨테이너 통합 실행 명시 |

---

## 개요

이 문서는 EBS 3-앱 아키텍처(Lobby, Command Center, Back Office) + Game Engine + Overlay의 기술 스택 선정 근거를 기술한다. 각 컴포넌트별로 **선정 이유**, **대안 기각 사유**, **Phase별 진화 계획**을 명시한다.

> 참조: BS-00 §1 앱 아키텍처 용어, PRD-EBS_Foundation Ch.10 기술 스택

---

## 1. 아키텍처 요약

```
┌─ Docker Server ──────────────────────────┐
│ ┌─────────────┐  REST/WS  ┌────────────┐│  WS  ┌──────────────┐
│ │   Lobby     │ ────────→ │Back Office ││ ←──── │    CC        │
│ │  (Next.js)  │           │ (FastAPI)  ││       │  (Flutter)   │
│ └─────────────┘           └─────┬──────┘│       └──────┬───────┘
│                              SQLite DB   │              │
└──────────────────────────────────────────┘       ┌──────┴───────┐
                                                   │ Game Engine  │
                                                   │ (Dart pkg)   │
                                                   └──────┬───────┘
                                                          │
                                                   ┌──────┴───────┐
                                                   │   Overlay    │
                                                   │ (Flutter+Rive)│
                                                   └──────────────┘
```

---

## 2. Lobby — 웹 앱

### 2.1 선정 기술

| 항목 | 기술 | 버전 |
|------|------|------|
| 프레임워크 | **Next.js (App Router)** | 15.x |
| 상태 관리 | **Zustand** | 5.x |
| HTTP 클라이언트 | fetch (내장) | — |
| WebSocket | 네이티브 WebSocket API + Zustand store | — |
| 빌드 | Next.js 내장 (Turbopack) | — |
| UI 라이브러리 | shadcn/ui + Tailwind CSS 4.x | — |

### 2.2 선정 근거

| 근거 | 설명 |
|------|------|
| 브라우저 접근성 | 설치 없이 브라우저에서 접속. Admin/Viewer 진입 장벽 최소화 |
| CC와 기술 분리 | Lobby는 관제/설정 허브로 CC(Flutter)와 독립 배포 필요 |
| 웹 생태계 | 차트, 테이블, 대시보드 컴포넌트 풍부 |
| REST API 소비 | BO REST API와 자연스러운 연동 |

### 2.3 대안 기각

| 대안 | 기각 사유 |
|------|----------|
| Flutter Web | Lobby와 CC를 동일 기술로 통합 가능하나, Flutter Web은 SEO/초기 로딩/번들 크기에서 웹 네이티브 대비 열세. 관제 대시보드에 적합하지 않음 |
| Vue.js | 팀 내 React 경험이 더 풍부. 컴포넌트 생태계 규모 차이 |
| Angular | 소규모 프로젝트에 과도한 보일러플레이트. 학습 곡선 높음 |
| SvelteKit | 생태계 미성숙. Enterprise 레퍼런스 부족 |

### 2.4 결정 완료 사항 (2026-04-09)

| 항목 | 결정 | 근거 |
|------|------|------|
| React SPA vs Next.js | **Next.js 15 (App Router)** | 파일 기반 라우팅이 5계층 구조에 자연스러움. SSR 불필요하지만 라우팅/빌드/배포 통합이 실용적 |
| 상태 관리 라이브러리 | **Zustand 5.x** | 보일러플레이트 최소, WebSocket 상태 통합 용이. Context는 리렌더링 문제, Jotai는 atom 남발 위험 |
| HTTP 클라이언트 | **fetch (내장)** | Next.js와 자연스러운 통합. Axios 추가 의존성 불필요 |
| UI 라이브러리 | **shadcn/ui + Tailwind CSS** | 커스터마이징 자유도 높고 번들 경량. 방송 운영 대시보드에 적합 |

---

## 3. Command Center (CC) — Flutter 앱

### 3.1 선정 기술

| 항목 | 기술 | 버전 |
|------|------|------|
| 프레임워크 | Flutter | 3.x |
| 언어 | Dart | 3.x |
| 상태 관리 | Riverpod | 2.x |
| 라우팅 | go_router | 14.x |
| 애니메이션 | Rive | 최신 |
| RFID 통신 | dart:io (Serial) + HAL | — |
| 로컬 저장 | SharedPreferences / Hive | — |
| 보안 저장 | flutter_secure_storage | — |

### 3.2 선정 근거

| 근거 | 설명 |
|------|------|
| 크로스 플랫폼 | Windows, macOS, Linux 단일 코드베이스 빌드 |
| 네이티브 성능 | 하드웨어(RFID Serial UART) 직접 접근 가능 |
| Rive 통합 | 방송 오버레이 벡터 애니메이션 네이티브 지원 |
| Game Engine 공유 | 순수 Dart 패키지를 CC에 직접 import |
| Riverpod DI | Real/Mock HAL 교체를 Provider 오버라이드로 구현 |

### 3.3 대안 기각

| 대안 | 기각 사유 |
|------|----------|
| Electron (React) | 번들 크기 과대(200MB+), 메모리 소비 높음. 방송 현장 PC 리소스 제약 |
| .NET MAUI | Dart Engine과 언어 불일치. Rive 통합 미지원 |
| Qt / C++ | 개발 속도 느림. 크로스 플랫폼 UI 생산성 낮음 |
| Tauri (Rust) | Serial UART 생태계 미약. Rive 통합 없음 |

### 3.4 Riverpod 선정 근거

| 대안 | 기각 사유 |
|------|----------|
| Provider (legacy) | Riverpod이 공식 후속. 타입 안전성, 테스트 용이성 우위 |
| Bloc | 보일러플레이트 과다. 작은 상태 변경에도 Event/State 쌍 필요 |
| GetX | 마법(magic) 의존. 테스트 어려움, 대규모 앱 유지보수 부적합 |
| MobX | Dart 생태계에서 Riverpod 대비 레퍼런스 부족 |

---

## 4. Back Office (BO) — FastAPI 서버

### 4.1 선정 기술

| 항목 | 기술 | 버전 |
|------|------|------|
| 언어 | Python | 3.12+ |
| 프레임워크 | FastAPI | 0.115+ |
| ORM | SQLModel (SQLAlchemy 기반) | 0.0.22+ |
| DB | SQLite (Phase 1-2) → PostgreSQL (Phase 3+) | — |
| 마이그레이션 | Alembic | 1.13+ |
| ASGI 서버 | uvicorn | 0.30+ |
| 컨테이너 | Docker + docker-compose | 24+ |
| 인증 | python-jose (JWT) + passlib (bcrypt) | — |
| WebSocket | FastAPI WebSocket (Starlette 기반) | — |

### 4.2 선정 근거

| 근거 | 설명 |
|------|------|
| 비동기 네이티브 | async/await 기반. WebSocket + REST 동시 서빙 |
| 자동 문서화 | OpenAPI(Swagger) 자동 생성. CC/Lobby 개발자 즉시 참조 |
| SQLModel 통합 | Pydantic + SQLAlchemy 하이브리드. 스키마 ↔ API 모델 단일 정의 |
| Phase 전환 용이 | SQLite → PostgreSQL 마이그레이션이 SQLAlchemy 레벨에서 투명 |
| 빠른 개발 | Python 생태계. 프로토타이핑 → 프로덕션 전환 속도 |
| Docker 기본 실행 | 방송 현장에서 단일 `docker compose up`으로 서버 전체 실행. 환경 차이 없음 |

### 4.3 대안 기각

| 대안 | 기각 사유 |
|------|----------|
| Django REST Framework | 동기 기본. WebSocket 지원에 Channels 추가 필요. 관습 과다 |
| Express.js (Node) | Dart Engine과 언어 이중화. 타입 안전성 약함 |
| Dart Shelf/Serverpod | Dart 서버 생태계 미성숙. ORM/마이그레이션 도구 부족 |
| Go (Gin/Fiber) | 개발 속도 느림. ORM 생태계 약함 |
| NestJS (TypeScript) | CC(Dart)와 별개 TypeScript 관리. FastAPI 대비 장점 불분명 |

### 4.4 SQLite → PostgreSQL 전환 계획

| Phase | DB | 이유 |
|:-----:|:--:|------|
| 1-2 | SQLite | 단일 서버, 설정 무(zero config), 파일 기반 백업 용이 |
| 3+ | PostgreSQL | 동시 쓰기, 수평 확장, 전문 검색, TDE 암호화 |

> 전환은 Alembic 마이그레이션 + SQLAlchemy 엔진 교체로 수행. 코드 변경 최소.

---

## 5. Game Engine — 순수 Dart 패키지

### 5.1 선정 기술

| 항목 | 기술 |
|------|------|
| 언어 | Dart 3.x |
| 패키지 유형 | 순수 Dart (Flutter 의존 없음) |
| 설계 패턴 | Event Sourcing: `apply(GameState, Event) → GameState` |
| 테스트 | dart test (순수 유닛 테스트) |

### 5.2 선정 근거

| 근거 | 설명 |
|------|------|
| CC 직접 import | Flutter CC에서 패키지로 직접 사용. 네트워크 경유 없이 즉시 호출 |
| Flutter 독립 | UI 없는 순수 로직. CLI, 서버, 테스트 어디서든 실행 가능 |
| Event Sourcing | 모든 게임 상태 변경이 이벤트로 기록. 리플레이, 디버깅, 감사 용이 |
| 결정적 실행 | 동일 이벤트 시퀀스 → 동일 결과. 테스트 재현성 100% |

### 5.3 대안 기각

| 대안 | 기각 사유 |
|------|----------|
| Python Engine (BO 내장) | CC → BO 네트워크 왕복 추가. 오프라인 시 게임 불가. 지연 증가 |
| TypeScript Engine | CC(Dart)에서 직접 호출 불가. FFI 필요 |
| Rust Engine (FFI) | FFI 바인딩 복잡도. 디버깅 어려움. 성능 이점 불필요(게임 로직은 CPU 경량) |

---

## 6. Overlay — Flutter + Rive

### 6.1 선정 기술

| 항목 | 기술 |
|------|------|
| 프레임워크 | Flutter 3.x |
| 애니메이션 | Rive (.riv 파일) |
| 출력 | NDI SDK / HDMI (윈도우 캡처) |

### 6.2 선정 근거

| 근거 | 설명 |
|------|------|
| CC와 동일 기술 | Game Engine(Dart)을 직접 import. CC ↔ Overlay 상태 공유 자연스러움 |
| Rive 네이티브 | 60fps 벡터 애니메이션. 해상도 독립적 스케일링 |
| 크로마키 지원 | Flutter Window 투명 배경 → OBS/vMix 크로마키 합성 |
| 스킨 시스템 | .riv 파일 교체만으로 그래픽 테마 전환 |

### 6.3 대안 기각

| 대안 | 기각 사유 |
|------|----------|
| HTML/CSS Overlay (CEF) | 60fps 보장 어려움. 복잡 애니메이션 성능 부족 |
| Unity | 오버킬. 라이선스 비용. 방송 오버레이에 3D 엔진 불필요 |
| After Effects + NDI | 실시간 데이터 바인딩 불가. 템플릿 방식 한계 |
| Unreal Engine | Unity와 동일 사유 + 학습 곡선 극심 |

---

## 7. 공통 인프라

### 7.1 통신 프로토콜

| 구간 | 프로토콜 | 포맷 |
|------|---------|------|
| Lobby → BO | REST API (HTTPS) | JSON |
| Lobby ↔ BO | WebSocket (WSS) | JSON Envelope |
| CC ↔ BO | WebSocket (WSS) | JSON Envelope |
| CC ↔ RFID | Serial UART (115200 baud) | 바이너리 → HAL 변환 |

> 참조: API-05 §2 메시지 포맷, API-06 §1 JWT 토큰

### 7.2 인증

| 항목 | 기술 |
|------|------|
| Access Token | JWT (HS256), 15분 만료 |
| Refresh Token | JWT (HS256), 7일 만료 |
| 비밀번호 | bcrypt 해싱 |
| 2FA | TOTP (Phase 1) |

> 참조: API-06 §1~2

### 7.3 Phase별 기술 스택 진화

| Phase | Lobby | CC | BO | Engine | Overlay |
|:-----:|:-----:|:--:|:--:|:------:|:-------:|
| 1 | Next.js 15 | Flutter 3.x | FastAPI + SQLite | Dart 3.x | Flutter + Rive |
| 2 | 확정 | 동일 | + Google OAuth | 동일 | 동일 |
| 3+ | 동일 | 동일 | PostgreSQL + Entra ID | 동일 | 동일 |
| 5 | 동일 | 동일 | + AI 파이프라인 | + AI Advisor | 동일 |

---

## 8. 의존성 매트릭스

| 패키지/라이브러리 | 사용 앱 | 용도 |
|-----------------|---------|------|
| Riverpod | CC, Overlay | 상태 관리 + DI |
| go_router | CC | 라우팅 |
| Rive | CC, Overlay | 벡터 애니메이션 |
| flutter_secure_storage | CC | 토큰 보안 저장 |
| SQLModel | BO | ORM |
| Alembic | BO | DB 마이그레이션 |
| uvicorn | BO | ASGI 서버 |
| python-jose | BO | JWT 인코딩/디코딩 |
| passlib | BO | 비밀번호 해싱 |
| ebs_engine (내부) | CC, Overlay | Game Engine 순수 Dart 패키지 |
| ebs_models (내부) | CC, Overlay | 공유 데이터 모델 |
| ebs_api_client (내부) | CC, Overlay | BO API 클라이언트 |
