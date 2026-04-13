<!--
  src/layouts/MainLayout.vue — Authenticated shell (UI-01 §Layout, UI-A1 §2.1).

  Responsibilities:
  - Top bar with logo + breadcrumb (lobbyStore) + user menu
  - Left drawer with primary navigation (Series / Settings / Graphic Editor)
  - <router-view /> for the active page
  - Logout → authStore.logout() → push('/login')

  Permission-gated nav items use authStore.hasPermission() (CCR-017 Bit Flag).
-->
<template>
  <q-layout view="hHh LpR fFf">
    <q-header elevated class="bg-primary text-white">
      <q-toolbar>
        <q-btn
          flat
          dense
          round
          icon="menu"
          aria-label="Menu"
          @click="drawerOpen = !drawerOpen"
        />
        <q-toolbar-title class="row items-center q-gutter-sm">
          <span class="text-weight-bold">EBS Lobby</span>
          <q-breadcrumbs
            class="text-white text-caption gt-sm"
            active-color="white"
            separator-color="white"
          >
            <q-breadcrumbs-el
              v-if="navStore.currentSeriesName"
              :label="navStore.currentSeriesName"
              :to="`/series/${navStore.currentSeriesId}/events`"
            />
            <q-breadcrumbs-el
              v-if="navStore.currentEventName"
              :label="navStore.currentEventName"
              :to="`/events/${navStore.currentEventId}/flights`"
            />
            <q-breadcrumbs-el
              v-if="navStore.currentFlightName"
              :label="navStore.currentFlightName"
              :to="`/flights/${navStore.currentFlightId}/tables`"
            />
            <q-breadcrumbs-el
              v-if="navStore.currentTableName"
              :label="navStore.currentTableName"
              :to="`/tables/${navStore.currentTableId}`"
            />
          </q-breadcrumbs>
        </q-toolbar-title>

        <q-btn-dropdown flat dense no-caps :label="authStore.displayName">
          <q-list>
            <q-item clickable v-close-popup>
              <q-item-section>
                <q-item-label class="text-caption text-grey">
                  {{ authStore.role }}
                </q-item-label>
                <q-item-label>{{ authStore.user?.email }}</q-item-label>
              </q-item-section>
            </q-item>
            <q-separator />
            <q-item clickable v-close-popup @click="handleLogout">
              <q-item-section avatar>
                <q-icon name="logout" />
              </q-item-section>
              <q-item-section>{{ $t('layout.logout') }}</q-item-section>
            </q-item>
          </q-list>
        </q-btn-dropdown>
      </q-toolbar>
    </q-header>

    <q-drawer
      v-model="drawerOpen"
      show-if-above
      bordered
      :width="240"
      :breakpoint="900"
    >
      <q-list>
        <q-item-label header class="text-grey-8">
          {{ $t('layout.navigation') }}
        </q-item-label>

        <q-item
          clickable
          :active="isActive('/series')"
          active-class="bg-blue-1 text-primary"
          @click="router.push('/series')"
        >
          <q-item-section avatar>
            <q-icon name="view_list" />
          </q-item-section>
          <q-item-section>{{ $t('layout.nav.series') }}</q-item-section>
        </q-item>

        <q-item
          v-if="authStore.hasPermission('Settings', 'Read')"
          clickable
          :active="isActive('/settings')"
          active-class="bg-blue-1 text-primary"
          @click="router.push('/settings')"
        >
          <q-item-section avatar>
            <q-icon name="settings" />
          </q-item-section>
          <q-item-section>{{ $t('layout.nav.settings') }}</q-item-section>
        </q-item>

        <q-item
          v-if="authStore.hasPermission('GraphicEditor', 'Read')"
          clickable
          :active="isActive('/lobby/graphic-editor')"
          active-class="bg-blue-1 text-primary"
          @click="router.push('/lobby/graphic-editor')"
        >
          <q-item-section avatar>
            <q-icon name="palette" />
          </q-item-section>
          <q-item-section>
            {{ $t('layout.nav.graphicEditor') }}
          </q-item-section>
        </q-item>
      </q-list>
    </q-drawer>

    <q-page-container>
      <router-view />
    </q-page-container>
  </q-layout>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useAuthStore } from 'stores/authStore';
import { useNavStore } from 'stores/navStore';

const router = useRouter();
const route = useRoute();
const authStore = useAuthStore();
const navStore = useNavStore();

const drawerOpen = ref(true);

const currentPath = computed(() => route.path);

function isActive(prefix: string): boolean {
  return currentPath.value.startsWith(prefix);
}

async function handleLogout(): Promise<void> {
  await authStore.logout();
  navStore.reset();
  await router.push('/login');
}
</script>
