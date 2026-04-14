// src/mocks/server.ts — MSW 2.x Node server setup for Vitest.
// Usage in tests:
//   import { server } from 'src/mocks/server';
//   beforeAll(() => server.listen());
//   afterEach(() => server.resetHandlers());
//   afterAll(() => server.close());

import { setupServer } from 'msw/node';
import { handlers } from './handlers';

export const server = setupServer(...handlers);
