// src/utils/permissions.ts — Bit Flag RBAC helpers (CCR-017).
// Permission is a number where each bit represents an allowed action:
//   bit 0 = Read  (1)
//   bit 1 = Write (2)
//   bit 2 = Delete(4)
// A user's permission map is `Record<resource, number>` — checked at router
// guard + template level via the authStore.hasPermission() wrapper.

import { Permission, type PermissionAction } from 'src/types/entities';

export { Permission } from 'src/types/entities';
export type { PermissionAction } from 'src/types/entities';

const ACTION_MASK: Record<PermissionAction, Permission> = {
  Read: Permission.Read,
  Write: Permission.Write,
  Delete: Permission.Delete,
};

/**
 * Return true when `perm` includes the bit for `action`.
 *
 * @example
 *   hasPermission(Permission.Read | Permission.Write, 'Read') // true
 *   hasPermission(Permission.Read, 'Delete')                  // false
 */
export function hasPermission(perm: number | undefined, action: PermissionAction): boolean {
  if (perm === undefined || perm === null) return false;
  const mask = ACTION_MASK[action];
  return (perm & mask) === mask;
}

/**
 * Higher-level check against a full permission map keyed by resource.
 *
 * @example
 *   checkResource({ Lobby: 3 }, 'Lobby', 'Write') // true  (3 = Read|Write)
 */
export function checkResource(
  perms: Record<string, number> | undefined,
  resource: string,
  action: PermissionAction,
): boolean {
  if (!perms) return false;
  return hasPermission(perms[resource], action);
}
