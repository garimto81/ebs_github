/* eslint-env node */
// Quasar 2 configuration — Vite mode
// Refer to: https://v2.quasar.dev/quasar-cli-vite/quasar-config-js

import { defineConfig } from '#q-app/wrappers';

export default defineConfig((ctx) => {
  return {
    // App boot files (/src/boot) — executed before root component instantiation
    boot: [
      'i18n',         // vue-i18n setup (ko/en/es)
      'pinia',        // createPinia() + store hydration
      'axios',        // API client wrapper (CCR-019 Idempotency-Key interceptor)
      'ws-client',    // WebSocket client (CCR-021 seq validation)
      'msw',          // MSW worker (dev only if VITE_USE_MOCK=true)
      'router-guards' // Vue Router beforeEach (auth + RBAC)
    ],

    // Global CSS
    css: ['app.scss'],

    // Icons & fonts
    extras: [
      'material-icons',
      'mdi-v7'
    ],

    // Build settings
    build: {
      target: {
        browser: ['es2022', 'chrome115', 'firefox115', 'safari16'],
        node: 'node20'
      },
      typescript: {
        strict: true,
        vueShim: true
      },
      vueRouterMode: 'history', // URL 에 # 없음
      env: {
        // 런타임 접근 가능한 public env (PROD)
        APP_VERSION: require('./package.json').version
      },
      extendViteConf(viteConf) {
        // Vitest 셋업 시 참조
        viteConf.test = viteConf.test || {};
      }
    },

    // Dev server
    devServer: {
      open: false,
      port: 9000,
      proxy: {
        // Real backend 전환 시 사용 (VITE_USE_MOCK=false)
        '/api': {
          target: 'http://localhost:8000',
          changeOrigin: true
        },
        '/ws': {
          target: 'ws://localhost:8000',
          ws: true,
          changeOrigin: true
        }
      }
    },

    // Quasar framework config
    framework: {
      config: {
        notify: {
          position: 'top-right',
          timeout: 3000,
          textColor: 'white'
        },
        loading: {}
      },
      iconSet: 'material-icons',
      lang: 'ko-KR',
      cssAddon: true,

      // Components, directives, plugins (tree-shake)
      components: [
        'QLayout', 'QHeader', 'QDrawer', 'QPageContainer', 'QPage', 'QFooter',
        'QToolbar', 'QToolbarTitle', 'QBtn', 'QBtnDropdown',
        'QInput', 'QSelect', 'QCheckbox', 'QRadio', 'QToggle', 'QSlider', 'QFile',
        'QDate', 'QTime', 'QPopupProxy',
        'QCard', 'QCardSection', 'QCardActions',
        'QList', 'QItem', 'QItemSection', 'QItemLabel', 'QSeparator',
        'QTable', 'QTh', 'QTr', 'QTd',
        'QTabs', 'QTab', 'QTabPanels', 'QTabPanel', 'QRouteTab',
        'QDialog', 'QTooltip', 'QBadge', 'QChip', 'QAvatar',
        'QLinearProgress', 'QCircularProgress', 'QSkeleton', 'QSpinner',
        'QBanner', 'QIcon', 'QImg', 'QForm'
      ],
      directives: ['Ripple', 'ClosePopup'],
      plugins: ['Notify', 'Dialog', 'Loading', 'LocalStorage', 'SessionStorage']
    },

    animations: [],

    // SSR / PWA / BEX / Electron 모드는 비활성
    ssr: { pwa: false, prodPort: 3000 },
    pwa: { workboxMode: 'GenerateSW' },
    cordova: {},
    capacitor: { hideSplashscreen: true },
    electron: { preloadScripts: ['electron-preload'], inspectPort: 5858, bundler: 'packager' },
    bex: { contentScripts: ['my-content-script'] }
  };
});
