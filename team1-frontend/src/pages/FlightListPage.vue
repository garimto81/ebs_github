<!--
  src/pages/FlightListPage.vue — Flight list (stub).
  Route: /events/:eventId/flights. Note the React version embedded flights
  into EventListPage as an accordion; this standalone view is used when the
  user deep-links to a single event's flights.
-->
<template>
  <q-page padding>
    <div class="row items-center q-mb-md">
      <div>
        <div class="text-h5 text-weight-bold">
          {{ $t('lobby.flights.title') }}
        </div>
        <div class="text-caption text-grey-7">
          Event #{{ eventId }}
        </div>
      </div>
      <q-space />
      <q-btn
        v-if="authStore.hasPermission('Lobby', 'Write')"
        color="primary"
        unelevated
        no-caps
        icon="add"
        :label="$t('lobby.flights.newFlight')"
      />
    </div>

    <LoadingState v-if="lobbyStore.flightsState.status === 'loading'" />
    <ErrorBanner
      :message="lobbyStore.flightsState.error"
      :on-retry="reload"
    />
    <EmptyState
      v-if="flights.length === 0 && lobbyStore.flightsState.status === 'success'"
      :message="$t('lobby.flights.empty')"
      icon="flight_takeoff"
    />

    <q-table
      v-if="flights.length > 0"
      :rows="flights"
      :columns="columns"
      row-key="event_flight_id"
      flat
      bordered
      hide-pagination
      :pagination="{ rowsPerPage: 0 }"
      @row-click="(_, row) => handleOpen(row as EventFlight)"
    />
  </q-page>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from 'stores/authStore';
import { useLobbyStore } from 'stores/lobbyStore';
import { useNavStore } from 'stores/navStore';
import LoadingState from 'components/common/LoadingState.vue';
import ErrorBanner from 'components/common/ErrorBanner.vue';
import EmptyState from 'components/common/EmptyState.vue';
import type { EventFlight } from 'src/types/entities';

const props = defineProps<{ eventId: string }>();

const router = useRouter();
const authStore = useAuthStore();
const lobbyStore = useLobbyStore();
const navStore = useNavStore();

const eid = computed(() => Number(props.eventId));

const columns = [
  { name: 'display_name', label: 'Flight', field: 'display_name', align: 'left' as const },
  { name: 'start_time', label: 'Start', field: 'start_time', align: 'left' as const },
  { name: 'entries', label: 'Entries', field: 'entries', align: 'left' as const },
  { name: 'players_left', label: 'Players Left', field: 'players_left', align: 'left' as const },
  { name: 'table_count', label: 'Tables', field: 'table_count', align: 'left' as const },
  { name: 'play_level', label: 'Level', field: 'play_level', align: 'left' as const },
  { name: 'status', label: 'Status', field: 'status', align: 'left' as const },
];

const flights = computed(() =>
  lobbyStore.flightsList.filter((f) => f.event_id === eid.value),
);

onMounted(() => {
  void reload();
});

async function reload(): Promise<void> {
  await lobbyStore.fetchFlights(eid.value);
}

function handleOpen(flight: EventFlight): void {
  if (!['running', 'registering'].includes(flight.status)) return;
  navStore.setFlightId(flight.event_flight_id, flight.display_name);
  void router.push(`/flights/${flight.event_flight_id}/tables`);
}
</script>
