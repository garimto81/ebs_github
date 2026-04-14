<template>
  <q-page class="page-container">
    <div class="page-header">
      <div>
        <div class="page-title">{{ $t('lobby.series.title') }}</div>
        <div class="page-subtitle">{{ $t('lobby.series.total', { count: lobbyStore.seriesList.length }) }}</div>
      </div>

      <div class="row items-center q-gutter-sm">
        <q-input
          v-model="search"
          :placeholder="$t('lobby.series.searchPlaceholder')"
          dense
          outlined
          clearable
          style="min-width: 240px"
        >
          <template #prepend>
            <q-icon name="search" />
          </template>
        </q-input>
        <q-checkbox dense v-model="filterUpdated" :label="$t('lobby.series.onlyUpdated')" />
        <q-checkbox dense v-model="filterBookmarked" :label="$t('lobby.series.bookmarks')" />
        <q-btn flat dense icon="refresh" @click="resetFilters" />
        <q-btn
          v-if="authStore.hasPermission('Lobby', 'Write')"
          color="primary"
          icon="add"
          :label="$t('lobby.series.newSeries')"
          @click="showForm = true"
        />
      </div>
    </div>

    <LoadingState v-if="lobbyStore.seriesState.status === 'loading'" />
    <ErrorBanner :message="lobbyStore.seriesState.error" :on-retry="() => lobbyStore.fetchSeries()" />

    <div v-if="filtered.length === 0 && lobbyStore.seriesState.status === 'success'">
      <EmptyState :message="$t('lobby.series.empty')" icon="emoji_events" />
    </div>

    <div class="row q-col-gutter-md">
      <div v-for="s in filtered" :key="s.series_id" class="col-12 col-sm-6 col-md-4">
        <q-card flat bordered class="cursor-pointer series-card" @click="onSelect(s)">
          <q-card-section>
            <div class="row items-start no-wrap">
              <div class="col text-h6 ellipsis">{{ s.series_name }}</div>
              <q-btn
                flat dense round
                :icon="isBookmarked(s.series_id) ? 'star' : 'star_border'"
                :color="isBookmarked(s.series_id) ? 'amber' : 'grey'"
                @click.stop="toggleBookmark(s.series_id)"
              />
            </div>
            <div class="text-caption text-grey-7">{{ s.year }} · {{ s.currency }}</div>
          </q-card-section>
          <q-separator />
          <q-card-section class="row items-center justify-between q-pt-sm">
            <div class="text-caption text-grey-8">
              {{ formatDate(s.begin_at) }} → {{ formatDate(s.end_at) }}
            </div>
            <q-badge :color="s.is_completed ? 'grey' : 'positive'" :label="s.is_completed ? 'completed' : 'running'" />
          </q-card-section>
        </q-card>
      </div>
    </div>

    <q-dialog v-model="showForm">
      <q-card style="min-width: 360px">
        <q-card-section>
          <div class="text-h6">{{ $t('lobby.series.newSeries') }}</div>
        </q-card-section>
        <q-card-section>
          <div class="text-caption text-grey-7">
            TODO: Series 생성 폼 - B-075 후속 세션에서 포팅
          </div>
        </q-card-section>
        <q-card-actions align="right">
          <q-btn flat :label="$t('common.cancel')" @click="showForm = false" />
          <q-btn flat color="primary" :label="$t('common.save')" disable />
        </q-card-actions>
      </q-card>
    </q-dialog>
  </q-page>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useAuthStore } from 'stores/authStore';
import { useLobbyStore } from 'stores/lobbyStore';
import { useNavStore } from 'stores/navStore';
import LoadingState from 'components/common/LoadingState.vue';
import ErrorBanner from 'components/common/ErrorBanner.vue';
import EmptyState from 'components/common/EmptyState.vue';
import type { Series } from 'src/types/entities';

const authStore = useAuthStore();
const lobbyStore = useLobbyStore();
const navStore = useNavStore();
const router = useRouter();

const search = ref('');
const showForm = ref(false);
const filterUpdated = ref(false);
const filterBookmarked = ref(false);

const BOOKMARKS_KEY = 'ebs_bookmarked_series';

const bookmarks = ref<number[]>(
  JSON.parse(localStorage.getItem(BOOKMARKS_KEY) ?? '[]') as number[],
);

function isBookmarked(id: number): boolean {
  return bookmarks.value.includes(id);
}

function toggleBookmark(id: number): void {
  const idx = bookmarks.value.indexOf(id);
  if (idx >= 0) {
    bookmarks.value.splice(idx, 1);
  } else {
    bookmarks.value.push(id);
  }
  localStorage.setItem(BOOKMARKS_KEY, JSON.stringify(bookmarks.value));
}

function resetFilters(): void {
  search.value = '';
  filterUpdated.value = false;
  filterBookmarked.value = false;
}

onMounted(() => {
  void lobbyStore.fetchSeries();
});

const filtered = computed<Series[]>(() => {
  let result = lobbyStore.seriesList;
  const q = search.value.trim().toLowerCase();
  if (q) {
    result = result.filter((s) => s.series_name.toLowerCase().includes(q));
  }
  if (filterUpdated.value) {
    const cutoff = Date.now() - 24 * 60 * 60 * 1000;
    result = result.filter((s) => new Date(s.updated_at).getTime() > cutoff);
  }
  if (filterBookmarked.value) {
    result = result.filter((s) => bookmarks.value.includes(s.series_id));
  }
  return result;
});

function formatDate(iso: string | null): string {
  return iso?.slice(0, 10) ?? '—';
}

function onSelect(s: Series): void {
  lobbyStore.selectSeries(s.series_id);
  navStore.setSeriesId(s.series_id, s.series_name);
  void router.push({ name: 'event-list', params: { seriesId: String(s.series_id) } });
}
</script>

<style lang="scss" scoped>
.series-card {
  transition: transform 0.15s ease, box-shadow 0.15s ease;
  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  }
}
</style>
