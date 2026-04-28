# ── Stage 1: Build ────────────────────────────────────────────────────────────
FROM dart:stable AS build

WORKDIR /app

# Cache pub dependencies
COPY pubspec.yaml ./
COPY pubspec.lock* ./
RUN dart pub get

# Copy source
COPY . .

# Compile binaries (AOT)
RUN dart compile exe bin/harness.dart -o /app/bin/harness_exe
RUN dart compile exe bin/replay.dart  -o /app/bin/replay_exe

# ── Stage 2: Runtime ───────────────────────────────────────────────────────────
FROM debian:bookworm-slim

# ca-certificates: HTTPS 호출용
# curl: docker HEALTHCHECK 호출용 (compose engine.healthcheck → /health 200 검증)
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy compiled binaries
COPY --from=build /app/bin/harness_exe /app/harness
COPY --from=build /app/bin/replay_exe  /app/replay

# Copy static web assets
COPY lib/harness/web/ /app/web/

EXPOSE 8080

CMD ["/app/harness", "--port", "8080"]
