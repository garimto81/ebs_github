# syntax=docker/dockerfile:1.7
#
# Phase 5 — lobby-web (team1 Flutter Web release).
# Multi-stage: Flutter SDK build → Nginx alpine serve.
# 결과 이미지 ≈ 28 MB (nginx:1.27-alpine 기반).

# -----------------------------------------------------------------------------
# Stage 1: Build
# -----------------------------------------------------------------------------
FROM ghcr.io/cirruslabs/flutter:3.22.0 AS builder

WORKDIR /app

# 의존성 캐시 레이어 분리 (pubspec 변경 시에만 재실행)
COPY pubspec.yaml pubspec.lock ./
COPY ../shared/ebs_common /shared/ebs_common
RUN flutter pub get

# 소스 복사 + codegen
COPY . .
RUN dart run build_runner build --delete-conflicting-outputs

# Production env (build-arg 로 주입)
ARG ENV_FILE=production.json
RUN if [ ! -f "$ENV_FILE" ]; then cp production.example.json "$ENV_FILE"; fi

# Release web build (gatekeeper 무시 — CI 단계가 별도 검증)
RUN flutter build web \
      --release \
      --web-renderer=html \
      --tree-shake-icons \
      --dart2js-optimization=O4 \
      --dart-define-from-file="$ENV_FILE" \
      --obfuscate \
      --split-debug-info=build/debug-info \
      --source-maps \
      --output=build/web

# -----------------------------------------------------------------------------
# Stage 2: Serve
# -----------------------------------------------------------------------------
FROM nginx:1.27-alpine AS runtime

# Healthcheck 도구 (alpine 기본은 없음)
RUN apk add --no-cache curl tini

# Static assets
COPY --from=builder /app/build/web /usr/share/nginx/html

# Nginx config (SPA fallback + caching + healthz)
COPY docker/lobby-web/nginx.conf /etc/nginx/conf.d/default.conf

# Sentry source map artefact (사이드카 — release 시 upload 후 제거)
COPY --from=builder /app/build/debug-info /opt/debug-info

# 비-root 실행 (nginx 1.20+ 는 nginx user 자동 존재)
RUN chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /var/log/nginx \
 && touch /var/run/nginx.pid \
 && chown nginx:nginx /var/run/nginx.pid

USER nginx

EXPOSE 3000

# tini = PID 1 (signal handling, zombie reaping)
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["nginx", "-g", "daemon off;"]

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/ || exit 1
