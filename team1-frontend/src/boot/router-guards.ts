// src/boot/router-guards.ts — Vue Router beforeEach hooks
// - Auth guard (redirect to /login if required)
// - Bit Flag RBAC (CCR-017) permission check per meta.requiredPermission
// UI-A1 §2.2.

import { defineBoot } from '#q-app/wrappers';
import { useAuthStore } from 'stores/authStore';

type PermissionAction = 'Read' | 'Write' | 'Delete';

export default defineBoot(({ router }) => {
  router.beforeEach(async (to) => {
    const auth = useAuthStore();

    // public routes (login, forgot-password, 404)
    if (to.meta.public) return true;

    // Auth required
    if (to.meta.requiresAuth && !auth.isAuthenticated) {
      const restored = await auth.tryRestoreSession();
      if (!restored) {
        return { name: 'login', query: { redirect: to.fullPath } };
      }
    }

    // Resource-level permission (Bit Flag)
    const requiredPerm = to.meta.requiredPermission as string | undefined;
    if (requiredPerm) {
      const [resource, action] = requiredPerm.split(':') as [string, PermissionAction];
      if (!auth.hasPermission(resource, action)) {
        return { name: 'series-list' };
      }
    }

    // Document title
    const title = (to.meta.title as string | undefined) ?? 'EBS Lobby';
    if (typeof document !== 'undefined') {
      document.title = title === 'EBS Lobby' ? title : `${title} · EBS Lobby`;
    }

    return true;
  });
});
