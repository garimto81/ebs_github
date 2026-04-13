<!--
  src/pages/settings/OutputsPage.vue — NDI/HDMI output routing (stub).
  Uses settingsStore.getSection('outputs') + updateSection pattern.
-->
<template>
  <div>
    <div class="text-subtitle1 text-weight-bold q-mb-sm">
      {{ $t('settings.tabs.outputs') }}
    </div>
    <q-card flat bordered>
      <q-card-section>
        <div class="text-caption text-grey-6">
          TODO: port Output routing form (NDI sources, HDMI ports,
          chroma-key toggle). B-080 tracks full implementation.
        </div>
      </q-card-section>
    </q-card>
  </div>
</template>

<script setup lang="ts">
// Placeholder — wiring to settingsStore pending.
</script>
