<!--
  src/pages/TableDetailPage.vue — Table seat map + player list + launch CC.
  Route: /tables/:tableId (UI-01 §화면 4)
-->
<template>
  <q-page padding>
    <!-- Header: Table summary -->
    <div class="row items-center q-mb-md">
      <div>
        <div class="row items-center q-gutter-sm">
          <div class="text-h5 text-weight-bold">{{ table?.name || `Table #${tableId}` }}</div>
          <q-badge
            v-if="table"
            :color="statusColor(table.status)"
            :label="table.status"
          />
          <q-icon
            v-if="table?.type === 'feature'"
            name="star"
            color="amber"
            size="sm"
          />
        </div>
        <div v-if="table" class="text-caption text-grey-7 q-mt-xs">
          Blinds {{ table.small_blind ?? 0 }}/{{ table.big_blind ?? 0 }}
          <template v-if="table.ante_amount"> &middot; Ante {{ table.ante_amount }}</template>
          <template v-if="table.max_players"> &middot; {{ table.max_players }} max</template>
        </div>
      </div>
      <q-space />
      <q-btn
        v-if="authStore.hasPermission('Lobby', 'Write')"
        color="primary"
        unelevated no-caps
        icon="person_add"
        :label="$t('lobby.tables.addPlayer')"
        class="q-mr-sm"
        @click="addPlayerOpen = true"
      />
      <q-btn
        v-if="authStore.hasPermission('CC', 'Write')"
        color="positive"
        unelevated no-caps
        icon="open_in_new"
        :label="$t('lobby.tables.enterCc')"
        :loading="launching"
        @click="handleLaunchCc"
      />
    </div>

    <LoadingState v-if="loading" />
    <ErrorBanner :message="error" :on-retry="loadSeats" />

    <template v-if="!loading && !error">
      <!-- Seat Map -->
      <q-card flat bordered class="q-mb-md">
        <q-card-section>
          <div class="text-subtitle2 q-mb-sm">{{ $t('lobby.tables.seatMap') }}</div>
          <div class="seat-map-grid">
            <div
              v-for="seatNo in maxSeats"
              :key="seatNo"
              class="seat-map-cell"
              :class="seatMapClass(seatNo)"
              :title="seatMapTitle(seatNo)"
            >
              <div class="text-caption text-weight-bold">{{ seatNo }}</div>
              <div class="seat-player-name">{{ seatPlayerName(seatNo) }}</div>
            </div>
          </div>
        </q-card-section>
      </q-card>

      <!-- Player DataTable -->
      <q-table
        :rows="seats"
        :columns="seatColumns"
        row-key="seat_no"
        flat bordered dense
        :pagination="{ rowsPerPage: 0 }"
        hide-pagination
      >
        <template #body-cell-status="props">
          <q-td :props="props">
            <q-badge
              :color="props.row.status === 'occupied' ? 'green' : 'grey'"
              :label="props.row.status"
            />
          </q-td>
        </template>
      </q-table>
    </template>

    <!-- Add Player Dialog -->
    <AddPlayerDialog
      v-model="addPlayerOpen"
      :table-id="tid"
      :empty-seats="emptySeats"
      @saved="loadSeats"
    />
  </q-page>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useAuthStore } from 'stores/authStore';
import LoadingState from 'components/common/LoadingState.vue';
import ErrorBanner from 'components/common/ErrorBanner.vue';
import AddPlayerDialog from 'components/table/AddPlayerDialog.vue';
import * as tablesApi from 'src/api/tables';
import * as seatsApi from 'src/api/seats';
import type { Table, TableSeat } from 'src/types/entities';

const props = defineProps<{ tableId: string }>();

const authStore = useAuthStore();
const launching = ref(false);
const loading = ref(false);
const error = ref<string | null>(null);
const table = ref<Table | null>(null);
const seats = ref<TableSeat[]>([]);
const addPlayerOpen = ref(false);

const tid = computed(() => Number(props.tableId));
const maxSeats = computed(() => table.value?.max_players ?? 10);

const emptySeats = computed(() => {
  const occupied = new Set(seats.value.map(s => s.seat_no));
  const empty: number[] = [];
  for (let i = 1; i <= maxSeats.value; i++) {
    if (!occupied.has(i)) empty.push(i);
  }
  return empty;
});

const seatColumns = [
  { name: 'seat_no', label: 'Seat', field: 'seat_no', align: 'center' as const, sortable: true },
  { name: 'player_name', label: 'Player Name', field: 'player_name', align: 'left' as const },
  { name: 'chip_count', label: 'Stack', field: 'chip_count', align: 'right' as const, format: (v: number) => v?.toLocaleString() ?? '-' },
  { name: 'status', label: 'Status', field: 'status', align: 'center' as const },
];

onMounted(() => {
  void loadTable();
  void loadSeats();
});

async function loadTable(): Promise<void> {
  const res = await tablesApi.getById(tid.value);
  if (res.data) table.value = res.data;
}

async function loadSeats(): Promise<void> {
  loading.value = true;
  error.value = null;
  try {
    const res = await seatsApi.getByTable(tid.value);
    if (res.data) {
      seats.value = res.data;
    } else {
      error.value = res.error?.message ?? 'Failed to load seats';
    }
  } catch (err) {
    error.value = err instanceof Error ? err.message : 'Failed';
  } finally {
    loading.value = false;
  }
}

function seatMapClass(seatNo: number): string {
  const seat = seats.value.find(s => s.seat_no === seatNo);
  if (!seat) return 'seat-map-empty';
  return seat.status === 'occupied' ? 'seat-map-occupied' : 'seat-map-empty';
}

function seatMapTitle(seatNo: number): string {
  const seat = seats.value.find(s => s.seat_no === seatNo);
  if (!seat) return `Seat ${seatNo}: empty`;
  return `Seat ${seatNo}: ${seat.player_name ?? 'empty'}`;
}

function seatPlayerName(seatNo: number): string {
  const seat = seats.value.find(s => s.seat_no === seatNo);
  if (!seat || !seat.player_name) return 'empty';
  // Abbreviate: first name + last initial
  const parts = seat.player_name.split(' ');
  if (parts.length >= 2) return `${parts[0]} ${parts[1]![0]}.`;
  return seat.player_name;
}

function statusColor(status: string): string {
  switch (status) {
    case 'live': return 'green';
    case 'setup': return 'orange';
    case 'empty': return 'grey';
    default: return 'grey';
  }
}

async function handleLaunchCc(): Promise<void> {
  launching.value = true;
  try {
    const res = await tablesApi.launchCc(tid.value);
    if (res.data?.url) {
      window.open(res.data.url, '_blank');
    }
  } finally {
    launching.value = false;
  }
}
</script>

<style scoped>
.seat-map-grid {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 8px;
  max-width: 500px;
}
.seat-map-cell {
  border-radius: 8px;
  padding: 8px;
  text-align: center;
  min-height: 56px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}
.seat-map-occupied {
  background: var(--q-green-2, #c8e6c9);
  border: 2px solid var(--q-green-5, #4caf50);
}
.seat-map-empty {
  background: var(--q-grey-2, #eeeeee);
  border: 2px solid var(--q-grey-4, #bdbdbd);
}
.seat-player-name {
  font-size: 11px;
  max-width: 80px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>
