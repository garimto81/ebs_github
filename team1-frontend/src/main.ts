// NOTE — Quasar(vite mode)는 실제 런타임 엔트리로 `.quasar/client-entry.js`
// (Quasar CLI 가 자동 생성) 를 사용한다. 이 파일은 Quasar 가 직접 import 하지 않는다.
//
// 이 파일은 다음 목적으로 유지한다:
//   1. Vitest/Playwright 환경에서 Vue 앱을 수동 마운트해야 할 때 참조용 엔트리
//   2. 계약 문서 (UI-A1 §1.2) 가 참조하는 "main.ts" 를 placeholder 로 존재시키기
//   3. 향후 Electron/BEX 모드로 확장할 때 별도 엔트리로 재사용 가능
//
// 프로덕션/dev 빌드의 실제 부트 순서는 `quasar.config.js > boot` 에서 관리한다:
//   i18n → pinia → axios → ws-client → msw → router-guards

import { createApp, type App as VueApp } from 'vue';
import { createPinia } from 'pinia';
import { createRouter, createWebHistory, type Router } from 'vue-router';
import { Quasar, Notify, Dialog, Loading } from 'quasar';

import App from './App.vue';
import { routes } from './router/routes';

// Quasar Sass tokens + Material Icons
import '@quasar/extras/material-icons/material-icons.css';
import 'quasar/src/css/index.sass';

/**
 * Manually construct a router instance. Quasar 의 `defineRouter` wrapper 를
 * 사용하지 않는 context (Vitest, standalone harness) 에서만 사용한다.
 */
function createManualRouter(): Router {
  return createRouter({
    history: createWebHistory(),
    routes,
    scrollBehavior: () => ({ left: 0, top: 0 }),
  });
}

/**
 * Bootstrap the application manually.
 * Quasar CLI 바깥에서 (테스트 harness, Electron preload 등) Vue 앱을 독립적으로
 * 마운트해야 할 때 호출된다. Quasar dev/build 경로에서는 호출되지 않는다.
 */
export function bootstrap(root: string | Element = '#q-app'): VueApp {
  const app = createApp(App);

  app.use(createPinia());
  app.use(createManualRouter());

  app.use(Quasar, {
    plugins: { Notify, Dialog, Loading },
    config: {
      notify: { position: 'top-right', timeout: 3000 },
    },
  });

  app.mount(root);
  return app;
}

// 자동 실행 (Vite 가 이 파일을 엔트리로 쓰지 않으므로 side-effect 는 안전)
if (import.meta.env?.VITE_MANUAL_BOOTSTRAP === 'true') {
  bootstrap();
}
