<!--
  src/pages/settings/StatsPage.vue — Statistics display options.
  Equity, Outs, Leaderboard, Score Strip toggles.
-->
<template>
  <div class="q-pa-md">
    <div class="text-subtitle1 text-weight-bold q-mb-md">
      {{ $t('settings.tabs.stats') }}
    </div>

    <div v-if="section.status === 'loading'" class="text-center q-pa-lg">
      <q-spinner size="2em" />
      <div class="q-mt-sm text-grey-6">{{ $t('common.loading') }}</div>
    </div>

    <template v-else>
      <div class="row q-col-gutter-md">
        <div class="col-12">
          <q-toggle
            v-model="form.showEquity"
            :label="$t('settings.stats.showEquity')"
            @update:model-value="onField('showEquity', $event)"
          />
        </div>

        <div class="col-12">
          <q-toggle
            v-model="form.showOuts"
            :label="$t('settings.stats.showOuts')"
            @update:model-value="onField('showOuts', $event)"
          />
        </div>

        <div class="col-12">
          <q-toggle
            v-model="form.showLeaderboard"
            :label="$t('settings.stats.showLeaderboard')"
            @update:model-value="onField('showLeaderboard', $event)"
          />
        </div>

        <div class="col-12">
          <q-toggle
            v-model="form.showScoreStrip"
            :label="$t('settings.stats.showScoreStrip')"
            @update:model-value="onField('showScoreStrip', $event)"
          />
        </div>
      </div>

      <q-banner v-if="section.error" class="bg-negative text-white q-mt-md" rounded>
        {{ section.error }}
      </q-banner>

      <div class="row q-mt-lg q-gutter-sm">
        <q-btn
          flat
          :label="$t('settings.revert')"
          @click="revert"
          :disable="!section.dirty"
        />
        <q-btn
          color="primary"
          :label="$t('common.save')"
          @click="save"
          :loading="section.status === 'saving'"
          :disable="!section.dirty"
        />
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
import { reactive, onMounted, watch } from 'vue';
import { useSettingsStore } from 'src/stores/settingsStore';

const store = useSettingsStore();
const section = store.stats;

const form = reactive({
  showEquity: true,
  showOuts: true,
  showLeaderboard: true,
  showScoreStrip: true,
});

function syncFromStore() {
  const d = section.draft;
  form.showEquity = (d.showEquity as boolean) ?? true;
  form.showOuts = (d.showOuts as boolean) ?? true;
  form.showLeaderboard = (d.showLeaderboard as boolean) ?? true;
  form.showScoreStrip = (d.showScoreStrip as boolean) ?? true;
}

function onField(key: string, value: unknown) {
  store.updateField('stats', key, value);
}

function revert() {
  store.revertSection('stats');
  syncFromStore();
}

async function save() {
  await store.saveSection('stats');
}

onMounted(async () => {
  if (section.status === 'idle') {
    await store.fetchSection('stats');
  }
  syncFromStore();
});

watch(() => section.committed, syncFromStore, { deep: true });
</script>
