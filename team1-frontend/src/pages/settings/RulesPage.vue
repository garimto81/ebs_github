<!--
  src/pages/settings/RulesPage.vue — Game rules & player display settings.
  Bomb Pot, Straddle, Sleeper, seat number, player order, highlight active.
-->
<template>
  <div class="q-pa-md">
    <div class="text-subtitle1 text-weight-bold q-mb-md">
      {{ $t('settings.tabs.rules') }}
    </div>

    <div v-if="section.status === 'loading'" class="text-center q-pa-lg">
      <q-spinner size="2em" />
      <div class="q-mt-sm text-grey-6">{{ $t('common.loading') }}</div>
    </div>

    <template v-else>
      <div class="row q-col-gutter-md">
        <!-- Game Rules Section -->
        <div class="col-12">
          <div class="text-subtitle2 text-weight-medium q-mb-sm">
            {{ $t('settings.rules.gameRulesTitle') }}
          </div>
        </div>

        <!-- Bomb Pot -->
        <div class="col-12">
          <q-toggle
            v-model="form.bombPotEnabled"
            :label="$t('settings.rules.bombPot')"
            @update:model-value="onField('bombPotEnabled', $event)"
          />
          <q-input
            v-if="form.bombPotEnabled"
            v-model.number="form.bombPotFrequency"
            type="number"
            :label="$t('settings.rules.bombPotFrequency')"
            outlined
            dense
            :min="1"
            :max="100"
            class="q-ml-lg q-mt-xs"
            style="max-width: 240px"
            :suffix="$t('settings.rules.hands')"
            @update:model-value="onField('bombPotFrequency', $event)"
          />
        </div>

        <!-- Straddle -->
        <div class="col-12">
          <q-toggle
            v-model="form.straddleEnabled"
            :label="$t('settings.rules.straddle')"
            @update:model-value="onField('straddleEnabled', $event)"
          />
          <q-select
            v-if="form.straddleEnabled"
            v-model="form.straddleType"
            :options="straddleTypeOptions"
            :label="$t('settings.rules.straddleType')"
            emit-value
            map-options
            outlined
            dense
            class="q-ml-lg q-mt-xs"
            style="max-width: 240px"
            @update:model-value="onField('straddleType', $event)"
          />
        </div>

        <!-- Sleeper -->
        <div class="col-12">
          <q-toggle
            v-model="form.sleeperEnabled"
            :label="$t('settings.rules.sleeper')"
            @update:model-value="onField('sleeperEnabled', $event)"
          />
        </div>

        <q-separator class="col-12" />

        <!-- Player Display Section -->
        <div class="col-12">
          <div class="text-subtitle2 text-weight-medium q-mb-sm">
            {{ $t('settings.rules.playerDisplayTitle') }}
          </div>
        </div>

        <div class="col-12">
          <q-toggle
            v-model="form.showSeatNumber"
            :label="$t('settings.rules.showSeatNumber')"
            @update:model-value="onField('showSeatNumber', $event)"
          />
        </div>

        <div class="col-12">
          <q-toggle
            v-model="form.showPlayerOrder"
            :label="$t('settings.rules.showPlayerOrder')"
            @update:model-value="onField('showPlayerOrder', $event)"
          />
        </div>

        <div class="col-12">
          <q-toggle
            v-model="form.highlightActivePlayer"
            :label="$t('settings.rules.highlightActivePlayer')"
            @update:model-value="onField('highlightActivePlayer', $event)"
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
const section = store.rules;

const straddleTypeOptions = [
  { label: 'UTG Only', value: 'utg' },
  { label: 'Mississippi', value: 'mississippi' },
  { label: 'Sleeper Straddle', value: 'sleeper' },
  { label: 'Any Position', value: 'any' },
];

const form = reactive({
  bombPotEnabled: false,
  bombPotFrequency: 10,
  straddleEnabled: false,
  straddleType: 'utg',
  sleeperEnabled: false,
  showSeatNumber: true,
  showPlayerOrder: true,
  highlightActivePlayer: true,
});

function syncFromStore() {
  const d = section.draft;
  form.bombPotEnabled = (d.bombPotEnabled as boolean) ?? false;
  form.bombPotFrequency = (d.bombPotFrequency as number) ?? 10;
  form.straddleEnabled = (d.straddleEnabled as boolean) ?? false;
  form.straddleType = (d.straddleType as string) ?? 'utg';
  form.sleeperEnabled = (d.sleeperEnabled as boolean) ?? false;
  form.showSeatNumber = (d.showSeatNumber as boolean) ?? true;
  form.showPlayerOrder = (d.showPlayerOrder as boolean) ?? true;
  form.highlightActivePlayer = (d.highlightActivePlayer as boolean) ?? true;
}

function onField(key: string, value: unknown) {
  store.updateField('rules', key, value);
}

function revert() {
  store.revertSection('rules');
  syncFromStore();
}

async function save() {
  await store.saveSection('rules');
}

onMounted(async () => {
  if (section.status === 'idle') {
    await store.fetchSection('rules');
  }
  syncFromStore();
});

watch(() => section.committed, syncFromStore, { deep: true });
</script>
