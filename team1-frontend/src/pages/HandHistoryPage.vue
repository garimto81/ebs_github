<!--
  src/pages/HandHistoryPage.vue — Hand history with table selector,
  DataTable, and expandable action detail per hand.
  Route: /hand-history/:tableId?
-->
<template>
  <q-page padding>
    <div class="row items-center q-mb-md">
      <div class="text-h5 text-weight-bold">
        {{ $t('lobby.handHistory.title') }}
      </div>
      <q-space />
      <!-- Table selector -->
      <q-select
        v-model="selectedTableId"
        :options="tableOptions"
        :label="$t('lobby.handHistory.selectTable')"
        emit-value
        map-options
        outlined
        dense
        clearable
        style="min-width: 200px"
        @update:model-value="fetchHands"
      />
    </div>

    <LoadingState v-if="loading" />
    <EmptyState
      v-else-if="hands.length === 0"
      :message="$t('lobby.handHistory.empty')"
      icon="history"
    />

    <q-table
      v-else
      :rows="hands"
      :columns="columns"
      row-key="hand_id"
      flat
      bordered
      :pagination="{ rowsPerPage: 20 }"
      :rows-per-page-options="[10, 20, 50]"
    >
      <!-- Expandable row -->
      <template #body="bodyProps">
        <q-tr :props="bodyProps" class="cursor-pointer" @click="bodyProps.expand = !bodyProps.expand">
          <q-td v-for="col in bodyProps.cols" :key="col.name" :props="bodyProps">
            {{ col.value }}
          </q-td>
        </q-tr>
        <q-tr v-show="bodyProps.expand" :props="bodyProps">
          <q-td colspan="100%">
            <HandDetail :hand-id="bodyProps.row.hand_id" />
          </q-td>
        </q-tr>
      </template>
    </q-table>
  </q-page>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, defineAsyncComponent } from 'vue';
import { useI18n } from 'vue-i18n';
import LoadingState from 'components/common/LoadingState.vue';
import EmptyState from 'components/common/EmptyState.vue';
import * as handsApi from 'src/api/hands';
import * as tablesApi from 'src/api/tables';
import type { Hand } from 'src/types/models';
import type { QTableColumn } from 'quasar';

const HandDetail = defineAsyncComponent(
  () => import('components/hand-history/HandDetail.vue'),
);

const { t } = useI18n();
const props = defineProps<{ tableId?: string }>();

const hands = ref<Hand[]>([]);
const loading = ref(true);
const selectedTableId = ref<number | null>(props.tableId ? Number(props.tableId) : null);
const tableOptions = ref<{ label: string; value: number }[]>([]);

const columns = computed<QTableColumn[]>(() => [
  { name: 'hand_number', label: t('lobby.handHistory.handNo'), field: 'hand_number', align: 'left', sortable: true },
  { name: 'started_at', label: t('lobby.handHistory.time'), field: 'started_at', align: 'left', sortable: true },
  { name: 'board_cards', label: t('lobby.handHistory.board'), field: 'board_cards', align: 'left' },
  { name: 'pot_total', label: t('lobby.handHistory.pot'), field: 'pot_total', align: 'right', sortable: true, format: (v: number) => v.toLocaleString() },
  { name: 'current_street', label: t('lobby.handHistory.street'), field: 'current_street', align: 'left', format: (v: string | null) => v ?? 'ended' },
]);

async function fetchHands(): Promise<void> {
  loading.value = true;
  try {
    const params = selectedTableId.value
      ? { table_id: selectedTableId.value }
      : undefined;
    const res = await handsApi.list(params);
    if (res.data) hands.value = res.data;
  } finally {
    loading.value = false;
  }
}

async function fetchTables(): Promise<void> {
  try {
    const res = await tablesApi.list();
    if (res.data) {
      tableOptions.value = res.data.map((tbl) => ({
        label: tbl.name ?? `Table ${tbl.table_no ?? tbl.table_id}`,
        value: tbl.table_id,
      }));
    }
  } catch {
    // non-critical — table selector just stays empty
  }
}

onMounted(async () => {
  await Promise.all([fetchHands(), fetchTables()]);
});
</script>
