---
name: vercel-deployment
description: >
  This skill should be used when the user needs Vercel deployment, Preview/Production environment management, Edge Functions, or CI/CD pipeline integration.
version: 2.0.0

triggers:
  keywords:
    - "vercel"
    - "vercel deploy"
    - "preview 배포"
    - "production 배포"
    - "Edge Function"
    - "serverless"
  file_patterns:
    - "vercel.json"
    - ".vercel/**/*"
    - "api/**/*.ts"
    - "api/**/*.js"
  context:
    - "Vercel 배포 설정"
    - "프로덕션 배포"
    - "서버리스 함수"

auto_trigger: true
---

# Vercel Deployment Skill

Vercel 배포 및 서버리스 인프라 관리를 위한 전문 스킬입니다.

## Quick Start

```bash
# Vercel CLI 설치
npm install -g vercel

# 로그인
vercel login

# 프로젝트 연결
vercel link

# 배포 (Preview)
vercel

# 배포 (Production)
vercel --prod
```

## 필수 환경 변수

| 변수 | 용도 | 획득 위치 |
|------|------|----------|
| `VERCEL_TOKEN` | CLI/API 인증 | Vercel > Settings > Tokens |
| `VERCEL_ORG_ID` | 조직 ID | `vercel link` 후 `.vercel/project.json` |
| `VERCEL_PROJECT_ID` | 프로젝트 ID | `vercel link` 후 `.vercel/project.json` |

## 핵심 CLI 명령어

| 명령어 | 용도 |
|--------|------|
| `vercel` | Preview 배포 |
| `vercel --prod` | Production 배포 |
| `vercel dev` | 로컬 개발 서버 |
| `vercel build` | 로컬 빌드 |
| `vercel deploy --prebuilt` | 빌드된 결과물 배포 |
| `vercel env ls` | 환경 변수 목록 |
| `vercel rollback` | 이전 배포로 롤백 |

## Anti-Patterns

| 금지 | 이유 | 대안 |
|------|------|------|
| 토큰 코드에 노출 | 보안 위험 | 환경 변수 사용 |
| Production 직접 배포 | 검증 누락 | Preview 먼저 테스트 |
| 환경 변수 하드코딩 | 환경별 분리 불가 | `vercel env` 사용 |
| `--force` 남용 | 캐시 무효화 | 필요시만 사용 |

## 연동

| 스킬/에이전트 | 연동 시점 |
|---------------|----------|
| `supabase-integration` | 백엔드 API 연결 |
| `github-engineer` | CI/CD 파이프라인 |
| `designer` | 프론트엔드 빌드 |
| `devops-engineer` | 인프라 설정 |

## 상세 참조

> 환경 변수 관리, vercel.json 설정, Serverless Functions, CI/CD 통합, 도메인 관리, 트러블슈팅 등 상세 가이드:
> **Read `references/deployment-guide.md`**
