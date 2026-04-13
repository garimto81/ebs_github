// src/router/routes.ts — Vue Router routes definition
// Follows UI-A1-architecture.md §2.1 router tree.

import type { RouteRecordRaw } from 'vue-router';

export const routes: RouteRecordRaw[] = [
  // Login (public)
  {
    path: '/login',
    name: 'login',
    component: () => import('pages/LoginPage.vue'),
    meta: { public: true, title: 'Login' },
  },

  // Forgot Password flow (public)
  {
    path: '/forgot-password',
    name: 'forgot-password',
    component: () => import('pages/ForgotPasswordPage.vue'),
    meta: { public: true, title: 'Forgot Password' },
  },

  // Authenticated shell
  {
    path: '/',
    component: () => import('layouts/MainLayout.vue'),
    meta: { requiresAuth: true },
    children: [
      { path: '', redirect: '/series' },

      // 3계층 Lobby 네비게이션 + Player 독립 레이어 (UI-01 §화면 1~4)
      // Series → Event(Day) → Table (3계층 drill-down)
      { path: 'series', name: 'series-list', component: () => import('pages/SeriesListPage.vue') },
      { path: 'series/:seriesId/events', name: 'event-list', component: () => import('pages/EventListPage.vue'), props: true },
      { path: 'events/:eventId/tables', name: 'table-list', component: () => import('pages/TableListPage.vue'), props: true },
      // Legacy Flight route (backward compat — Event(Day)가 Flight를 흡수)
      { path: 'flights/:flightId/tables', redirect: to => `/events/${to.params.flightId}/tables` },
      { path: 'tables/:tableId', name: 'table-detail', component: () => import('pages/TableDetailPage.vue'), props: true },
      { path: 'hand-history/:tableId?', name: 'hand-history', component: () => import('pages/HandHistoryPage.vue'), props: true },

      // Player 독립 레이어 (Table 하위가 아닌 독립 경로)
      { path: 'players', name: 'player-list', component: () => import('pages/PlayerListPage.vue') },
      { path: 'players/:playerId', name: 'player-detail', component: () => import('pages/PlayerDetailPage.vue'), props: true },

      // Settings 6탭 (UI-03)
      {
        path: 'settings',
        component: () => import('pages/settings/SettingsLayout.vue'),
        meta: { requiredPermission: 'Settings:Read' },
        children: [
          { path: '', redirect: '/settings/outputs' },
          { path: 'outputs', name: 'settings-outputs', component: () => import('pages/settings/OutputsPage.vue') },
          { path: 'gfx', name: 'settings-gfx', component: () => import('pages/settings/GfxPage.vue') },
          { path: 'display', name: 'settings-display', component: () => import('pages/settings/DisplayPage.vue') },
          { path: 'rules', name: 'settings-rules', component: () => import('pages/settings/RulesPage.vue') },
          { path: 'stats', name: 'settings-stats', component: () => import('pages/settings/StatsPage.vue') },
          { path: 'preferences', name: 'settings-preferences', component: () => import('pages/settings/PreferencesPage.vue') },
        ],
      },

      // Graphic Editor 허브 (CCR-011, UI-04)
      {
        path: 'lobby/graphic-editor',
        name: 'ge-hub',
        component: () => import('pages/graphic-editor/GraphicEditorHubPage.vue'),
        meta: { requiredPermission: 'GraphicEditor:Read', title: 'Graphic Editor' },
      },
      {
        path: 'lobby/graphic-editor/:skinId',
        name: 'ge-detail',
        component: () => import('pages/graphic-editor/GraphicEditorDetailPage.vue'),
        props: true,
        meta: { requiredPermission: 'GraphicEditor:Read' },
      },
    ],
  },

  // 404
  {
    path: '/:pathMatch(.*)*',
    name: 'not-found',
    component: () => import('pages/NotFoundPage.vue'),
    meta: { public: true, title: 'Not Found' },
  },
];
