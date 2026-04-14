<!--
  src/components/table/AddPlayerDialog.vue — Assign a player to an empty seat.
  Used from TableDetailPage [+ Add Player] button.
  Props: modelValue, tableId, emptySeats (available seat indices).
-->
<template>
  <q-dialog :model-value="modelValue" persistent @update:model-value="$emit('update:modelValue', $event)">
    <q-card style="width: 500px; max-width: 90vw">
      <q-card-section class="row items-center">
        <div class="text-h6">{{ $t('lobby.tables.addPlayer') }}</div>
        <q-space />
        <q-btn flat round dense icon="close" v-close-popup />
      </q-card-section>
      <q-separator />

      <q-card-section class="q-gutter-md">
        <!-- Player search -->
        <q-input
          v-model="searchQuery"
          :label="$t('lobby.players.searchPlaceholder')"
          outlined dense
          debounce="300"
          @update:model-value="handleSearch"
        >
          <template #prepend><q-icon name="search" /></template>
        </q-input>

        <!-- Player results -->
        <q-list v-if="searchResults.length > 0" bordered separator class="rounded-borders" style="max-height: 200px; overflow-y: auto">
          <q-item
            v-for="player in searchResults"
            :key="player.player_id"
            clickable
            :active="selectedPlayerId === player.player_id"
            active-class="bg-primary text-white"
            @click="selectedPlayerId = player.player_id"
          >
            <q-item-section>
              <q-item-label>{{ player.first_name }} {{ player.last_name }}</q-item-label>
              <q-item-label caption>{{ player.wsop_id }} &middot; {{ player.country_code }}</q-item-label>
            </q-item-section>
          </q-item>
        </q-list>
        <div v-else-if="searchQuery && !searching" class="text-caption text-grey-6">
          {{ $t('lobby.players.empty') }}
        </div>

        <!-- Seat selection -->
        <q-select
          v-model="selectedSeat"
          :options="seatOptions"
          :label="$t('lobby.tables.selectSeat')"
          outlined dense
          emit-value map-options
        />
      </q-card-section>

      <q-separator />
      <q-card-actions align="right">
        <q-btn flat no-caps :label="$t('common.cancel')" v-close-popup />
        <q-btn
          color="primary"
          unelevated no-caps
          :label="$t('common.save')"
          :loading="saving"
          :disable="!selectedPlayerId || selectedSeat == null"
          @click="handleSave"
        />
      </q-card-actions>
    </q-card>
  </q-dialog>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import * as playersApi from 'src/api/players';
import * as seatsApi from 'src/api/seats';
import type { Player } from 'src/types/entities';

const props = defineProps<{
  modelValue: boolean;
  tableId: number;
  emptySeats: number[];
}>();

const emit = defineEmits<{
  (e: 'update:modelValue', v: boolean): void;
  (e: 'saved'): void;
}>();

const searchQuery = ref('');
const searchResults = ref<Player[]>([]);
const searching = ref(false);
const selectedPlayerId = ref<number | null>(null);
const selectedSeat = ref<number | null>(null);
const saving = ref(false);

const seatOptions = computed(() =>
  props.emptySeats.map(s => ({ label: `Seat ${s}`, value: s })),
);

async function handleSearch(q: string | number | null): Promise<void> {
  const query = String(q ?? '').trim();
  if (!query) {
    searchResults.value = [];
    return;
  }
  searching.value = true;
  try {
    const res = await playersApi.search(query);
    searchResults.value = res.data ?? [];
  } finally {
    searching.value = false;
  }
}

async function handleSave(): Promise<void> {
  if (!selectedPlayerId.value || selectedSeat.value == null) return;
  saving.value = true;
  try {
    await seatsApi.assign(props.tableId, selectedSeat.value, {
      player_id: selectedPlayerId.value,
      seat_no: selectedSeat.value,
    });
    emit('saved');
    emit('update:modelValue', false);
  } finally {
    saving.value = false;
  }
}
</script>
