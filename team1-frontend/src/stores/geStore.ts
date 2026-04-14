// src/stores/geStore.ts — Graphic Editor store (CCR-011, UI-04, API-07).
// State for the Lobby Graphic Editor hub:
//   - skins list + selectedSkinId
//   - metadata draft with dirty tracking (title, description, tags, author)
//   - upload progress
//   - validation errors from the server
//   - preview state (rive file URL, paused flag)
//   - activation state (which skin is live)
//
// UI-A1 §3.4.

import { defineStore } from 'pinia';
import * as skinsApi from 'src/api/skins';
import type { Skin, SkinMetadata } from 'src/types/entities';
import type { WsEventEnvelope } from 'src/types/api';

type LoadStatus = 'idle' | 'loading' | 'success' | 'error';
type UploadStatus = 'idle' | 'uploading' | 'validating' | 'ready' | 'error';

interface GeState {
  skins: Record<number, Skin>;
  selectedSkinId: number | null;

  metadataDraft: SkinMetadata | null;
  metadataDirty: boolean;

  uploadStatus: UploadStatus;
  uploadProgress: number; // 0..100
  validationErrors: string[];

  previewUrl: string | null;
  previewPaused: boolean;

  activeSkinId: number | null;
  activationPending: boolean;

  status: LoadStatus;
  error: string | null;
}

export const useGeStore = defineStore('ge', {
  state: (): GeState => ({
    skins: {},
    selectedSkinId: null,

    metadataDraft: null,
    metadataDirty: false,

    uploadStatus: 'idle',
    uploadProgress: 0,
    validationErrors: [],

    previewUrl: null,
    previewPaused: false,

    activeSkinId: null,
    activationPending: false,

    status: 'idle',
    error: null,
  }),

  getters: {
    skinsList(state): Skin[] {
      return Object.values(state.skins);
    },
    selectedSkin(state): Skin | null {
      return state.selectedSkinId != null ? state.skins[state.selectedSkinId] ?? null : null;
    },
  },

  actions: {
    async fetchSkins(): Promise<void> {
      this.status = 'loading';
      this.error = null;
      try {
        const res = await skinsApi.list();
        if (res.data) {
          this.skins = Object.fromEntries(res.data.map((s) => [s.skin_id, s]));
          const active = res.data.find((s) => s.status === 'active');
          this.activeSkinId = active?.skin_id ?? null;
          this.status = 'success';
        } else {
          this.status = 'error';
          this.error = res.error?.message ?? 'Failed';
        }
      } catch (err) {
        this.status = 'error';
        this.error = err instanceof Error ? err.message : 'Failed';
      }
    },

    selectSkin(id: number | null): void {
      this.selectedSkinId = id;
      if (id == null) {
        this.metadataDraft = null;
        this.metadataDirty = false;
        this.previewUrl = null;
        return;
      }
      const skin = this.skins[id];
      if (skin) {
        this.metadataDraft = { ...skin.metadata };
        this.metadataDirty = false;
        this.previewUrl = skin.preview_url;
      }
    },

    async uploadSkin(file: File): Promise<void> {
      this.uploadStatus = 'uploading';
      this.uploadProgress = 0;
      this.validationErrors = [];
      try {
        const res = await skinsApi.upload(file, (pct) => {
          this.uploadProgress = pct;
        });
        if (res.data) {
          this.skins[res.data.skin_id] = res.data;
          this.uploadStatus = 'ready';
          this.selectSkin(res.data.skin_id);
        } else {
          this.uploadStatus = 'error';
          this.validationErrors = res.error?.details as string[] | undefined ?? [];
          this.error = res.error?.message ?? 'Upload failed';
        }
      } catch (err) {
        this.uploadStatus = 'error';
        this.error = err instanceof Error ? err.message : 'Upload failed';
      }
    },

    editMetadata(patch: Partial<SkinMetadata>): void {
      if (!this.metadataDraft) return;
      this.metadataDraft = { ...this.metadataDraft, ...patch };
      const original = this.selectedSkin?.metadata;
      this.metadataDirty = !original || JSON.stringify(this.metadataDraft) !== JSON.stringify(original);
    },

    async saveMetadata(): Promise<void> {
      if (!this.selectedSkinId || !this.metadataDraft || !this.metadataDirty) return;
      try {
        const res = await skinsApi.updateMetadata(this.selectedSkinId, this.metadataDraft);
        if (res.data) {
          this.skins[res.data.skin_id] = res.data;
          this.metadataDirty = false;
        } else {
          this.error = res.error?.message ?? 'Save failed';
        }
      } catch (err) {
        this.error = err instanceof Error ? err.message : 'Save failed';
      }
    },

    async activateSkin(id: number): Promise<void> {
      this.activationPending = true;
      try {
        const res = await skinsApi.activate(id);
        if (res.data) {
          // Update status flags
          for (const s of Object.values(this.skins)) {
            s.status = s.skin_id === id ? 'active' : s.status === 'active' ? 'validated' : s.status;
          }
          this.activeSkinId = id;
        } else {
          this.error = res.error?.message ?? 'Activation failed';
        }
      } catch (err) {
        this.error = err instanceof Error ? err.message : 'Activation failed';
      } finally {
        this.activationPending = false;
      }
    },

    togglePreview(paused: boolean): void {
      this.previewPaused = paused;
    },

    applyRemoteSkinUpdate(event: WsEventEnvelope): void {
      if (event.event !== 'skin.updated' && event.event !== 'skin.activated' && event.event !== 'skin_updated') return;
      const skin = event.payload as Skin | undefined;
      if (!skin?.skin_id) return;
      this.skins[skin.skin_id] = skin;
      if (skin.status === 'active') this.activeSkinId = skin.skin_id;
    },
  },
});
