---
name: supabase-integration
description: >
  This skill should be used when the user needs Supabase project setup, database design, RLS policies, Edge Functions, or auth integration.
version: 2.0.0

triggers:
  keywords:
    - "supabase"
    - "RLS"
    - "Row Level Security"
    - "Edge Function"
    - "supabase auth"
    - "실시간 구독"
  file_patterns:
    - "supabase/**/*"
    - "**/supabase.ts"
    - "**/supabase.js"
    - "**/*.sql"
  context:
    - "Supabase 프로젝트 설정"
    - "데이터베이스 스키마 설계"
    - "인증 시스템 구축"

auto_trigger: true
---

# Supabase Integration Skill

Supabase 백엔드 서비스 통합을 위한 전문 스킬입니다.

## Quick Start

```bash
# Supabase CLI 설치
npm install -g supabase

# 프로젝트 초기화
supabase init

# 로컬 개발 환경 시작
supabase start

# 마이그레이션 생성
supabase migration new <migration_name>
```

## 환경 변수 설정

### API 키 시스템 (2025 업데이트)

> **중요**: Supabase가 새로운 키 시스템으로 전환 중입니다.
> - 2026년 말: 레거시 키(anon/service_role) 제거 예정
> - 신규 프로젝트는 새 키 사용 권장

| 키 타입 | 새 키 (권장) | 레거시 키 | 용도 |
|---------|-------------|----------|------|
| 클라이언트 | `sb_publishable_...` | `anon key` | 브라우저/앱 |
| 서버 | `sb_secret_...` | `service_role` | 백엔드 전용 |

### 새 키 vs 레거시 키 차이점

| 항목 | 새 키 | 레거시 키 |
|------|-------|----------|
| 형식 | `sb_publishable_...` | JWT (eyJhbG...) |
| 독립 로테이션 | ✅ 가능 | ❌ 불가 |
| 다운타임 없는 교체 | ✅ | ❌ |
| 모바일 앱 배포 | ✅ 용이 | ❌ 강제 업데이트 필요 |

### 필수 환경 변수

```bash
# 새 키 시스템 (권장)
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
SUPABASE_SECRET_KEY=sb_secret_...

# 레거시 키 (2026년까지 지원)
# NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbG...
# SUPABASE_SERVICE_ROLE_KEY=eyJhbG...
```

## 핵심 기능

### 1. 프로젝트 설정
프로젝트 구조, 초기화 설정

### 2. 데이터베이스 스키마 설계
테이블 생성, 관계 설정, 트리거

### 3. RLS (Row Level Security) 정책
RLS 활성화, 본인 데이터 접근, 공개/비공개 정책, 역할 기반 접근

### 4. Edge Functions
Deno 기반 서버리스 함수, 배포

### 5. 클라이언트 설정
TypeScript 클라이언트, 타입 생성

### 6. 인증 설정
이메일/패스워드, OAuth (Google, GitHub)

### 7. 실시간 구독
테이블 변경 감지, 실시간 업데이트

### 8. Storage 설정
버킷 생성, 파일 업로드, RLS 정책

## CLI 명령어 참조

| 명령어 | 용도 |
|--------|------|
| `supabase init` | 프로젝트 초기화 |
| `supabase start` | 로컬 환경 시작 |
| `supabase stop` | 로컬 환경 중지 |
| `supabase db reset` | DB 초기화 + 마이그레이션 재실행 |
| `supabase migration new <name>` | 새 마이그레이션 생성 |
| `supabase db push` | 로컬 변경사항 원격 적용 |
| `supabase db pull` | 원격 스키마 로컬로 가져오기 |
| `supabase gen types typescript` | TypeScript 타입 생성 |
| `supabase functions serve` | Edge Function 로컬 실행 |
| `supabase functions deploy` | Edge Function 배포 |

## 체크리스트

### 프로젝트 설정

- [ ] `supabase init` 실행
- [ ] `.env.local`에 URL, Publishable Key 설정 (또는 레거시 anon key)
- [ ] 클라이언트 라이브러리 설치 (`@supabase/supabase-js`)

### 데이터베이스

- [ ] 테이블 스키마 설계
- [ ] 외래 키 관계 설정
- [ ] 인덱스 추가 (자주 조회하는 컬럼)
- [ ] updated_at 트리거 설정

### 보안

- [ ] 모든 테이블 RLS 활성화
- [ ] SELECT/INSERT/UPDATE/DELETE 정책 설정
- [ ] 민감 데이터 접근 제한 확인
- [ ] Publishable vs Secret 키 구분 사용 (서버에만 Secret)

### 인증

- [ ] 인증 제공자 설정 (이메일, OAuth)
- [ ] 리다이렉트 URL 설정
- [ ] 회원가입 시 profiles 테이블 자동 생성 트리거

## Anti-Patterns

| 금지 | 이유 | 대안 |
|------|------|------|
| RLS 없이 배포 | 데이터 노출 위험 | 모든 테이블 RLS 활성화 |
| Secret 키 클라이언트 노출 | 전체 DB 접근 가능 | Publishable 키만 클라이언트 |
| 레거시 키 신규 사용 | 2026년 제거 예정 | 새 키 시스템 사용 |
| SQL 인젝션 가능한 쿼리 | 보안 취약점 | Supabase 클라이언트 사용 |
| 하드코딩된 환경 변수 | 키 유출 위험 | .env 파일 + .gitignore |

---

상세 코드 예시, SQL 패턴, 인증, 실시간, Storage, 트러블슈팅, 2025 신기능: `REFERENCE.md`
