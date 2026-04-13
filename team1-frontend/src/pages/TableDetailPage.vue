<!--
  src/pages/TableDetailPage.vue — Table seat map + launch CC.
  Stub shell (B-077): full seat grid + drag-to-reseat pending port.
-->
<template>
  <q-page padding>
    <div class="row items-center q-mb-md">
      <div class="text-h5 text-weight-bold">
        Table #{{ tableId }}
      </div>
      <q-space />
      <q-btn
        v-if="authStore.hasPermission('CC', 'Write')"
        color="primary"
        unelevated
        no-caps
        icon="open_in_new"
        label="Launch CC"
        :loading="launching"
        @click="handleLaunchCc"
      />
    </div>

    <q-card flat bordered>
      <q-card-section>
        <div class="text-subtitle2 q-mb-sm">Seats</div>
        <div class="text-caption text-grey-6">
          TODO: seat grid (UI-01 §화면 4) — port from
          ebs_lobby-react/pages/TableDetailPage.tsx (B-077)
        </div>
      </q-card-section>
    </q-card>
  </q-page>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useAuthStore } from 'stores/authStore';
import * as tablesApi from 'src/api/tables';

const props = defineProps<{ tableId: string }>();

const authStore = useAuthStore();
const launching = ref(false);

async function handleLaunchCc(): Promise<void> {
  launching.value = true;
  try {
    const res = await tablesApi.launchCc(Number(props.tableId));
    if (res.data?.url) {
      window.open(res.data.url, '_blank');
    }
  } finally {
    launching.value = false;
  }
}
</script>
