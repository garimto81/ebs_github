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
# 2026-04-28 — Flutter SDK explicit pin (PR #18 cascade — lobby-web 와 동일 pin 적용).
# 이전 :3.22.0 → 본 PR 시점 :3.41.7 (digest sha256:644e3cea...).
# 부동 :stable 금지 (build determinism). 변경 시 cascade 갭 (intl/Dart/web flag) 재검토.
FROM ghcr.io/cirruslabs/flutter:3.41.8 AS builder

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
      echo '{"DEMO_MODE":"true","BO_URL":"http://api.ebs.local","ENGINE_URL":"http://engine.ebs.local","LOBBY_URL":"http://lobby.ebs.local","APP_NAME":"EBS Command Center","APP_BUILD_CHANNEL":"stable"}' > "$ENV_FILE" ; \
    fi

# Release web build
# 2026-04-28 — Flutter stable (3.27+) 호환 cleanup (PR #17 cascade 동일):
#   --web-renderer=canvaskit  폐기 (build config 로 이전, Flutter 3.27+ 미지원)
#   --dart2js-optimization=O4 deprecation → 기본값
RUN flutter build web \
      --release \
      --tree-shake-icons \
      --dart-define-from-file="$ENV_FILE" \
      --source-maps \
      --output=build/web

# -----------------------------------------------------------------------------
# Stage 2: Serve
# -----------------------------------------------------------------------------
FROM nginx:1.29-alpine AS runtime

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
