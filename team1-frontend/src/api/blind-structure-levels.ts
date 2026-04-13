// src/api/blind-structure-levels.ts — Blind Level CRUD (ported from ebs_lobby-react/api/blind-structure-levels.ts)

import { get, post, put, del } from './client';
import type { BlindStructureLevel } from 'src/types/models';
import type { ApiResponse } from 'src/types/api';

export function list(
  blindStructureId: number,
): Promise<ApiResponse<BlindStructureLevel[]>> {
  return get<BlindStructureLevel[]>(
    `/blind-structures/${blindStructureId}/levels`,
  );
}

export function create(
  blindStructureId: number,
  data: Partial<BlindStructureLevel>,
): Promise<ApiResponse<BlindStructureLevel>> {
  return post<BlindStructureLevel>(
    `/blind-structures/${blindStructureId}/levels`,
    data,
  );
}

export function update(
  blindStructureId: number,
  levelId: number,
  data: Partial<BlindStructureLevel>,
): Promise<ApiResponse<BlindStructureLevel>> {
  return put<BlindStructureLevel>(
    `/blind-structures/${blindStructureId}/levels/${levelId}`,
    data,
  );
}

export function remove(
  blindStructureId: number,
  levelId: number,
): Promise<ApiResponse<null>> {
  return del<null>(
    `/blind-structures/${blindStructureId}/levels/${levelId}`,
  );
}
