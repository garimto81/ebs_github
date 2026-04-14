// src/boot/pinia.ts — NO-OP (superseded by src/stores/index.ts default export).
//
// Quasar CLI automatically wires the Pinia instance from
// `src/stores/index.ts` default export (see .quasar/*/app.js). Registering
// Pinia a second time here would double-install the plugin and produce
// warnings. This boot file is kept in the pipeline only so that the
// order in quasar.config.js (`boot: ['i18n', 'pinia', 'axios', …]`)
// stays stable while other boot files are written; it performs nothing.

import { defineBoot } from '#q-app/wrappers';

export default defineBoot(() => {
  // Intentionally empty — Pinia is installed by Quasar via
  // src/stores/index.ts default factory.
});
