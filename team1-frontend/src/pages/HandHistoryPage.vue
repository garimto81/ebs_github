<!--
  src/pages/HandHistoryPage.vue — Hand history list (stub).
  Route: /hand-history/:tableId?
-->
<template>
  <q-page padding>
    <div class="text-h5 text-weight-bold q-mb-md">
      {{ $t('lobby.handHistory.title') }}
    </div>

    <LoadingState v-if="loading" />
    <EmptyState
      v-else-if="hands.length === 0"
      :message="$t('lobby.handHistory.empty')"
      icon="history"
    />

    <q-list v-else bordered separator>
      <q-item v-for="h in hands" :key="h.hand_id" clickable>
        <q-item-section>
          <q-item-label>Hand #{{ h.hand_number }}</q-item-label>
          <q-item-label caption>
            Pot: {{ h.pot_total.toLocaleString() }} ·
            {{ h.current_street ?? 'ended' }}
          </q-item-label>
        </q-item-section>
        <q-item-section side>
          <q-item-label caption>{{ h.started_at }}</q-item-label>
        </q-item-section>
      </q-item>
    </q-list>
  </q-page>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import LoadingState from 'components/common/LoadingState.vue';
import EmptyState from 'components/common/EmptyState.vue';
import * as handsApi from 'src/api/hands';
import type { Hand } from 'src/types/models';

const props = defineProps<{ tableId?: string }>();

const hands = ref<Hand[]>([]);
const loading = ref(true);

onMounted(async () => {
  try {
    const params = props.tableId
      ? { table_id: Number(props.tableId) }
      : undefined;
    const res = await handsApi.list(params);
    if (res.data) hands.value = res.data;
  } finally {
    loading.value = false;
  }
});
</script>
