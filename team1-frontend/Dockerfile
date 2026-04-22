# ═══════════════════════════════════════════════════════════════════
# EBS Lobby (team1-frontend) — nginx static serve + reverse proxy
# ═══════════════════════════════════════════════════════════════════
#
# 사전 준비 (필수):
#   cd team1-frontend
#   flutter pub get
#   dart run build_runner build --delete-conflicting-outputs
#   flutter build web --release --dart-define=USE_MOCK=false
#
# 빌드:
#   cd <repo root>
#   docker compose --profile web build --no-cache lobby-web
#
# 기동:
#   docker compose --profile web up -d lobby-web
#
# 접속:
#   http://<lan-ip>:3000/
#
# 설계 근거:
#   cc-web 서비스와 동일 패턴. 호스트에서 flutter build web 수행 후 산출물만
#   nginx 이미지에 COPY. Flutter SDK 를 컨테이너에 넣지 않아 빌드 시간 100x 단축
#   (SDK clone 10~20분 → COPY 수 초). 트레이드오프: 호스트에 Flutter SDK 필요.
#   EBS 는 개발자 로컬 머신에서 LAN 배포하는 운영 모델이므로 SDK 전제 OK.

FROM nginx:alpine

# 기본 nginx config 제거
RUN rm /etc/nginx/conf.d/default.conf

# 호스트에서 사전 빌드된 Flutter web 산출물 복사
# build context = repo root (docker-compose.yml build.context: .)
COPY team1-frontend/build/web /usr/share/nginx/html

# nginx config: SPA fallback + /api, /ws reverse proxy to bo:8000
COPY team1-frontend/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://127.0.0.1/healthz || exit 1

CMD ["nginx", "-g", "daemon off;"]
