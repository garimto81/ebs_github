// src/stores/index.ts — Pinia store registry + Quasar-compatible factory.
//
// Quasar CLI auto-wires `src/stores/index.ts` as the app's Pinia host
// when it exists. Quasar's generated `.quasar/*/app.js` imports the
// default export and calls it as `createStore({})`, then `app.use(store)`.
// We therefore expose a factory that returns a fresh Pinia instance.
//
// Individual stores are defined via defineStore() in their own files
// (authStore.ts, lobbyStore.ts, ...) and consumed lazily via
// useXxxStore() inside setup functions. Importing this file does NOT
// instantiate them.
//
// UI-A1 §3.

import { createPinia } from 'pinia';
import type { Pinia } from 'pinia';

/**
 * Factory called by Quasar's generated bootstrap. Returns a fresh
 * Pinia instance. Quasar then `app.use(pinia)` internally — so we do
 * NOT also register Pinia inside a boot file (boot/pinia.ts is a no-op
 * guard kept for backwards compatibility during the store migration).
 */
export default function createStore(/* ssrContext */): Pinia {
  return createPinia();
}

export type StoreRegistry = {
  auth: 'useAuthStore';
  lobby: 'useLobbyStore';
  settings: 'useSettingsStore';
  ge: 'useGeStore';
  ws: 'useWsStore';
  nav: 'useNavStore';
};

/**
 * Boot-time eager stores (none currently — all stores lazy).
 */
export const eagerStores: Array<keyof StoreRegistry> = [];
