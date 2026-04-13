<!--
  src/pages/EventListPage.vue — UI-01 §화면 2 Event list.
  Stub shell — full port pending (Tier 2b B-076).

  React source: ebs_lobby-react/pages/EventListPage.tsx (513 lines)
  - Status tabs (all/created/announced/registering/running/completed)
  - Expandable event row → flight accordion
  - New Event form with Mix presets (HORSE/8-Game/PPC), blind structure
    inline creation, Dealer's Choice, Fixed Rotation
  - New Flight form nested under each event

  Current shell: table listing + tab bar + stub dialogs.
-->
<template>
  <q-page padding>
    <div class="page-header row items-center q-mb-md">
      <div>
        <div class="text-h5 text-weight-bold">
          {{ $t('lobby.events.title') }}
        </div>
        <div class="text-caption text-grey-7">
          Series #{{ seriesId }}
        </div>
      </div>
      <q-space />
      <q-btn
        v-if="authStore.hasPermission('Lobby', 'Write')"
        color="primary"
        unelevated
        no-caps
        icon="add"
        :label="$t('lobby.events.newEvent')"
        @click="showForm = true"
      />
    </div>

    <q-tabs
      v-model="activeTab"
      dense
      no-caps
      align="left"
      class="text-grey-8 q-mb-md"
      indicator-color="primary"
      active-color="primary"
    >
      <q-tab
        v-for="tab in statusTabs"
        :key="tab"
        :name="tab"
        :label="tab"
      />
    </q-tabs>

    <LoadingState v-if="lobbyStore.eventsState.status === 'loading'" />
    <ErrorBanner
      :message="lobbyStore.eventsState.error"
      :on-retry="reload"
    />

    <EmptyState
      v-if="filtered.length === 0 && lobbyStore.eventsState.status === 'success'"
      :message="$t('lobby.events.empty')"
      icon="event"
    />

    <q-table
      v-if="filtered.length > 0"
      :rows="filtered"
      :columns="columns"
      row-key="event_id"
      flat
      bordered
      :pagination="{ rowsPerPage: 0 }"
      hide-pagination
    >
      <template #body-cell-actions="props">
        <q-td :props="props">
          <q-btn
            flat
            dense
            size="sm"
            icon="expand_more"
            @click="toggleExpand(props.row.event_id)"
          />
        </q-td>
      </template>
    </q-table>

    <q-dialog v-model="showForm">
      <q-card style="min-width: 420px">
        <q-card-section>
          <div class="text-h6">{{ $t('lobby.events.newEvent') }}</div>
          <div class="text-caption text-grey-7 q-mt-sm">
            TODO: Mix 게임 preset + Blind inline creation 폼 이식 (B-076).
          </div>
        </q-card-section>
        <q-card-actions align="right">
          <q-btn
            flat
            no-caps
            :label="$t('common.cancel')"
            @click="showForm = false"
          />
          <q-btn flat disable no-caps :label="$t('common.save')" />
        </q-card-actions>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue';
import { useAuthStore } from 'stores/authStore';
import { useLobbyStore } from 'stores/lobbyStore';
import LoadingState from 'components/common/LoadingState.vue';
import ErrorBanner from 'components/common/ErrorBanner.vue';
import EmptyState from 'components/common/EmptyState.vue';
import { GameType } from 'src/types/enums';

const props = defineProps<{ seriesId: string }>();

const authStore = useAuthStore();
const lobbyStore = useLobbyStore();

const statusTabs = [
  'all',
  'created',
  'announced',
  'registering',
  'running',
  'completed',
] as const;
const activeTab = ref<(typeof statusTabs)[number]>('all');
const showForm = ref(false);
const expandedEventId = ref<number | null>(null);

const columns = [
  { name: 'event_no', label: 'Event #', field: 'event_no', align: 'left' as const },
  { name: 'event_name', label: 'Name', field: 'event_name', align: 'left' as const },
  {
    name: 'game_type',
    label: 'Game',
    field: (row: { game_type: number }) =>
      GameType[row.game_type] ?? `#${row.game_type}`,
    align: 'left' as const,
  },
  { name: 'buy_in', label: 'Buy-In', field: 'display_buy_in', align: 'left' as const },
  { name: 'table_size', label: 'Table Size', field: 'table_size', align: 'left' as const },
  { name: 'status', label: 'Status', field: 'status', align: 'left' as const },
  { name: 'actions', label: '', field: 'actions', align: 'right' as const },
];

const sid = computed(() => Number(props.seriesId));

onMounted(() => {
  lobbyStore.selectSeries(sid.value);
  void reload();
});

watch(
  () => props.seriesId,
  () => {
    lobbyStore.selectSeries(sid.value);
    void reload();
  },
);

async function reload(): Promise<void> {
  await lobbyStore.fetchEvents(sid.value);
}

const filtered = computed(() => {
  const events = lobbyStore.eventsList.filter(
    (e) => e.series_id === sid.value,
  );
  if (activeTab.value === 'all') return events;
  return events.filter((e) => e.status === activeTab.value);
});

function toggleExpand(eventId: number): void {
  expandedEventId.value =
    expandedEventId.value === eventId ? null : eventId;
}
</script>
