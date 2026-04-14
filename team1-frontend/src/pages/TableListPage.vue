<!--
  src/pages/TableListPage.vue — UI-01 §화면 3 Table Management.
  WSOP LIVE row-based seat grid + Day tabs (2026-04-13).
  Route: /events/:eventId/tables?day=N
-->
<template>
  <q-page padding>
    <!-- Players summary bar -->
    <div class="row q-gutter-md q-mb-md">
      <div class="col-auto">
        <div class="text-caption text-grey">Players</div>
        <div class="text-h6">{{ summaryStats.remaining }} / {{ summaryStats.total }}</div>
      </div>
      <div class="col-auto">
        <div class="text-caption text-grey">Waiting</div>
        <div class="text-h6">{{ summaryStats.waiting }}</div>
      </div>
      <div class="col-auto">
        <div class="text-caption text-grey">Total Tables</div>
        <div class="text-h6">{{ summaryStats.tableCount }}</div>
      </div>
      <div class="col-auto">
        <div class="text-caption text-grey">Seats</div>
        <div class="text-h6">{{ summaryStats.seatTotal }} (empty: {{ summaryStats.emptySeats }})</div>
      </div>
    </div>

    <!-- Day tabs (Flight integration) -->
    <DayTabs
      v-model="selectedDay"
      :flights="flights"
    />

    <!-- Toolbar -->
    <div class="row items-center q-mb-md q-gutter-sm">
      <q-btn-dropdown
        v-if="authStore.hasPermission('Lobby', 'Write')"
        flat no-caps
        :label="$t('lobby.tables.tableAction')"
        icon="more_vert"
      >
        <q-list>
          <q-item clickable v-close-popup>
            <q-item-section>{{ $t('common.edit') }}</q-item-section>
          </q-item>
          <q-item clickable v-close-popup>
            <q-item-section class="text-negative">{{ $t('common.delete') }}</q-item-section>
          </q-item>
        </q-list>
      </q-btn-dropdown>

      <q-input
        v-model="searchPlayer"
        dense outlined
        :placeholder="$t('lobby.tables.searchPlayer')"
        style="width: 200px"
      >
        <template #prepend><q-icon name="search" /></template>
      </q-input>

      <q-space />

      <q-btn
        v-if="authStore.hasPermission('Lobby', 'Write')"
        color="orange-8"
        unelevated no-caps
        icon="shuffle"
        :label="$t('lobby.tables.rebalance')"
        :loading="rebalancing"
        @click="handleRebalance"
      />
      <q-btn
        v-if="authStore.hasPermission('Lobby', 'Write')"
        color="primary"
        unelevated no-caps
        icon="add"
        :label="$t('lobby.tables.newTable')"
        @click="openTableForm(null)"
      />
    </div>

    <!-- Loading / Error / Empty -->
    <LoadingState v-if="lobbyStore.tablesState.status === 'loading'" />
    <ErrorBanner :message="lobbyStore.tablesState.error" :on-retry="reload" />
    <EmptyState
      v-if="tables.length === 0 && lobbyStore.tablesState.status === 'success'"
      :message="$t('lobby.tables.empty')"
      icon="table_restaurant"
    />

    <!-- Row-based seat grid table (WSOP LIVE style) -->
    <q-table
      v-if="tables.length > 0"
      :rows="tables"
      :columns="seatColumns"
      row-key="table_id"
      flat bordered dense
      :pagination="{ rowsPerPage: 0 }"
      hide-pagination
    >
      <!-- Table name column -->
      <template #body-cell-table_name="props">
        <q-td :props="props">
          <div class="row items-center no-wrap">
            <q-icon
              v-if="props.row.is_feature"
              name="star"
              color="amber"
              size="sm"
              class="q-mr-xs"
            />
            <span class="text-weight-bold">{{ props.row.name || `Table ${props.row.table_no}` }}</span>
          </div>
        </q-td>
      </template>

      <!-- Seat columns rendered as colored grid -->
      <template #body-cell-seats="props">
        <q-td :props="props">
          <SeatGrid
            :seats="getSeats(props.row)"
            :max-seats="props.row.max_players"
          />
        </q-td>
      </template>

      <!-- Actions -->
      <template #body-cell-actions="props">
        <q-td :props="props">
          <q-btn-dropdown flat dense icon="more_vert" size="sm">
            <q-list dense>
              <q-item clickable v-close-popup @click="enterCC(props.row)">
                <q-item-section>Enter CC</q-item-section>
              </q-item>
              <q-item clickable v-close-popup>
                <q-item-section>{{ props.row.is_feature ? 'Remove Feature' : 'Set as Feature' }}</q-item-section>
              </q-item>
            </q-list>
          </q-btn-dropdown>
        </q-td>
      </template>
    </q-table>

    <!-- Seat legend -->
    <div v-if="tables.length > 0" class="row q-gutter-sm q-mt-sm text-caption text-grey-7">
      <div class="row items-center"><div class="seat-legend seat-occupied" /> Seated</div>
      <div class="row items-center"><div class="seat-legend seat-empty" /> Empty</div>
      <div class="row items-center"><div class="seat-legend seat-busted" /> Busted</div>
    </div>

    <!-- Table Form Dialog (Create / Edit) -->
    <TableFormDialog
      v-model="tableFormOpen"
      :flight-id="currentFlightId"
      :table="editingTable"
      @saved="handleTableSaved"
    />

    <!-- Rebalance progress banner (auto-hide after 3s on success) -->
    <transition name="fade">
      <q-banner
        v-if="rebalanceBannerVisible"
        :class="rebalanceBannerClass"
        class="q-mb-md"
      >
        <template #avatar>
          <q-icon :name="rebalanceBannerIcon" />
        </template>
        <span>{{ rebalanceBannerText }}</span>
        <template v-if="rebalanceOutcome === 'compensated'" #action>
          <q-btn
            flat no-caps color="white"
            label="Retry"
            @click="handleRebalanceRetry"
          />
        </template>
      </q-banner>
    </transition>

    <!-- Rebalance Saga Detail Dialog (UI-01 §3.1, CCR-020) -->
    <q-dialog v-model="rebalanceDialog" persistent>
      <q-card style="min-width: 440px; max-width: 560px">
        <q-card-section>
          <div class="row items-center">
            <div class="text-h6">{{ $t('lobby.tables.rebalance') }}</div>
            <q-space />
            <q-badge
              :color="rebalanceOutcomeColor"
              :label="rebalanceOutcomeLabel"
            />
          </div>
        </q-card-section>

        <!-- Progress bar -->
        <q-card-section class="q-pt-none">
          <q-linear-progress
            :value="rebalanceTotalSteps > 0 ? rebalanceCompletedSteps / rebalanceTotalSteps : 0"
            :color="rebalanceOutcome === 'compensation_failed' ? 'negative' : 'primary'"
            size="8px"
            class="q-mb-sm"
          />
          <div class="text-caption text-grey-7">
            {{ rebalanceCompletedSteps }} / {{ rebalanceTotalSteps }} steps
          </div>
        </q-card-section>

        <!-- Step list -->
        <q-card-section class="q-pt-none" style="max-height: 320px; overflow-y: auto">
          <q-list dense separator>
            <q-expansion-item
              v-for="step in rebalanceSteps"
              :key="step.name"
              :icon="stepIcon(step.status)"
              :label="step.name"
              :caption="step.duration_ms != null ? `${step.duration_ms}ms` : ''"
              :header-class="step.status === 'failed' ? 'text-negative' : ''"
              :disable="step.status !== 'failed'"
              dense
            >
              <q-card v-if="step.error" flat class="bg-grey-2 q-pa-sm">
                <div class="text-caption text-negative">
                  <strong>{{ step.error.code }}</strong>: {{ step.error.message }}
                </div>
              </q-card>
            </q-expansion-item>
          </q-list>
        </q-card-section>

        <q-card-actions align="right">
          <q-btn
            v-if="rebalanceOutcome === 'compensated'"
            color="warning"
            unelevated no-caps
            label="Retry"
            @click="handleRebalanceRetry"
          />
          <q-btn
            flat no-caps
            :label="rebalanceOutcome ? 'Close' : 'Cancel'"
            @click="rebalanceDialog = false"
          />
        </q-card-actions>
      </q-card>
    </q-dialog>

    <!-- Compensation failed modal (500) -->
    <q-dialog v-model="compensationFailedModal" persistent>
      <q-card class="bg-negative text-white" style="min-width: 380px">
        <q-card-section>
          <div class="text-h6">Manual Intervention Required</div>
        </q-card-section>
        <q-card-section>
          <p>
            Rebalance compensation has failed. The table state may be inconsistent.
            Please verify table assignments manually.
          </p>
          <div v-if="compensationFailedError" class="text-caption q-mt-sm">
            Error: {{ compensationFailedError }}
          </div>
        </q-card-section>
        <q-card-actions align="right">
          <q-btn
            flat no-caps color="white"
            label="Acknowledge"
            @click="compensationFailedModal = false"
          />
        </q-card-actions>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { useRoute } from 'vue-router';
import { useAuthStore } from 'stores/authStore';
import { useLobbyStore } from 'stores/lobbyStore';
import { useWsStore } from 'stores/wsStore';
import LoadingState from 'components/common/LoadingState.vue';
import ErrorBanner from 'components/common/ErrorBanner.vue';
import EmptyState from 'components/common/EmptyState.vue';
import SeatGrid from 'components/table/SeatGrid.vue';
import DayTabs from 'components/table/DayTabs.vue';
import TableFormDialog from 'components/table/TableFormDialog.vue';
import * as tablesApi from 'src/api/tables';
import type { Table } from 'src/types/entities';
import type { WsEventEnvelope } from 'src/types/api';

// ---- Rebalance step types ----
interface RebalanceStepError {
  code: string;
  message: string;
}
type RebalanceStepStatus = 'pending' | 'in_progress' | 'ok' | 'failed' | 'compensated';
interface RebalanceStep {
  name: string;
  status: RebalanceStepStatus;
  duration_ms: number | null;
  error: RebalanceStepError | null;
}
type RebalanceOutcome = null | 'completed' | 'compensated' | 'compensation_failed';

const props = defineProps<{ eventId: string }>();
const route = useRoute();
const authStore = useAuthStore();
const lobbyStore = useLobbyStore();
const wsStore = useWsStore();

// State
const selectedDay = ref(0);
const searchPlayer = ref('');
const tableFormOpen = ref(false);
const editingTable = ref<Table | null>(null);

// Rebalance Saga state
const rebalancing = ref(false);
const rebalanceDialog = ref(false);
const rebalanceSteps = ref<RebalanceStep[]>([]);
const rebalanceOutcome = ref<RebalanceOutcome>(null);
const rebalanceBannerVisible = ref(false);
const compensationFailedModal = ref(false);
const compensationFailedError = ref('');
let bannerTimer: ReturnType<typeof setTimeout> | null = null;

const eid = computed(() => Number(props.eventId));

const rebalanceTotalSteps = computed(() => rebalanceSteps.value.length);
const rebalanceCompletedSteps = computed(() =>
  rebalanceSteps.value.filter(s => s.status === 'ok' || s.status === 'compensated').length,
);

const rebalanceOutcomeColor = computed(() => {
  switch (rebalanceOutcome.value) {
    case 'completed': return 'positive';
    case 'compensated': return 'warning';
    case 'compensation_failed': return 'negative';
    default: return 'info';
  }
});

const rebalanceOutcomeLabel = computed(() => {
  switch (rebalanceOutcome.value) {
    case 'completed': return 'Completed';
    case 'compensated': return 'Partial Failure';
    case 'compensation_failed': return 'Failed';
    default: return 'In Progress';
  }
});

const rebalanceBannerClass = computed(() => {
  switch (rebalanceOutcome.value) {
    case 'completed': return 'bg-positive text-white';
    case 'compensated': return 'bg-warning text-white';
    case 'compensation_failed': return 'bg-negative text-white';
    default: return 'bg-info text-white';
  }
});

const rebalanceBannerIcon = computed(() => {
  switch (rebalanceOutcome.value) {
    case 'completed': return 'check_circle';
    case 'compensated': return 'warning';
    case 'compensation_failed': return 'error';
    default: return 'sync';
  }
});

const rebalanceBannerText = computed(() => {
  switch (rebalanceOutcome.value) {
    case 'completed': return 'Rebalance completed successfully.';
    case 'compensated': return 'Rebalance partially failed. Some moves were rolled back.';
    case 'compensation_failed': return 'Rebalance failed critically. Manual intervention required.';
    default: return 'Rebalance in progress...';
  }
});

function stepIcon(status: RebalanceStepStatus): string {
  switch (status) {
    case 'ok': return 'check_circle';
    case 'in_progress': return 'hourglass_empty';
    case 'failed': return 'cancel';
    case 'compensated': return 'undo';
    case 'pending': return 'radio_button_unchecked';
    default: return 'radio_button_unchecked';
  }
}

// ---- WS listener for rebalance events ----
function handleWsEvent(event: WsEventEnvelope): void {
  const payload = event.payload as Record<string, unknown>;

  switch (event.event) {
    case 'rebalance_started': {
      rebalancing.value = true;
      rebalanceDialog.value = true;
      rebalanceOutcome.value = null;
      rebalanceBannerVisible.value = true;
      if (bannerTimer) clearTimeout(bannerTimer);
      // Initialize steps from payload if provided
      const steps = (payload.steps as Array<{ name: string }>) ?? [];
      rebalanceSteps.value = steps.map(s => ({
        name: s.name,
        status: 'pending' as const,
        duration_ms: null,
        error: null,
      }));
      break;
    }
    case 'rebalance_progress': {
      const stepName = payload.step_name as string;
      const stepStatus = payload.status as RebalanceStepStatus;
      const durationMs = (payload.duration_ms as number) ?? null;
      const error = (payload.error as RebalanceStepError) ?? null;

      const existing = rebalanceSteps.value.find(s => s.name === stepName);
      if (existing) {
        existing.status = stepStatus;
        existing.duration_ms = durationMs;
        existing.error = error;
      } else {
        rebalanceSteps.value.push({
          name: stepName,
          status: stepStatus,
          duration_ms: durationMs,
          error,
        });
      }
      break;
    }
    case 'rebalance_completed': {
      rebalanceOutcome.value = 'completed';
      rebalancing.value = false;
      // Mark remaining pending steps as ok
      for (const s of rebalanceSteps.value) {
        if (s.status === 'pending' || s.status === 'in_progress') s.status = 'ok';
      }
      // Auto-hide banner after 3s
      bannerTimer = setTimeout(() => {
        rebalanceBannerVisible.value = false;
      }, 3000);
      // Auto-close dialog after 3s
      setTimeout(() => {
        rebalanceDialog.value = false;
      }, 3000);
      // Refresh tables
      void reload();
      break;
    }
    case 'rebalance_compensated': {
      rebalanceOutcome.value = 'compensated';
      rebalancing.value = false;
      rebalanceBannerVisible.value = true;
      if (bannerTimer) clearTimeout(bannerTimer);
      break;
    }
    case 'rebalance_compensation_failed': {
      rebalanceOutcome.value = 'compensation_failed';
      rebalancing.value = false;
      rebalanceBannerVisible.value = true;
      compensationFailedError.value = (payload.error as string) ?? '';
      compensationFailedModal.value = true;
      if (bannerTimer) clearTimeout(bannerTimer);
      break;
    }
  }
}

let unsubscribeWs: (() => void) | null = null;

// Initialize from query param
onMounted(() => {
  const dayParam = route.query.day;
  if (dayParam) selectedDay.value = Number(dayParam);
  void reload();

  // Subscribe to WS rebalance events
  unsubscribeWs = wsStore.onMessage(handleWsEvent);
});

onUnmounted(() => {
  if (unsubscribeWs) unsubscribeWs();
  if (bannerTimer) clearTimeout(bannerTimer);
});

watch(() => props.eventId, () => void reload());

async function reload(): Promise<void> {
  await lobbyStore.fetchFlights(eid.value);
  const currentFlight = flights.value.find(f => f.day_index === selectedDay.value);
  if (currentFlight) {
    await lobbyStore.fetchTables(currentFlight.flight_id);
  }
}

watch(selectedDay, async () => {
  const currentFlight = flights.value.find(f => f.day_index === selectedDay.value);
  if (currentFlight) {
    await lobbyStore.fetchTables(currentFlight.flight_id);
  }
});

// Flights for Day tabs
const flights = computed(() =>
  lobbyStore.flightsList.filter(f => f.event_id === eid.value),
);

// Tables for current day
const tables = computed(() => {
  const currentFlight = flights.value.find(f => f.day_index === selectedDay.value);
  if (!currentFlight) return [];
  return lobbyStore.tablesList.filter(t => t.event_flight_id === currentFlight.flight_id);
});

// Summary stats
const summaryStats = computed(() => {
  const tbls = tables.value;
  const totalSeats = tbls.reduce((sum, t) => sum + (t.max_players || 0), 0);
  const occupiedSeats = tbls.reduce((sum, t) => sum + (t.seated_count || 0), 0);
  return {
    remaining: occupiedSeats,
    total: totalSeats,
    waiting: 0,
    tableCount: tbls.length,
    seatTotal: totalSeats,
    emptySeats: totalSeats - occupiedSeats,
  };
});

// Column definitions for seat grid table
const seatColumns = [
  { name: 'table_name', label: 'Table # / Seat #', field: 'name', align: 'left' as const },
  { name: 'seats', label: 'Seats', field: 'seats', align: 'left' as const },
  { name: 'actions', label: '', field: 'actions', align: 'right' as const },
];

// Generate seat data for a table row
function getSeats(table: Table) {
  const maxSeats = table.max_players || 10;
  const seats = [];
  for (let i = 0; i < maxSeats; i++) {
    // TODO: populate from actual seat data via API
    const occupied = i < (table.seated_count || 0);
    seats.push({
      seat_index: i,
      status: occupied ? 'occupied' as const : 'empty' as const,
      ...(occupied && { player_id: 1000 + i }),
    });
  }
  return seats;
}

const currentFlightId = computed(() => {
  const f = flights.value.find(fl => fl.day_index === selectedDay.value);
  return f ? f.flight_id : 0;
});

function openTableForm(table: Table | null): void {
  editingTable.value = table;
  tableFormOpen.value = true;
}

async function handleTableSaved(): Promise<void> {
  await reload();
}

function enterCC(table: Table): void {
  void tablesApi.launchCc(table.table_id);
}

async function handleRebalance(): Promise<void> {
  const currentFlight = flights.value.find(f => f.day_index === selectedDay.value);
  if (!currentFlight) return;

  rebalancing.value = true;
  rebalanceDialog.value = true;
  rebalanceOutcome.value = null;
  rebalanceSteps.value = [];
  rebalanceBannerVisible.value = true;
  if (bannerTimer) clearTimeout(bannerTimer);

  try {
    // POST triggers the saga; WS events drive progress UI
    await tablesApi.rebalance(currentFlight.flight_id);
    // If no WS events arrive (mock fallback), mark completed after API returns
    if (!rebalanceOutcome.value) {
      rebalanceOutcome.value = 'completed';
      rebalancing.value = false;
      bannerTimer = setTimeout(() => {
        rebalanceBannerVisible.value = false;
        rebalanceDialog.value = false;
      }, 3000);
      await reload();
    }
  } catch {
    rebalanceOutcome.value = 'compensation_failed';
    rebalancing.value = false;
    compensationFailedError.value = 'Rebalance API call failed';
    compensationFailedModal.value = true;
  }
}

function handleRebalanceRetry(): void {
  void handleRebalance();
}
</script>

<style scoped>
.seat-legend {
  width: 14px;
  height: 14px;
  border-radius: 3px;
  margin-right: 4px;
}
.seat-occupied { background: #66bb6a; }
.seat-empty { background: #eeeeee; }
.seat-busted { background: #e57373; }

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.5s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
