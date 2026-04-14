<!--
  src/pages/settings/SettingsLayout.vue — 6-tab container for Settings.
  Reference: UI-03 Settings. Tabs (Team 1 scope, non-visual only):
  - Outputs (NDI/HDMI routing)
  - GFX (graphic engine links — not the editor itself)
  - Display (basic display toggles)
  - Rules (game rules + timer + blind)
  - Stats (statistics display options)
  - Preferences (user UI preferences)

  Graphic Editor is Team 4 (Flutter/Rive) — linked from §lobby/graphic-editor.
-->
<template>
  <q-page padding>
    <div class="text-h5 text-weight-bold q-mb-md">
      {{ $t('settings.title') }}
    </div>

    <q-tabs
      v-model="activeTab"
      dense
      no-caps
      align="left"
      class="text-grey-8 q-mb-md"
      indicator-color="primary"
      active-color="primary"
      @update:model-value="(v: string) => router.push(`/settings/${v}`)"
    >
      <q-tab name="outputs" :label="$t('settings.tabs.outputs')" />
      <q-tab name="gfx" :label="$t('settings.tabs.gfx')" />
      <q-tab name="display" :label="$t('settings.tabs.display')" />
      <q-tab name="rules" :label="$t('settings.tabs.rules')" />
      <q-tab name="stats" :label="$t('settings.tabs.stats')" />
      <q-tab
        name="preferences"
        :label="$t('settings.tabs.preferences')"
      />
    </q-tabs>

    <router-view />
  </q-page>
</template>

<script setup lang="ts">
import { ref, watch, onMounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';

const router = useRouter();
const route = useRoute();

const activeTab = ref(extractTab(route.path));

onMounted(() => {
  activeTab.value = extractTab(route.path);
});

watch(
  () => route.path,
  (p) => {
    activeTab.value = extractTab(p);
  },
);

function extractTab(path: string): string {
  const m = path.match(/\/settings\/(\w+)/);
  return m ? (m[1] ?? 'outputs') : 'outputs';
}
</script>
