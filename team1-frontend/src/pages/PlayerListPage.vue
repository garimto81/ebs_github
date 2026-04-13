<!--
  src/pages/PlayerListPage.vue — Player 독립 레이어 (어디서든 접근 가능).
  Table의 하위가 아닌 독립 화면. eventId query param으로 이벤트별 필터 가능.
-->
<template>
  <q-page padding>
    <div class="row items-center q-mb-md">
      <div class="text-h5 text-weight-bold">
        {{ $t('lobby.players.title') }}
      </div>
      <q-space />
      <q-input
        v-model="search"
        dense
        outlined
        :placeholder="$t('lobby.players.searchPlaceholder')"
        style="width: 240px"
      >
        <template #prepend>
          <q-icon name="search" />
        </template>
      </q-input>
    </div>

    <LoadingState v-if="loading" />
    <EmptyState
      v-if="!loading && players.length === 0"
      :message="$t('lobby.players.empty')"
      icon="person"
    />

    <q-list v-if="!loading && players.length > 0" bordered separator>
      <q-item
        v-for="p in filtered"
        :key="p.player_id"
        clickable
        @click="handleOpen(p)"
      >
        <q-item-section avatar>
          <q-avatar color="primary" text-color="white">
            {{ p.first_name.charAt(0) }}
          </q-avatar>
        </q-item-section>
        <q-item-section>
          <q-item-label>
            {{ p.first_name }} {{ p.last_name }}
          </q-item-label>
          <q-item-label caption>
            {{ p.nationality ?? '—' }}
          </q-item-label>
        </q-item-section>
      </q-item>
    </q-list>
  </q-page>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import LoadingState from 'components/common/LoadingState.vue';
import EmptyState from 'components/common/EmptyState.vue';
import * as playersApi from 'src/api/players';
import type { Player } from 'src/types/entities';

const router = useRouter();
const route = useRoute();
const players = ref<Player[]>([]);
const loading = ref(true);
const search = ref('');

onMounted(async () => {
  try {
    const eventId = route.query.eventId as string | undefined;
    const res = await playersApi.list(eventId ? { event_id: Number(eventId) } : {});
    if (res.data) players.value = res.data;
  } finally {
    loading.value = false;
  }
});

const filtered = computed(() => {
  const q = search.value.trim().toLowerCase();
  if (!q) return players.value;
  return players.value.filter((p) =>
    `${p.first_name} ${p.last_name}`.toLowerCase().includes(q),
  );
});

function handleOpen(p: Player): void {
  void router.push(`/players/${p.player_id}`);
}
</script>
