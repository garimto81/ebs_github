<!--
  src/pages/graphic-editor/GraphicEditorDetailPage.vue — Skin metadata
  + activate/deactivate controls. The actual visual editing UX is in
  Team 4 (Flutter). This page is the Lobby-side lifecycle manager.
-->
<template>
  <q-page padding>
    <q-btn
      flat
      dense
      icon="arrow_back"
      :label="$t('common.back')"
      class="q-mb-md"
      @click="router.back()"
    />

    <LoadingState v-if="loading" />
    <q-card v-else-if="skin" flat bordered>
      <q-card-section>
        <div class="text-h6">
          {{ skin.metadata.title || skin.name }}
        </div>
        <div class="text-caption text-grey-7">
          v{{ skin.version }} · {{ skin.status }}
        </div>
      </q-card-section>
      <q-separator />
      <q-card-section>
        <div class="text-body2 q-mb-sm">
          {{ skin.metadata.description }}
        </div>
        <div
          v-if="skin.metadata.tags.length > 0"
          class="row q-gutter-xs q-mb-sm"
        >
          <q-chip
            v-for="tag in skin.metadata.tags"
            :key="tag"
            dense
            color="blue-1"
            text-color="primary"
            :label="tag"
          />
        </div>
        <div class="text-caption text-grey-6">
          TODO: preview iframe + activate/deactivate/archive controls
          (B-087). Visual editing handled by Team 4 Flutter editor.
        </div>
      </q-card-section>
      <q-card-actions
        v-if="authStore.hasPermission('GraphicEditor', 'Write')"
      >
        <q-btn
          v-if="skin.status !== 'active'"
          color="positive"
          unelevated
          no-caps
          :label="$t('graphicEditor.activate')"
          @click="handleActivate"
        />
      </q-card-actions>
    </q-card>
  </q-page>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from 'stores/authStore';
import LoadingState from 'components/common/LoadingState.vue';
import * as skinsApi from 'src/api/skins';
import type { Skin } from 'src/types/entities';

const props = defineProps<{ skinId: string }>();

const router = useRouter();
const authStore = useAuthStore();
const skin = ref<Skin | null>(null);
const loading = ref(true);

onMounted(async () => {
  try {
    const res = await skinsApi.getById(Number(props.skinId));
    if (res.data) skin.value = res.data;
  } finally {
    loading.value = false;
  }
});

async function handleActivate(): Promise<void> {
  const res = await skinsApi.activate(Number(props.skinId));
  if (res.data) skin.value = res.data;
}
</script>
