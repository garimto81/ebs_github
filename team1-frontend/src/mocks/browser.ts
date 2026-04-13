// src/mocks/browser.ts — MSW 2.x browser worker setup.
// Started from src/boot/msw.ts when VITE_USE_MOCK=true.

import { setupWorker } from 'msw/browser';
import { handlers } from './handlers';

export const worker = setupWorker(...handlers);
