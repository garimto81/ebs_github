<!--
  src/pages/TableListPage.vue — Table list + Rebalance Saga trigger.
  Route: /flights/:flightId/tables
  Design: UI-01 §화면 3 + §4.1 Rebalance Saga UI (CCR-020).
-->
<template>
  <q-page padding>
    <div class="row items-center q-mb-md">
      <div>
        <div class="text-h5 text-weight-bold">
          {{ $t('lobby.tables.title') }}
        </div>
        <div class="text-caption text-grey-7">
          Flight #{{ flightId }}
        </div>
      </div>
      <q-space />
      <q-btn
        v-if="authStore.hasPermission('Lobby', 'Write')"
        color="secondary"
        unelevated
        no-caps
        icon="shuffle"
        :label="$t('lobby.tables.rebalance')"
        :loading="rebalancing"
        class="q-mr-sm"
        @click="handleRebalance"
      />
      <q-btn
        v-if="authStore.hasPermission('Lobby', 'Write')"
        color="primary"
        unelevated
        no-caps
        icon="add"
        :label="$t('lobby.tables.newTable')"
      />
    </div>

    <LoadingState v-if="lobbyStore.tablesState.status === 'loading'" />
    <ErrorBanner
      :message="lobbyStore.tablesState.error"
      :on-retry="reload"
    />
    <EmptyState
      v-if="tables.length === 0 && lobbyStore.tablesState.status === 'success'"
      :message="$t('lobby.tables.empty')"
      icon="table_restaurant"
    />

    <div class="row q-col-gutter-md">
      <div
        v-for="t in tables"
        :key="t.table_id"
        class="col-xs-12 col-sm-6 col-md-4 col-lg-3"
      >
        <q-card flat bordered class="cursor-pointer" @click="handleOpen(t)">
          <q-card-section>
            <div class="row items-center">
              <div class="text-subtitle1 text-weight-bold">
                Table {{ t.table_no }}
              </div>
              <q-space />
              <q-badge
                :color="statusColor(t.status)"
                :label="t.status"
              />
            </div>
            <div class="text-caption text-grey-7 q-mt-xs">
              {{ t.name }}
            </div>
            <div class="text-caption text-grey-8 q-mt-sm">
              Seats: {{ t.max_players }} · Blinds:
              {{ t.small_blind }}/{{ t.big_blind }}
            </div>
          </q-card-section>
        </q-card>
      </div>
    </div>

    <!-- Rebalance Saga Progress Dialog (UI-01 §4.1, CCR-020) -->
    <q-dialog v-model="rebalanceDialog" persistent>
      <q-card style="min-width: 360px">
        <q-card-section>
          <div class="text-h6">{{ $t('lobby.tables.rebalance') }}</div>
        </q-card-section>
        <q-card-section>
          <q-linear-progress
            :value="rebalanceProgress / 6"
            color="primary"
            class="q-mb-sm"
          />
          <div class="text-caption text-grey-7">
            Step {{ rebalanceProgress }} of 6: {{ rebalanceStep }}
          </div>
          <div class="text-caption text-grey-6 q-mt-sm">
            TODO: subscribe to ws `rebalance_progress` events via wsStore.
          </div>
        </q-card-section>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from 'stores/authStore';
import { useLobbyStore } from 'stores/lobbyStore';
import { useNavStore } from 'stores/navStore';
import LoadingState from 'components/common/LoadingState.vue';
import ErrorBanner from 'components/common/ErrorBanner.vue';
import EmptyState from 'components/common/EmptyState.vue';
import * as tablesApi from 'src/api/tables';
import type { Table } from 'src/types/entities';

const props = defineProps<{ flightId: string }>();

const router = useRouter();
const authStore = useAuthStore();
const lobbyStore = useLobbyStore();
const navStore = useNavStore();

const fid = computed(() => Number(props.flightId));
const rebalancing = ref(false);
const rebalanceDialog = ref(false);
const rebalanceProgress = ref(0);
const rebalanceStep = ref('');

const tables = computed(() =>
  lobbyStore.tablesList.filter((t) => t.event_flight_id === fid.value),
);

onMounted(() => {
  void reload();
});

async function reload(): Promise<void> {
  await lobbyStore.fetchTables(fid.value);
}

function statusColor(status: string): string {
  switch (status) {
    case 'live':
      return 'positive';
    case 'paused':
      return 'warning';
    case 'closed':
      return 'grey';
    default:
      return 'blue-grey';
  }
}

function handleOpen(t: Table): void {
  navStore.setTableId(t.table_id, `Table ${t.table_no}`);
  void router.push(`/tables/${t.table_id}`);
}

async function handleRebalance(): Promise<void> {
  rebalancing.value = true;
  rebalanceDialog.value = true;
  rebalanceProgress.value = 0;
  rebalanceStep.value = 'Starting…';
  try {
    const res = await tablesApi.rebalance(fid.value);
    if (res.data) {
      rebalanceProgress.value = 6;
      rebalanceStep.value = `Moved ${res.data.moved} players`;
    }
    await reload();
  } finally {
    rebalancing.value = false;
    setTimeout(() => {
      rebalanceDialog.value = false;
    }, 1500);
  }
}
</script>
