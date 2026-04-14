<!--
  src/pages/settings/OutputsPage.vue — Output routing settings.
  Resolution, frame rate, output protocol, Fill & Key routing.
  Uses settingsStore.getSection('outputs') + updateSection pattern.
-->
<template>
  <div class="q-pa-md">
    <div class="text-subtitle1 text-weight-bold q-mb-md">
      {{ $t('settings.tabs.outputs') }}
    </div>

    <div v-if="section.status === 'loading'" class="text-center q-pa-lg">
      <q-spinner size="2em" />
      <div class="q-mt-sm text-grey-6">{{ $t('common.loading') }}</div>
    </div>

    <template v-else>
      <div class="row q-col-gutter-md">
        <!-- Resolution -->
        <div class="col-12 col-sm-6">
          <q-select
            v-model="form.resolution"
            :options="resolutionOptions"
            :label="$t('settings.outputs.resolution')"
            emit-value
            map-options
            outlined
            dense
            @update:model-value="onField('resolution', $event)"
          />
        </div>

        <!-- Frame Rate -->
        <div class="col-12 col-sm-6">
          <q-select
            v-model="form.frameRate"
            :options="frameRateOptions"
            :label="$t('settings.outputs.frameRate')"
            emit-value
            map-options
            outlined
            dense
            @update:model-value="onField('frameRate', $event)"
          />
        </div>

        <!-- Output Protocol -->
        <div class="col-12">
          <div class="text-caption text-grey-7 q-mb-xs">
            {{ $t('settings.outputs.outputProtocol') }}
          </div>
          <q-option-group
            v-model="form.outputProtocol"
            :options="protocolOptions"
            type="radio"
            inline
            @update:model-value="onField('outputProtocol', $event)"
          />
        </div>

        <!-- Fill & Key Routing -->
        <div class="col-12">
          <q-toggle
            v-model="form.fillKeyRouting"
            :label="$t('settings.outputs.fillKeyRouting')"
            @update:model-value="onField('fillKeyRouting', $event)"
          />
        </div>
      </div>

      <!-- Error banner -->
      <q-banner v-if="section.error" class="bg-negative text-white q-mt-md" rounded>
        {{ section.error }}
      </q-banner>

      <!-- Action buttons -->
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
const section = store.outputs;

const resolutionOptions = [
  { label: '1920 x 1080 (Full HD)', value: '1920x1080' },
  { label: '2560 x 1440 (QHD)', value: '2560x1440' },
  { label: '3840 x 2160 (4K UHD)', value: '3840x2160' },
];

const frameRateOptions = [
  { label: '30 fps', value: 30 },
  { label: '60 fps', value: 60 },
];

const protocolOptions = [
  { label: 'NDI', value: 'NDI' },
  { label: 'RTMP', value: 'RTMP' },
  { label: 'SRT', value: 'SRT' },
  { label: 'DIRECT', value: 'DIRECT' },
];

const form = reactive({
  resolution: '1920x1080',
  frameRate: 60,
  outputProtocol: 'NDI',
  fillKeyRouting: false,
});

function syncFromStore() {
  const d = section.draft;
  form.resolution = (d.resolution as string) ?? '1920x1080';
  form.frameRate = (d.frameRate as number) ?? 60;
  form.outputProtocol = (d.outputProtocol as string) ?? 'NDI';
  form.fillKeyRouting = (d.fillKeyRouting as boolean) ?? false;
}

function onField(key: string, value: unknown) {
  store.updateField('outputs', key, value);
}

function revert() {
  store.revertSection('outputs');
  syncFromStore();
}

async function save() {
  await store.saveSection('outputs');
}

onMounted(async () => {
  if (section.status === 'idle') {
    await store.fetchSection('outputs');
  }
  syncFromStore();
});

watch(() => section.committed, syncFromStore, { deep: true });
</script>
