// test/vitest.setup.ts — Vitest global setup
// - MSW server (node mode) for API mocking
// - Quasar plugin install for component tests
// - vue-i18n with ko locale
// Reference: QA-LOBBY-06-quasar-test-strategy.md §4.2

import { beforeAll, afterEach, afterAll } from 'vitest';
import { config } from '@vue/test-utils';
import { Quasar } from 'quasar';
import { createI18n } from 'vue-i18n';
import { server } from 'src/mocks/server';

// MSW lifecycle
beforeAll(() => server.listen({ onUnhandledRequest: 'warn' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

// Quasar plugin install
config.global.plugins = config.global.plugins || [];

try {
  const i18n = createI18n({ locale: 'ko', legacy: false, messages: { ko: {} } });
  config.global.plugins.push([Quasar, { plugins: {} }], i18n);
} catch {
  // Quasar or i18n not yet installed — setup skipped
}

// Common stubs
config.global.stubs = {
  'router-link': true,
  'router-view': true,
};
