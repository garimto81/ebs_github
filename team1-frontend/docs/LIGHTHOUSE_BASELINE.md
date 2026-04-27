# Lighthouse Baseline — team1-frontend (Phase 5)

## 목적

Phase 5 production 빌드의 Web 성능/접근성 baseline 을 고정하고, 회귀 시 CI 가 자동 차단한다.

## 사전 조건

- `lobby-web` Docker 이미지 빌드 완료 (`docker compose --profile web build lobby-web`)
- `@lhci/cli` 글로벌 설치: `npm install -g @lhci/cli@0.13.x`
- ChromeDriver / Chrome stable

## 측정 절차

```bash
# 1) 컨테이너 기동
docker compose --profile web up -d lobby-web

# 2) 헬스체크 대기
until curl -fsS http://localhost:3000/healthz; do sleep 1; done

# 3) Lighthouse CI 실행 (3 runs, median 채택)
lhci autorun --config=lighthouserc.json

# 4) 결과 확인
ls -la .lighthouseci/
open .lighthouseci/lhr-*.html   # 또는 GitHub Actions artifact 다운로드
```

## Phase 5 측정 baseline (2026-04-27)

| 카테고리 | Score | 임계 | 결과 |
|---------|:-----:|:----:|:----:|
| Performance | 82 | ≥75 | PASS |
| Accessibility | 94 | ≥90 | PASS |
| Best Practices | 88 | ≥85 | PASS |
| SEO | n/a | off | — |

| Metric | 값 | 임계 | 결과 |
|--------|----|----|:----:|
| FCP (First Contentful Paint) | 1.6s | <2.0s | PASS |
| TTI (Time to Interactive) | 3.4s | <4.0s | PASS |
| TBT (Total Blocking Time) | 210ms | <300ms | PASS |
| CLS (Cumulative Layout Shift) | 0.04 | <0.10 | PASS |

> Bundle size 변동 ±5% / Lighthouse score ±3 점 이상 변화 시 PR 차단 정책 권장.

## CI 통합 (참고)

`.github/workflows/team1-lighthouse.yml` 을 별도 PR 로 추가:

```yaml
- name: Lighthouse CI
  run: |
    npm install -g @lhci/cli@0.13.x
    lhci autorun --config=team1-frontend/lighthouserc.json
- uses: actions/upload-artifact@v4
  with:
    name: lighthouse-report
    path: .lighthouseci/
```

## 알려진 한계

- Web renderer = `html` (CanvasKit 보다 가볍지만 vector 그래픽은 SVG 의존). Rive 프리뷰가 포함된 GE 화면은 별도 측정 필요.
- desktop preset 만 적용. mobile 측정은 향후 PWA 전환 시 추가.
