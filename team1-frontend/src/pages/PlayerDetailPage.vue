<!--
  src/pages/PlayerDetailPage.vue — Player profile (독립 레이어).
  Route: /players/:playerId
-->
<template>
  <q-page padding>
    <q-btn flat dense icon="arrow_back" :label="$t('common.back')" class="q-mb-md" @click="router.back()" />

    <LoadingState v-if="loading" />

    <template v-if="!loading && player">
      <!-- Profile Header -->
      <q-card flat bordered class="q-mb-md">
        <q-card-section>
          <div class="row items-center q-gutter-md">
            <q-avatar size="64px" color="primary" text-color="white" class="text-h5">
              {{ player.first_name?.charAt(0) }}{{ player.last_name?.charAt(0) }}
            </q-avatar>
            <div>
              <div class="text-h5">{{ player.first_name }} {{ player.last_name }}</div>
              <div class="text-caption text-grey-7">WSOP ID: {{ player.wsop_id ?? '—' }}</div>
              <div class="text-caption text-grey-7">Nationality: {{ player.nationality ?? '—' }}</div>
            </div>
            <q-space />
            <q-badge :color="statusColor" size="lg">{{ playerStatus }}</q-badge>
          </div>
        </q-card-section>
      </q-card>

      <!-- Current Assignment -->
      <q-card flat bordered class="q-mb-md">
        <q-card-section>
          <div class="text-subtitle1 text-weight-bold q-mb-sm">Current Assignment</div>
          <div v-if="currentTable" class="row q-gutter-md">
            <div>
              <div class="text-caption text-grey">Table</div>
              <div class="text-body1">{{ currentTable }}</div>
            </div>
            <div>
              <div class="text-caption text-grey">Seat</div>
              <div class="text-body1">{{ currentSeat ?? '—' }}</div>
            </div>
            <div>
              <div class="text-caption text-grey">Stack</div>
              <div class="text-body1 text-weight-bold">{{ formatStack(player.stack) }}</div>
            </div>
          </div>
          <div v-else class="text-grey">Not assigned to any table</div>
        </q-card-section>
      </q-card>

      <!-- Stats Summary -->
      <div class="row q-gutter-md q-mb-md">
        <q-card flat bordered class="col">
          <q-card-section class="text-center">
            <div class="text-h4">{{ stats.handsPlayed }}</div>
            <div class="text-caption text-grey">Hands Played</div>
          </q-card-section>
        </q-card>
        <q-card flat bordered class="col">
          <q-card-section class="text-center">
            <div class="text-h4">{{ stats.vpip }}%</div>
            <div class="text-caption text-grey">VPIP</div>
          </q-card-section>
        </q-card>
        <q-card flat bordered class="col">
          <q-card-section class="text-center">
            <div class="text-h4">{{ stats.pfr }}%</div>
            <div class="text-caption text-grey">PFR</div>
          </q-card-section>
        </q-card>
        <q-card flat bordered class="col">
          <q-card-section class="text-center">
            <div class="text-h4" :class="stats.pnl >= 0 ? 'text-positive' : 'text-negative'">
              {{ stats.pnl >= 0 ? '+' : '' }}{{ formatStack(stats.pnl) }}
            </div>
            <div class="text-caption text-grey">P&L</div>
          </q-card-section>
        </q-card>
      </div>

      <!-- Stack History (placeholder chart) -->
      <q-card flat bordered class="q-mb-md">
        <q-card-section>
          <div class="text-subtitle1 text-weight-bold q-mb-sm">Stack History</div>
          <div v-if="stackHistory.length === 0" class="text-grey text-center q-pa-lg">
            No hand data yet
          </div>
          <div v-else class="row q-gutter-xs items-end" style="height: 120px">
            <div
              v-for="(entry, idx) in stackHistory"
              :key="idx"
              class="bg-primary"
              :style="{ width: `${100 / stackHistory.length}%`, height: `${(entry.stack / maxStack) * 100}%`, borderRadius: '2px 2px 0 0' }"
              :title="`Hand #${entry.hand_no}: ${formatStack(entry.stack)}`"
            />
          </div>
        </q-card-section>
      </q-card>

      <!-- Table Move History -->
      <q-card flat bordered>
        <q-card-section>
          <div class="text-subtitle1 text-weight-bold q-mb-sm">Table History</div>
          <q-list dense separator>
            <q-item v-for="(move, idx) in moveHistory" :key="idx">
              <q-item-section avatar>
                <q-icon :name="move.type === 'seated' ? 'login' : 'logout'" :color="move.type === 'seated' ? 'positive' : 'grey'" />
              </q-item-section>
              <q-item-section>
                <q-item-label>{{ move.table_name }} — Seat {{ move.seat_index }}</q-item-label>
                <q-item-label caption>{{ formatTime(move.timestamp) }}</q-item-label>
              </q-item-section>
            </q-item>
            <q-item v-if="moveHistory.length === 0">
              <q-item-section class="text-grey">No moves recorded</q-item-section>
            </q-item>
          </q-list>
        </q-card-section>
      </q-card>
    </template>
  </q-page>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import LoadingState from 'components/common/LoadingState.vue';
import * as playersApi from 'src/api/players';
import type { Player } from 'src/types/entities';

const props = defineProps<{ playerId: string }>();
const router = useRouter();

const player = ref<Player | null>(null);
const loading = ref(true);

// Mock data — will be populated from API
const currentTable = ref<string | null>(null);
const currentSeat = ref<number | null>(null);

const stats = ref({
  handsPlayed: 0,
  vpip: 0,
  pfr: 0,
  pnl: 0,
});

const stackHistory = ref<{ hand_no: number; stack: number }[]>([]);
const moveHistory = ref<{ type: string; table_name: string; seat_index: number; timestamp: string }[]>([]);

const maxStack = computed(() => {
  if (stackHistory.value.length === 0) return 1;
  return Math.max(...stackHistory.value.map(e => e.stack));
});

const playerStatus = computed(() => {
  if (!player.value) return 'Unknown';
  if (currentTable.value) return 'Active';
  return 'Waiting';
});

const statusColor = computed(() => {
  return playerStatus.value === 'Active' ? 'positive' : 'grey';
});

onMounted(async () => {
  try {
    const res = await playersApi.getById(Number(props.playerId));
    if (res.data) {
      player.value = res.data;
      // Populate mock assignment data
      if (res.data.table_name) currentTable.value = res.data.table_name;
      if (res.data.seat_index != null) currentSeat.value = res.data.seat_index;
      if (res.data.stack) {
        stats.value.handsPlayed = Math.floor(Math.random() * 200);
        stats.value.vpip = Math.floor(Math.random() * 40) + 10;
        stats.value.pfr = Math.floor(Math.random() * 25) + 5;
        stats.value.pnl = (res.data.stack || 0) - 20000;
        // Mock stack history
        const start = 20000;
        const history = [];
        let current = start;
        for (let i = 1; i <= stats.value.handsPlayed && i <= 30; i++) {
          current += Math.floor((Math.random() - 0.45) * 3000);
          if (current < 0) current = 0;
          history.push({ hand_no: i, stack: current });
        }
        stackHistory.value = history;
      }
    }
  } finally {
    loading.value = false;
  }
});

function formatStack(val: number | undefined | null): string {
  if (val == null) return '—';
  return val.toLocaleString();
}

function formatTime(ts: string): string {
  return new Date(ts).toLocaleString();
}
</script>
