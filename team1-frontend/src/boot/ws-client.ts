// src/boot/ws-client.ts — WebSocket client boot hook
// Connects after auth store rehydrates. seq validation (CCR-021) is inside wsStore.
// UI-A1 §5.

import { defineBoot } from '#q-app/wrappers';
import { useAuthStore } from 'stores/authStore';
import { useWsStore } from 'stores/wsStore';

export default defineBoot(({ router }) => {
  const auth = useAuthStore();
  const ws = useWsStore();

  // Connect after auth is ready
  router.afterEach(() => {
    if (auth.isAuthenticated && ws.status === 'disconnected') {
      ws.connect();
    }
  });

  // Disconnect on logout
  auth.$subscribe?.((_mutation, state) => {
    if (state.status !== 'authenticated' && ws.status !== 'disconnected') {
      ws.disconnect();
    }
  });
});
