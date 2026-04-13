// src/boot/msw.ts — MSW 2.x browser worker bootstrap
// Activated only when VITE_USE_MOCK=true in development.
// UI-A1 §6 Mock Server strategy.

import { defineBoot } from '#q-app/wrappers';

export default defineBoot(async () => {
  if (import.meta.env.VITE_USE_MOCK !== 'true') return;
  if (import.meta.env.PROD) return;

  try {
    const { worker } = await import('src/mocks/browser');
    await worker.start({
      onUnhandledRequest: 'bypass',
      serviceWorker: { url: '/mockServiceWorker.js' },
    });
    // eslint-disable-next-line no-console
    console.info('[MSW] worker started — using mock data');
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[MSW] failed to start worker', err);
  }
});
