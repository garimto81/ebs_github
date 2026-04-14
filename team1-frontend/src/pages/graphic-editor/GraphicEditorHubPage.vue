<!--
  src/pages/graphic-editor/GraphicEditorHubPage.vue — Skin gallery hub.
  Reference: UI-04 Graphic Editor, CCR-011. The *editor* itself is
  Team 4 Flutter, but Team 1 owns the skin browse/upload/activate UI
  for Lobby-side management.
-->
<template>
  <q-page padding>
    <div class="row items-center q-mb-md">
      <div>
        <div class="text-h5 text-weight-bold">
          {{ $t('graphicEditor.title') }}
        </div>
        <div class="text-caption text-grey-7">
          {{ $t('graphicEditor.hubSubtitle') }}
        </div>
      </div>
      <q-space />
      <q-btn
        v-if="authStore.hasPermission('GraphicEditor', 'Write')"
        color="primary"
        unelevated
        no-caps
        icon="upload"
        :label="$t('graphicEditor.upload')"
        @click="handleUpload"
      />
    </div>

    <LoadingState v-if="loading" />
    <EmptyState
      v-else-if="skins.length === 0"
      :message="$t('graphicEditor.empty')"
      icon="palette"
    />

    <div v-else class="row q-col-gutter-md">
      <div
        v-for="s in skins"
        :key="s.skin_id"
        class="col-xs-12 col-sm-6 col-md-4 col-lg-3"
      >
        <q-card flat bordered class="cursor-pointer" @click="handleOpen(s)">
          <q-img
            v-if="s.preview_url"
            :src="s.preview_url"
            :ratio="16 / 9"
          />
          <q-card-section>
            <div class="text-subtitle1 ellipsis">
              {{ s.metadata.title || s.name }}
            </div>
            <div class="text-caption text-grey-7">
              v{{ s.version }}
            </div>
          </q-card-section>
          <q-card-actions>
            <q-badge
              :color="statusColor(s.status)"
              :label="s.status"
            />
          </q-card-actions>
        </q-card>
      </div>
    </div>
  </q-page>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from 'stores/authStore';
import LoadingState from 'components/common/LoadingState.vue';
import EmptyState from 'components/common/EmptyState.vue';
import * as skinsApi from 'src/api/skins';
import type { Skin, SkinStatus } from 'src/types/entities';

const router = useRouter();
const authStore = useAuthStore();
const skins = ref<Skin[]>([]);
const loading = ref(true);

onMounted(async () => {
  try {
    const res = await skinsApi.list();
    if (res.data) skins.value = res.data;
  } finally {
    loading.value = false;
  }
});

function statusColor(s: SkinStatus): string {
  switch (s) {
    case 'active':
      return 'positive';
    case 'validated':
      return 'info';
    case 'archived':
      return 'grey';
    default:
      return 'warning';
  }
}

function handleOpen(s: Skin): void {
  void router.push(`/lobby/graphic-editor/${s.skin_id}`);
}

function handleUpload(): void {
  // TODO: file picker + skinsApi.upload with progress
  console.warn('Upload flow — B-086 pending');
}
</script>
