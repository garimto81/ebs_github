// src/api/configs.ts — Settings section get/update (API-05).
// The server returns a flat { key: value } object per section; stores expose
// it as Record<string, unknown> with dirty tracking.

import { get, put } from './client';
import type { ApiResponse } from 'src/types/api';
import type { SettingsSection } from 'src/types/entities';

export function getSection(
  section: SettingsSection,
): Promise<ApiResponse<Record<string, unknown>>> {
  return get<Record<string, unknown>>(`/configs/${section}`);
}

export function updateSection(
  section: SettingsSection,
  values: Record<string, unknown>,
): Promise<ApiResponse<Record<string, unknown>>> {
  return put<Record<string, unknown>>(
    `/configs/${section}`,
    values as Record<string, string>,
  );
}

export function getAll(): Promise<
  ApiResponse<Record<SettingsSection, Record<string, unknown>>>
> {
  return get<Record<SettingsSection, Record<string, unknown>>>('/configs');
}
