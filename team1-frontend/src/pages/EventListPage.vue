<!--
  src/pages/EventListPage.vue — UI-01 §화면 2 Event Management.
  WSOP LIVE Staff Page "Management" 화면 정렬 (2026-04-13).

  Features:
  - Multi-filter bar (Event No, Name, Mix, Game Type, Tournament Type)
  - Status tabs: All / Announced / Registering / Running / Completed / Cancelled (with counts)
  - Today's Events quick filter
  - 15-column DataTable (WSOP LIVE parity)
  - Flight inline sub-rows (accordion expand)
  - [Create New Tournament] red button
-->
<template>
  <q-page padding>
    <!-- Page header -->
    <div class="row items-center q-mb-sm">
      <div>
        <div class="text-h5 text-weight-bold">Management</div>
        <div class="text-caption text-grey-7">Series #{{ seriesId }}</div>
      </div>
      <q-space />
      <q-btn
        v-if="authStore.hasPermission('Lobby', 'Write')"
        color="red"
        unelevated
        no-caps
        icon="add"
        :label="$t('lobby.events.createTournament')"
        @click="showForm = true"
      />
    </div>

    <!-- Multi-filter bar -->
    <div class="row q-gutter-sm q-mb-sm items-end">
      <q-input
        v-model="filters.eventNo"
        dense outlined
        :label="$t('lobby.events.filterEventNo')"
        style="width: 100px"
      />
      <q-input
        v-model="filters.name"
        dense outlined
        :label="$t('lobby.events.filterName')"
        style="width: 180px"
      />
      <q-select
        v-model="filters.mix"
        dense outlined
        :options="['All', 'Single', 'Mix']"
        :label="$t('lobby.events.filterMix')"
        style="width: 100px"
      />
      <q-select
        v-model="filters.gameType"
        dense outlined
        :options="gameTypeOptions"
        :label="$t('lobby.events.filterGameType')"
        style="width: 140px"
        emit-value
        map-options
      />
      <q-select
        v-model="filters.tournType"
        dense outlined
        :options="['All', 'Freezeout', 'Re-entry']"
        :label="$t('lobby.events.filterTournType')"
        style="width: 140px"
      />
      <q-btn dense color="primary" icon="search" @click="applyFilters" />
      <q-btn dense flat icon="refresh" @click="resetFilters" />
    </div>

    <!-- Status tabs -->
    <q-tabs
      v-model="activeTab"
      dense no-caps align="left"
      class="text-grey-8 q-mb-sm"
      indicator-color="primary"
      active-color="primary"
    >
      <q-tab name="all">
        <span>All</span>
        <q-badge color="grey-6" floating>{{ statusCounts.all }}</q-badge>
      </q-tab>
      <q-tab name="announced">
        <span>Announced</span>
        <q-badge color="grey-5" floating>{{ statusCounts.announced }}</q-badge>
      </q-tab>
      <q-tab name="registering">
        <span>Registering</span>
        <q-badge color="blue" floating>{{ statusCounts.registering }}</q-badge>
      </q-tab>
      <q-tab name="running">
        <span>Running</span>
        <q-badge color="green" floating>{{ statusCounts.running }}</q-badge>
      </q-tab>
      <q-tab name="completed">
        <span>Completed</span>
        <q-badge color="grey-6" floating>{{ statusCounts.completed }}</q-badge>
      </q-tab>
      <q-tab name="cancelled">
        <span>Cancelled</span>
        <q-badge color="red" floating>{{ statusCounts.cancelled }}</q-badge>
      </q-tab>
    </q-tabs>

    <!-- Quick filters -->
    <div class="row q-mb-md q-gutter-sm">
      <q-btn
        flat dense no-caps
        icon="today"
        :label="$t('lobby.events.todayEvents')"
        :color="showToday ? 'primary' : 'grey'"
        @click="showToday = !showToday"
      />
    </div>

    <!-- Loading / Error / Empty states -->
    <LoadingState v-if="lobbyStore.eventsState.status === 'loading'" />
    <ErrorBanner :message="lobbyStore.eventsState.error" :on-retry="reload" />
    <EmptyState
      v-if="filtered.length === 0 && lobbyStore.eventsState.status === 'success'"
      :message="$t('lobby.events.empty')"
      icon="event"
    />

    <!-- 15-column DataTable -->
    <q-table
      v-if="filtered.length > 0"
      :rows="filtered"
      :columns="columns"
      row-key="event_id"
      flat bordered
      :pagination="{ rowsPerPage: 20 }"
      dense
    >
      <!-- Event Name cell with expand button for flights -->
      <template #body-cell-event_name="props">
        <q-td :props="props">
          <div class="row items-center no-wrap">
            <q-btn
              flat dense round size="sm"
              :icon="isExpanded(props.row.event_id) ? 'expand_less' : 'expand_more'"
              @click="toggleExpand(props.row.event_id)"
            />
            <span class="q-ml-xs">{{ props.row.event_name }}</span>
          </div>
        </q-td>
      </template>

      <!-- Status badge -->
      <template #body-cell-status="props">
        <q-td :props="props">
          <q-badge :color="statusColor(props.row.status)">
            {{ props.row.status }}
          </q-badge>
        </q-td>
      </template>

      <!-- Prize Pool / Buy-in formatting -->
      <template #body-cell-prize_pool="props">
        <q-td :props="props">
          {{ formatCurrency(props.row.prize_pool) }}
        </q-td>
      </template>
      <template #body-cell-guarantee="props">
        <q-td :props="props">
          {{ formatCurrency(props.row.guarantee) }}
        </q-td>
      </template>
      <template #body-cell-buy_in="props">
        <q-td :props="props">
          {{ formatCurrency(props.row.display_buy_in) }}
        </q-td>
      </template>

      <!-- Expanded flight sub-rows -->
      <template #body="props">
        <q-tr :props="props">
          <q-td v-for="col in props.cols" :key="col.name" :props="props">
            <template v-if="col.name === 'event_name'">
              <div class="row items-center no-wrap">
                <q-btn
                  flat dense round size="sm"
                  :icon="isExpanded(props.row.event_id) ? 'expand_less' : 'expand_more'"
                  @click="toggleExpand(props.row.event_id)"
                />
                <span class="q-ml-xs">{{ props.row.event_name }}</span>
              </div>
            </template>
            <template v-else-if="col.name === 'status'">
              <q-badge :color="statusColor(props.row.status)">
                {{ props.row.status }}
              </q-badge>
            </template>
            <template v-else-if="['prize_pool', 'guarantee', 'buy_in'].includes(col.name)">
              {{ formatCurrency(col.value) }}
            </template>
            <template v-else>
              {{ col.value ?? '—' }}
            </template>
          </q-td>
        </q-tr>
        <!-- Flight sub-rows when expanded -->
        <template v-if="isExpanded(props.row.event_id)">
          <q-tr
            v-for="flight in getFlights(props.row.event_id)"
            :key="flight.flight_id"
            class="bg-grey-1 cursor-pointer"
            @click="navigateToTables(props.row.event_id, flight.day_index)"
          >
            <q-td colspan="3" class="q-pl-xl">
              └ {{ flight.flight_name }}
            </q-td>
            <q-td>{{ flight.table_count }} tables</q-td>
            <q-td>{{ flight.player_count }} players</q-td>
            <q-td>
              <q-badge :color="statusColor(flight.status)">
                {{ flight.status }}
              </q-badge>
            </q-td>
            <q-td :colspan="columns.length - 6" />
          </q-tr>
        </template>
      </template>
    </q-table>

    <!-- Create/Edit Tournament Dialog -->
    <EventFormDialog
      v-model="showForm"
      :series-id="sid"
      @saved="reload"
    />
  </q-page>
</template>

<script setup lang="ts">
import { ref, computed, reactive, onMounted, watch } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from 'stores/authStore';
import { useLobbyStore } from 'stores/lobbyStore';
import LoadingState from 'components/common/LoadingState.vue';
import ErrorBanner from 'components/common/ErrorBanner.vue';
import EmptyState from 'components/common/EmptyState.vue';
import EventFormDialog from 'components/event/EventFormDialog.vue';
import { GameType } from 'src/types/enums';

const props = defineProps<{ seriesId: string }>();
const router = useRouter();
const authStore = useAuthStore();
const lobbyStore = useLobbyStore();

// State
const activeTab = ref('all');
const showForm = ref(false);
const showToday = ref(false);
const expandedIds = ref<Set<number>>(new Set());

const filters = reactive({
  eventNo: '',
  name: '',
  mix: 'All',
  gameType: 'All',
  tournType: 'All',
});

const gameTypeOptions = computed(() => {
  const types = Object.entries(GameType)
    .filter(([, v]) => typeof v === 'number')
    .map(([label, value]) => ({ label, value }));
  return [{ label: 'All', value: 'All' }, ...types];
});

// 15-column definition (WSOP LIVE parity)
const columns = [
  { name: 'start_time', label: 'Start Time', field: 'start_at', align: 'left' as const, sortable: true,
    format: (v: string) => v ? new Date(v).toLocaleDateString('en-US', { month: '2-digit', day: '2-digit' }) : '—' },
  { name: 'event_no', label: 'No.', field: 'event_no', align: 'left' as const, sortable: true },
  { name: 'event_name', label: 'Event Name / Flights', field: 'event_name', align: 'left' as const },
  { name: 'remaining', label: 'Remain/Total', field: (r: Record<string, number>) => `${r.remaining_players ?? '—'}/${r.total_players ?? '—'}`, align: 'left' as const },
  { name: 'unique', label: 'Unique', field: 'unique_entries', align: 'right' as const, sortable: true },
  { name: 'alt_entries', label: 'Alt Ent', field: 'alt_entries', align: 'right' as const },
  { name: 'status', label: 'Status', field: 'status', align: 'left' as const, sortable: true },
  { name: 'level', label: 'Level', field: 'current_level', align: 'right' as const },
  { name: 'late_reg', label: 'Late Reg', field: 'late_reg_status', align: 'left' as const },
  { name: 'prize_pool', label: 'Prize Pool', field: 'prize_pool', align: 'right' as const, sortable: true },
  { name: 'guarantee', label: 'Guarantee', field: 'guarantee', align: 'right' as const },
  { name: 'buy_in', label: 'Buy-In', field: 'display_buy_in', align: 'right' as const, sortable: true },
  { name: 'tickets', label: 'Tickets', field: 'ticket_count', align: 'right' as const },
  { name: 'registration', label: 'Reg', field: 'registration_status', align: 'left' as const },
  { name: 'chip_mode', label: 'Chip M', field: 'chip_mode', align: 'left' as const },
];

const sid = computed(() => Number(props.seriesId));

onMounted(() => {
  lobbyStore.selectSeries(sid.value);
  void reload();
});

watch(() => props.seriesId, () => {
  lobbyStore.selectSeries(sid.value);
  void reload();
});

async function reload(): Promise<void> {
  await lobbyStore.fetchEvents(sid.value);
}

// Status counts for tab badges
const statusCounts = computed(() => {
  const events = lobbyStore.eventsList.filter(e => e.series_id === sid.value);
  return {
    all: events.length,
    announced: events.filter(e => e.status === 'announced').length,
    registering: events.filter(e => e.status === 'registering').length,
    running: events.filter(e => e.status === 'running').length,
    completed: events.filter(e => e.status === 'completed').length,
    cancelled: events.filter(e => e.status === 'cancelled').length,
  };
});

// Filtered events
const filtered = computed(() => {
  let events = lobbyStore.eventsList.filter(e => e.series_id === sid.value);

  // Status tab
  if (activeTab.value !== 'all') {
    events = events.filter(e => e.status === activeTab.value);
  }

  // Today filter
  if (showToday.value) {
    const today = new Date().toISOString().slice(0, 10);
    events = events.filter(e => (e.start_time ?? '').startsWith(today));
  }

  // Multi-filters
  if (filters.eventNo) {
    events = events.filter(e => String(e.event_no).includes(filters.eventNo));
  }
  if (filters.name) {
    events = events.filter(e => e.event_name.toLowerCase().includes(filters.name.toLowerCase()));
  }
  if (filters.gameType !== 'All') {
    events = events.filter(e => e.game_type === Number(filters.gameType));
  }

  return events;
});

// Expand / collapse
function isExpanded(eventId: number): boolean {
  return expandedIds.value.has(eventId);
}

function toggleExpand(eventId: number): void {
  if (expandedIds.value.has(eventId)) {
    expandedIds.value.delete(eventId);
  } else {
    expandedIds.value.add(eventId);
  }
}

function getFlights(eventId: number) {
  return lobbyStore.flightsList.filter(f => f.event_id === eventId);
}

function navigateToTables(eventId: number, dayIndex?: number): void {
  const query = dayIndex != null ? { day: String(dayIndex) } : {};
  void router.push({ path: `/events/${eventId}/tables`, query });
}

// Helpers
function statusColor(status: string): string {
  switch (status) {
    case 'running': return 'green';
    case 'registering': return 'blue';
    case 'cancelled': return 'red';
    case 'announced': return 'grey-6';
    default: return 'grey';
  }
}

function formatCurrency(val: number | string | null | undefined): string {
  if (val == null) return '—';
  const num = typeof val === 'string' ? parseFloat(val) : val;
  if (isNaN(num)) return '—';
  return `$${num.toLocaleString()}`;
}

function applyFilters(): void {
  // filters are reactive, computed re-evaluates automatically
}

function resetFilters(): void {
  filters.eventNo = '';
  filters.name = '';
  filters.mix = 'All';
  filters.gameType = 'All';
  filters.tournType = 'All';
  showToday.value = false;
  activeTab.value = 'all';
}
</script>
