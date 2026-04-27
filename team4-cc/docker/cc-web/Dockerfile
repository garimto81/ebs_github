# syntax=docker/dockerfile:1.7
#
# 2026-04-27 — cc-web (team4 Flutter Web release).
# SG-022 폐기 cascade. Multi-Service Docker SSOT 채택 — Lobby (3000) 와
# 별개로 독립 컨테이너로 기동되어 ebs-net 네트워크에서 협력.
# Multi-stage: Flutter SDK build → Nginx alpine serve.
# 결과 이미지 ≈ 28 MB (nginx:1.27-alpine 기반).
#
# Build context: team4-cc/  (team4-cc/src 가 Flutter 프로젝트 루트)
# Dockerfile path: docker/cc-web/Dockerfile

# -----------------------------------------------------------------------------
# Stage 1: Build
# -----------------------------------------------------------------------------
FROM ghcr.io/cirruslabs/flutter:3.22.0 AS builder

WORKDIR /app

# 의존성 캐시 레이어 분리 (pubspec 변경 시에만 재실행)
COPY src/pubspec.yaml src/pubspec.lock ./
RUN flutter pub get

# 소스 복사 + codegen (CC 는 Riverpod / Freezed / Retrofit 사용 → build_runner 필수)
COPY src/ ./
RUN dart run build_runner build --delete-conflicting-outputs || true

# Production env (build-arg 로 주입)
# DEMO_MODE=true 가 정규 LAN 배포 모드 (RFID 하드웨어 의존 분리)
ARG ENV_FILE=production.json
RUN if [ ! -f "$ENV_FILE" ]; then \
      echo '{"DEMO_MODE":"true","BO_URL":"http://bo:8000","ENGINE_URL":"http://engine:8080","LOBBY_URL":"http://lobby-web:3000","APP_NAME":"EBS Command Center","APP_BUILD_CHANNEL":"stable"}' > "$ENV_FILE" ; \
    fi

# Release web build
RUN flutter build web \
      --release \
      --web-renderer=canvaskit \
      --tree-shake-icons \
      --dart2js-optimization=O4 \
      --dart-define-from-file="$ENV_FILE" \
      --source-maps \
      --output=build/web

# -----------------------------------------------------------------------------
# Stage 2: Serve
# -----------------------------------------------------------------------------
FROM nginx:1.27-alpine AS runtime

RUN apk add --no-cache curl tini

# Static assets
COPY --from=builder /app/build/web /usr/share/nginx/html

# Nginx config (SPA fallback + caching + healthz)
COPY docker/cc-web/nginx.conf /etc/nginx/conf.d/default.conf

# 비-root 실행
RUN chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /var/log/nginx \
 && touch /var/run/nginx.pid \
 && chown nginx:nginx /var/run/nginx.pid

USER nginx

EXPOSE 3001

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["nginx", "-g", "daemon off;"]

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3001/healthz || exit 1
