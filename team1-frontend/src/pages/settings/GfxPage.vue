<!--
  src/pages/settings/GfxPage.vue — Graphics settings.
  Layout preset, card style, player display options, animation speed.
  Team 1 owns CRUD form + rive-js preview. Overlay rendering is Team 4.
-->
<template>
  <div class="q-pa-md">
    <div class="text-subtitle1 text-weight-bold q-mb-md">
      {{ $t('settings.tabs.gfx') }}
    </div>

    <div v-if="section.status === 'loading'" class="text-center q-pa-lg">
      <q-spinner size="2em" />
      <div class="q-mt-sm text-grey-6">{{ $t('common.loading') }}</div>
    </div>

    <template v-else>
      <div class="row q-col-gutter-md">
        <!-- Layout Preset -->
        <div class="col-12 col-sm-6">
          <q-select
            v-model="form.layoutPreset"
            :options="layoutPresetOptions"
            :label="$t('settings.gfx.layoutPreset')"
            emit-value
            map-options
            outlined
            dense
            @update:model-value="onField('layoutPreset', $event)"
          />
        </div>

        <!-- Card Style -->
        <div class="col-12 col-sm-6">
          <q-select
            v-model="form.cardStyle"
            :options="cardStyleOptions"
            :label="$t('settings.gfx.cardStyle')"
            emit-value
            map-options
            outlined
            dense
            @update:model-value="onField('cardStyle', $event)"
          />
        </div>

        <!-- Player Display Options -->
        <div class="col-12">
          <div class="text-caption text-grey-7 q-mb-xs">
            {{ $t('settings.gfx.playerDisplayOptions') }}
          </div>
          <q-toggle
            v-model="form.showPlayerPhoto"
            :label="$t('settings.gfx.showPlayerPhoto')"
            @update:model-value="onField('showPlayerPhoto', $event)"
          />
          <q-toggle
            v-model="form.showPlayerFlag"
            :label="$t('settings.gfx.showPlayerFlag')"
            @update:model-value="onField('showPlayerFlag', $event)"
          />
          <q-toggle
            v-model="form.showChipCount"
            :label="$t('settings.gfx.showChipCount')"
            @update:model-value="onField('showChipCount', $event)"
          />
        </div>

        <!-- Animation Speed -->
        <div class="col-12">
          <div class="text-caption text-grey-7 q-mb-xs">
            {{ $t('settings.gfx.animationSpeed') }}: {{ form.animationSpeed }}x
          </div>
          <q-slider
            v-model="form.animationSpeed"
            :min="0.5"
            :max="3"
            :step="0.25"
            label
            :label-value="`${form.animationSpeed}x`"
            color="primary"
            @update:model-value="onField('animationSpeed', $event)"
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
const section = store.gfx;

const layoutPresetOptions = [
  { label: 'Standard (9-max)', value: 'standard-9' },
  { label: 'Standard (6-max)', value: 'standard-6' },
  { label: 'Heads Up', value: 'heads-up' },
  { label: 'Final Table', value: 'final-table' },
];

const cardStyleOptions = [
  { label: 'Classic', value: 'classic' },
  { label: 'Four-Color', value: 'four-color' },
  { label: 'Jumbo', value: 'jumbo' },
];

const form = reactive({
  layoutPreset: 'standard-9',
  cardStyle: 'classic',
  showPlayerPhoto: true,
  showPlayerFlag: true,
  showChipCount: true,
  animationSpeed: 1,
});

function syncFromStore() {
  const d = section.draft;
  form.layoutPreset = (d.layoutPreset as string) ?? 'standard-9';
  form.cardStyle = (d.cardStyle as string) ?? 'classic';
  form.showPlayerPhoto = (d.showPlayerPhoto as boolean) ?? true;
  form.showPlayerFlag = (d.showPlayerFlag as boolean) ?? true;
  form.showChipCount = (d.showChipCount as boolean) ?? true;
  form.animationSpeed = (d.animationSpeed as number) ?? 1;
}

function onField(key: string, value: unknown) {
  store.updateField('gfx', key, value);
}

function revert() {
  store.revertSection('gfx');
  syncFromStore();
}

async function save() {
  await store.saveSection('gfx');
}

onMounted(async () => {
  if (section.status === 'idle') {
    await store.fetchSection('gfx');
  }
  syncFromStore();
});

watch(() => section.committed, syncFromStore, { deep: true });
</script>
