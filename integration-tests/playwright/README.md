# Playwright E2E (V9.5 P14 scaffold)

> Conductor 소유. browser-level 통합 테스트. **scaffold only — 실제 실행 환경 설정은 별도 cycle.**

## 위치

- `playwright.config.ts` — 기본 설정 (chromium, baseURL=lobby-web)
- `tests/` — spec 시나리오
  - `v95-blind-levels-flow.spec.ts` — V9.5 P2+P3+P7 통합 검증 (admin 로그인 → BS 생성 → Levels CRUD → logout)
- `package.json` — 최소 deps (`@playwright/test`, `typescript`)

## 사전 요구

| 항목 | 설명 |
|------|------|
| Node.js | v18+ 권장 |
| BO container | `http://localhost:8000` healthy (team2) |
| lobby-web container | `http://localhost:3000` healthy (team1) |
| admin 계정 | `admin@ebs.test` / `test-password-1234` (또는 env override) |

`docker ps` 로 `ebs-bo`, `ebs-lobby-web` 컨테이너 healthy 상태 확인. 운영 절차: `docs/4. Operations/Docker_Runtime.md`.

## 환경 설정 (별도 cycle 에서 수행)

```bash
cd integration-tests/playwright

# 1. deps 설치
npm install

# 2. 브라우저 binary 설치 (chromium 만)
npx playwright install chromium
```

## 실행

```bash
# headless
npm test

# headed (브라우저 창 표시)
npm run test:headed

# HTML report 보기 (실행 후)
npm run report
```

## 환경 변수 override

| 변수 | 기본값 | 용도 |
|------|--------|------|
| `LOBBY_BASE_URL` | `http://localhost:3000` | Playwright `baseURL` |
| `BO_BASE_URL` | `http://localhost:8000` | API request 대상 |
| `ADMIN_USERNAME` | `admin@ebs.test` | 로그인 계정 |
| `ADMIN_PASSWORD` | `test-password-1234` | 로그인 비밀번호 |
| `CI` | (unset) | true 시 retries=2, forbidOnly=true |

## V9.5 cycle 정합 검증 매핑

| Spec step | 검증 대상 | V9.5 phase |
|-----------|-----------|------------|
| Step 1 (login) | POST /auth/login + access_token shape | 기존 contract |
| Step 2 (BS create) | POST /blind-structures (flat path) | P8 drift 0 |
| Step 3 (POST level) | POST /blind-structures/{bs_id}/levels | **P3 신규** |
| Step 4 (list) | GET /blind-structures/{bs_id}/levels | **P3 신규** |
| Step 5 (PUT) | PUT /blind-structures/{bs_id}/levels/{id} (partial) | **P3 신규** |
| Step 6 (DELETE level) | DELETE /blind-structures/{bs_id}/levels/{id} | **P3 신규** |
| Step 7 (cleanup BS) | DELETE /blind-structures/{bs_id} | 기존 contract |
| Step 8 (logout) | POST /auth/logout (DELETE /auth/session 폐기) | **P2 fix** |

## scaffold 범위 제한 (V9.5 정신 — 분량 control)

- ✅ config + 1 시나리오 + README + package.json
- ❌ npm install 실행 (별도 cycle)
- ❌ `npx playwright install` 실행 (별도 cycle)
- ❌ Frontend UI page object 작성 (API-level request fixture 만)
- ❌ 추가 deps (lighthouse, allure 등)
- ❌ CI workflow yaml 추가 (별도 P15+)

## 다음 cycle 후속 작업 (P15+ 후보)

1. `npm install` + `npx playwright install chromium` 실행
2. UI page object pattern 도입 (`pages/LobbyPage.ts`, `pages/CCPage.ts`)
3. 추가 시나리오: CC 런치 / RFID deck register / Overlay broadcast
4. CI workflow `.github/workflows/playwright.yml` (PR trigger)
5. Visual regression (screenshot baseline)

---

**관련 문서**:
- 상위 `../README.md` — integration-tests 전반 규칙
- `../scenarios/40-v95-blind-levels-flow.http` — REST Client 기반 동등 시나리오 (P9)
- `docs/4. Operations/Docker_Runtime.md` — 컨테이너 운영 절차
