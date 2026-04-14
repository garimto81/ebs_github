<!--
  src/components/hand-history/HandDetail.vue — Expandable hand detail
  showing players and actions grouped by street (Preflop/Flop/Turn/River).
-->
<template>
  <div class="q-pa-md">
    <div v-if="loading" class="text-center q-pa-md">
      <q-spinner size="1.5em" />
    </div>

    <template v-else>
      <!-- Players -->
      <div class="text-subtitle2 text-weight-bold q-mb-sm">
        {{ $t('lobby.handHistory.players') }}
      </div>
      <q-table
        :rows="players"
        :columns="playerColumns"
        row-key="id"
        flat
        dense
        bordered
        hide-pagination
        :pagination="{ rowsPerPage: 0 }"
        class="q-mb-md"
      />

      <!-- Board Cards -->
      <div v-if="hand?.board_cards" class="q-mb-md">
        <span class="text-subtitle2 text-weight-bold q-mr-sm">
          {{ $t('lobby.handHistory.board') }}:
        </span>
        <q-badge
          v-for="(card, idx) in boardCards"
          :key="idx"
          color="dark"
          class="q-mr-xs text-body2"
          :label="card"
        />
      </div>

      <!-- Actions by Street -->
      <div class="text-subtitle2 text-weight-bold q-mb-sm">
        {{ $t('lobby.handHistory.actions') }}
      </div>
      <div v-for="street in streets" :key="street">
        <div
          v-if="actionsByStreet[street]?.length"
          class="q-mb-sm"
        >
          <div class="text-caption text-weight-bold text-grey-8 q-mb-xs">
            {{ street }}
          </div>
          <q-list dense bordered separator class="rounded-borders">
            <q-item v-for="a in actionsByStreet[street]" :key="a.id" dense>
              <q-item-section avatar>
                <q-badge color="grey-7" :label="`Seat ${a.seat_no}`" />
              </q-item-section>
              <q-item-section>
                {{ a.action_type }}
                <span v-if="a.action_amount > 0" class="text-weight-bold">
                  {{ a.action_amount.toLocaleString() }}
                </span>
              </q-item-section>
              <q-item-section side>
                <span v-if="a.pot_after != null" class="text-caption text-grey-7">
                  Pot: {{ a.pot_after.toLocaleString() }}
                </span>
              </q-item-section>
            </q-item>
          </q-list>
        </div>
      </div>

      <EmptyState
        v-if="actions.length === 0 && players.length === 0"
        :message="$t('lobby.handHistory.noDetail')"
        icon="info"
      />
    </template>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import EmptyState from 'components/common/EmptyState.vue';
import * as handsApi from 'src/api/hands';
import type { Hand, HandPlayer, HandAction } from 'src/types/models';
import type { QTableColumn } from 'quasar';

const { t } = useI18n();
const props = defineProps<{ handId: number }>();

const hand = ref<Hand | null>(null);
const players = ref<HandPlayer[]>([]);
const actions = ref<HandAction[]>([]);
const loading = ref(true);

const streets = ['Preflop', 'Flop', 'Turn', 'River'];

const playerColumns = computed<QTableColumn[]>(() => [
  { name: 'seat_no', label: t('lobby.handHistory.seat'), field: 'seat_no', align: 'left' },
  { name: 'player_name', label: t('lobby.handHistory.player'), field: 'player_name', align: 'left' },
  { name: 'hole_cards', label: t('lobby.handHistory.holeCards'), field: 'hole_cards', align: 'left' },
  { name: 'start_stack', label: t('lobby.handHistory.startStack'), field: 'start_stack', align: 'right', format: (v: number) => v.toLocaleString() },
  { name: 'end_stack', label: t('lobby.handHistory.endStack'), field: 'end_stack', align: 'right', format: (v: number) => v.toLocaleString() },
  { name: 'pnl', label: t('lobby.handHistory.pnl'), field: 'pnl', align: 'right', format: (v: number) => (v >= 0 ? '+' : '') + v.toLocaleString() },
  { name: 'is_winner', label: t('lobby.handHistory.winner'), field: 'is_winner', align: 'center', format: (v: boolean) => v ? '★' : '' },
]);

const boardCards = computed(() => {
  if (!hand.value?.board_cards) return [];
  return hand.value.board_cards.split(/[,\s]+/).filter(Boolean);
});

const actionsByStreet = computed(() => {
  const grouped: Record<string, HandAction[]> = {};
  for (const street of streets) {
    grouped[street] = actions.value
      .filter((a) => a.street === street)
      .sort((a, b) => a.action_order - b.action_order);
  }
  return grouped;
});

onMounted(async () => {
  try {
    const [handRes, playersRes, actionsRes] = await Promise.all([
      handsApi.getById(props.handId),
      handsApi.getPlayers(props.handId),
      handsApi.getActions(props.handId),
    ]);
    if (handRes.data) hand.value = handRes.data;
    if (playersRes.data) players.value = playersRes.data;
    if (actionsRes.data) actions.value = actionsRes.data;
  } finally {
    loading.value = false;
  }
});
</script>
