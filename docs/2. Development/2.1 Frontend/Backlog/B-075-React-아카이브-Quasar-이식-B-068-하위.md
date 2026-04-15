---
id: B-075
title: React 아카이브 → Quasar 이식 (B-068 하위)
status: PENDING
source: docs/2. Development/2.1 Frontend/Backlog.md
---

# [B-075] React 아카이브 → Quasar 이식 (B-068 하위)
- **날짜**: 2026-04-10
- **teams**: [team1]
- **설명**: `C:/claude/ebs-archive-backup/07-archive/legacy-repos/ebs_lobby-react/` 의 9 pages + 19 api modules + 2 Zustand stores + mock-handler 를 Quasar (Vue 3) + Pinia + MSW 2.x 로 이식. JSX→Vue template, react-router→vue-router, Zustand `create()`→Pinia `defineStore()`, `useNavigate`→`useRouter` 변환.
- **수락 기준**: `src/pages/*.vue`, `src/stores/*.ts`, `src/api/*.ts`, `src/mocks/*` 모두 존재. `pnpm dev` 시 MSW 활성화 + Login → Series 플로우 동작.
- **관련 PRD**: `UI-A1-architecture.md` §1.2/§2/§3, `UI-01-lobby.md`, `UI-03-settings.md`, `UI-04-graphic-editor.md`
- **블로커**: B-068 완료 선행 필수
