# ═══════════════════════════════════════════
# EBS Lobby — Multi-stage Dockerfile
# ═══════════════════════════════════════════
# Stages:
#   dev  — Vite dev server with HMR
#   prod — nginx serving static build

# ── Base ──────────────────────────────────
FROM node:20-alpine AS base

WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install

# ── Development ───────────────────────────
FROM base AS dev

# Source is bind-mounted in docker-compose, but copy for standalone build
COPY . .

EXPOSE 5173

# --host 0.0.0.0 으로 컨테이너 외부 접근 허용
CMD ["npx", "vite", "--host", "0.0.0.0", "--port", "5173"]

# ── Build (intermediate for prod) ─────────
FROM base AS build

COPY . .
RUN npm run build

# ── Production ────────────────────────────
FROM nginx:alpine AS prod

COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
