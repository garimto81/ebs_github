<!--
  src/pages/PlayerDetailPage.vue — Player profile stub.
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
    <q-card v-else-if="player" flat bordered>
      <q-card-section>
        <div class="text-h6">
          {{ player.first_name }} {{ player.last_name }}
        </div>
        <div class="text-caption text-grey-7">
          WSOP ID: {{ player.wsop_id }}
        </div>
      </q-card-section>
      <q-separator />
      <q-card-section>
        <div class="text-caption text-grey-6">
          TODO: stack history, hand count, bust info (B-078)
        </div>
      </q-card-section>
    </q-card>
  </q-page>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import LoadingState from 'components/common/LoadingState.vue';
import * as playersApi from 'src/api/players';
import type { Player } from 'src/types/entities';

const props = defineProps<{ tableId: string; playerId: string }>();

const router = useRouter();
const player = ref<Player | null>(null);
const loading = ref(true);

onMounted(async () => {
  try {
    const res = await playersApi.getById(Number(props.playerId));
    if (res.data) player.value = res.data;
  } finally {
    loading.value = false;
  }
});
</script>
