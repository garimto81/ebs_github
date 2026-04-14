<!--
  src/pages/settings/DisplayPage.vue — Display format settings.
  Blinds display format, precision digits, display mode.
-->
<template>
  <div class="q-pa-md">
    <div class="text-subtitle1 text-weight-bold q-mb-md">
      {{ $t('settings.tabs.display') }}
    </div>

    <div v-if="section.status === 'loading'" class="text-center q-pa-lg">
      <q-spinner size="2em" />
      <div class="q-mt-sm text-grey-6">{{ $t('common.loading') }}</div>
    </div>

    <template v-else>
      <div class="row q-col-gutter-md">
        <!-- Blinds Display Format -->
        <div class="col-12">
          <div class="text-caption text-grey-7 q-mb-xs">
            {{ $t('settings.display.blindsFormat') }}
          </div>
          <q-option-group
            v-model="form.blindsFormat"
            :options="blindsFormatOptions"
            type="radio"
            @update:model-value="onField('blindsFormat', $event)"
          />
        </div>

        <!-- Precision Digits -->
        <div class="col-12 col-sm-6">
          <q-input
            v-model.number="form.precisionDigits"
            type="number"
            :label="$t('settings.display.precisionDigits')"
            outlined
            dense
            :min="0"
            :max="4"
            @update:model-value="onField('precisionDigits', $event)"
          />
        </div>

        <!-- Display Mode -->
        <div class="col-12">
          <div class="text-caption text-grey-7 q-mb-xs">
            {{ $t('settings.display.displayMode') }}
          </div>
          <q-option-group
            v-model="form.displayMode"
            :options="displayModeOptions"
            type="radio"
            inline
            @update:model-value="onField('displayMode', $event)"
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
import { useI18n } from 'vue-i18n';

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const { t: _t } = useI18n();
const store = useSettingsStore();
const section = store.display;

const blindsFormatOptions = [
  { label: '100/200', value: 'sb_bb' },
  { label: '100/200/25 (with ante)', value: 'sb_bb_ante' },
];

const displayModeOptions = [
  { label: 'Standard', value: 'standard' },
  { label: 'Compact', value: 'compact' },
];

const form = reactive({
  blindsFormat: 'sb_bb',
  precisionDigits: 0,
  displayMode: 'standard',
});

function syncFromStore() {
  const d = section.draft;
  form.blindsFormat = (d.blindsFormat as string) ?? 'sb_bb';
  form.precisionDigits = (d.precisionDigits as number) ?? 0;
  form.displayMode = (d.displayMode as string) ?? 'standard';
}

function onField(key: string, value: unknown) {
  store.updateField('display', key, value);
}

function revert() {
  store.revertSection('display');
  syncFromStore();
}

async function save() {
  await store.saveSection('display');
}

onMounted(async () => {
  if (section.status === 'idle') {
    await store.fetchSection('display');
  }
  syncFromStore();
});

watch(() => section.committed, syncFromStore, { deep: true });
</script>
