// src/stores/settingsStore.ts — Pinia store for Settings 6 tabs.
// UI-A1 §3.3. Global config (not per-table) per feedback_settings_global.md.
//
// Each section is a Record<key, value> with a dirty flag and load status.
// Edits mutate the `draft` copy; save flushes draft → server → committed.

import { defineStore } from 'pinia';
import * as configsApi from 'src/api/configs';
import type { SettingsSection } from 'src/types/entities';
import type { WsEventEnvelope } from 'src/types/api';

type LoadStatus = 'idle' | 'loading' | 'success' | 'error' | 'saving';

interface SectionState {
  committed: Record<string, unknown>;
  draft: Record<string, unknown>;
  dirty: boolean;
  status: LoadStatus;
  error: string | null;
}

type SettingsState = Record<SettingsSection, SectionState>;

function emptySection(): SectionState {
  return {
    committed: {},
    draft: {},
    dirty: false,
    status: 'idle',
    error: null,
  };
}

export const useSettingsStore = defineStore('settings', {
  state: (): SettingsState => ({
    outputs: emptySection(),
    gfx: emptySection(),
    display: emptySection(),
    rules: emptySection(),
    stats: emptySection(),
    preferences: emptySection(),
  }),

  getters: {
    isAnyDirty(state): boolean {
      return Object.values(state).some((s) => s.dirty);
    },
  },

  actions: {
    async fetchSection(section: SettingsSection): Promise<void> {
      const s = this[section];
      s.status = 'loading';
      s.error = null;
      try {
        const res = await configsApi.getSection(section);
        if (res.data) {
          s.committed = { ...res.data };
          s.draft = { ...res.data };
          s.dirty = false;
          s.status = 'success';
        } else {
          s.status = 'error';
          s.error = res.error?.message ?? 'Failed';
        }
      } catch (err) {
        s.status = 'error';
        s.error = err instanceof Error ? err.message : 'Failed';
      }
    },

    updateField(section: SettingsSection, key: string, value: unknown): void {
      const s = this[section];
      s.draft[key] = value;
      s.dirty = JSON.stringify(s.draft) !== JSON.stringify(s.committed);
    },

    async saveSection(section: SettingsSection): Promise<void> {
      const s = this[section];
      if (!s.dirty) return;
      s.status = 'saving';
      s.error = null;
      try {
        const res = await configsApi.updateSection(section, s.draft);
        if (res.data || !res.error) {
          s.committed = { ...s.draft };
          s.dirty = false;
          s.status = 'success';
        } else {
          s.status = 'error';
          s.error = res.error?.message ?? 'Save failed';
        }
      } catch (err) {
        s.status = 'error';
        s.error = err instanceof Error ? err.message : 'Save failed';
      }
    },

    revertSection(section: SettingsSection): void {
      const s = this[section];
      s.draft = { ...s.committed };
      s.dirty = false;
    },

    /**
     * Apply a server-pushed config change (e.g. another operator saved).
     * Only overwrites if the current tab is not dirty (avoid trampling edits).
     */
    applyRemoteChange(event: WsEventEnvelope): void {
      if (event.event !== 'config.updated' && event.event !== 'config_changed') return;
      const payload = event.payload as {
        section: SettingsSection;
        key: string;
        value: unknown;
      } | undefined;
      if (!payload) return;

      const s = this[payload.section];
      if (!s) return;
      s.committed[payload.key] = payload.value;
      if (!s.dirty) {
        s.draft[payload.key] = payload.value;
      }
    },
  },
});
