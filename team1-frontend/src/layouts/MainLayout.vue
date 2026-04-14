<!--
  src/layouts/MainLayout.vue — WSOP LIVE Staff Page 정렬 레이아웃 (UI-01 §공통 레이아웃).

  Responsibilities:
  - Red header bar: role badge, datetime (UTC), username, online status, CC dropdown, Settings gear
  - Left sidebar: Tournaments, Staff (Admin only), Players, History sections
  - Breadcrumb: EBS > Series > Event > Table (3계층, Player 독립)
  - <router-view /> for the active page
  - Sidebar hidden on Series list (full-screen card grid)

  Permission-gated nav items use authStore.hasPermission() (CCR-017 Bit Flag).
-->
<template>
  <q-layout view="hHh LpR fFf">
    <!-- Red Header Bar (WSOP LIVE style) -->
    <q-header elevated class="bg-red-9 text-white" style="height: 56px">
      <q-toolbar style="height: 56px">
        <!-- Left: Menu toggle + Role badge -->
        <q-btn
          v-if="showSidebar"
          flat
          dense
          round
          icon="menu"
          aria-label="Menu"
          @click="drawerOpen = !drawerOpen"
        />
        <q-badge
          :color="roleBadgeColor"
          class="q-ml-sm text-weight-bold"
          style="padding: 4px 10px"
        >
          ★ {{ authStore.role?.toUpperCase() }}
        </q-badge>

        <q-space />

        <!-- Center: Breadcrumb -->
        <q-breadcrumbs
          class="text-white text-caption"
          active-color="white"
          separator-color="white"
        >
          <q-breadcrumbs-el label="EBS" to="/series" icon="home" />
          <q-breadcrumbs-el
            v-if="navStore.currentSeriesName"
            :label="navStore.currentSeriesName"
            :to="`/series/${navStore.currentSeriesId}/events`"
          />
          <q-breadcrumbs-el
            v-if="navStore.currentEventName"
            :label="navStore.currentEventName"
            :to="`/events/${navStore.currentEventId}/tables`"
          />
          <q-breadcrumbs-el
            v-if="navStore.currentTableName"
            :label="navStore.currentTableName"
          />
        </q-breadcrumbs>

        <q-space />

        <!-- Right: DateTime + User + CC + Settings -->
        <span class="text-caption q-mr-md gt-sm">
          {{ currentDateTime }}
        </span>

        <span class="text-body2 q-mr-xs">{{ authStore.displayName }}</span>
        <q-icon
          :name="wsConnected ? 'circle' : 'radio_button_unchecked'"
          :color="wsConnected ? 'green-4' : 'grey-5'"
          size="10px"
          class="q-mr-md"
        />

        <!-- CC Monitor dropdown -->
        <q-btn-dropdown
          flat
          dense
          no-caps
          label="CC"
          icon="monitor"
          class="q-mr-sm"
        >
          <q-list dense style="min-width: 250px">
            <q-item-label header>
              {{ $t('layout.activeCc') }}
            </q-item-label>
            <q-item v-if="!activeCcTables.length">
              <q-item-section class="text-grey">
                {{ $t('layout.noCc') }}
              </q-item-section>
            </q-item>
          </q-list>
        </q-btn-dropdown>

        <!-- Settings gear -->
        <q-btn
          flat
          dense
          round
          icon="settings"
          @click="router.push('/settings')"
        />

        <!-- Logout -->
        <q-btn
          flat
          dense
          round
          icon="logout"
          @click="handleLogout"
        />
      </q-toolbar>
    </q-header>

    <!-- Left Sidebar (WSOP LIVE style) — shown after Series entry -->
    <q-drawer
      v-if="showSidebar"
      v-model="drawerOpen"
      show-if-above
      bordered
      :width="240"
      :breakpoint="900"
      class="bg-dark text-white"
    >
      <q-list dark>
        <!-- Tournaments section -->
        <q-expansion-item
          icon="emoji_events"
          :label="$t('layout.nav.tournaments')"
          default-opened
          header-class="text-weight-bold"
        >
          <q-item
            clickable
            :active="isActive('/series') && !isActive('/settings')"
            active-class="bg-white-alpha-8"
            @click="router.push(`/series/${navStore.currentSeriesId}/events`)"
            :disable="!navStore.currentSeriesId"
          >
            <q-item-section avatar><q-icon name="list" /></q-item-section>
            <q-item-section>{{ $t('layout.nav.tournamentList') }}</q-item-section>
          </q-item>

          <q-item
            clickable
            @click="router.push('/settings')"
            :active="isActive('/settings')"
            active-class="bg-white-alpha-8"
          >
            <q-item-section avatar><q-icon name="tune" /></q-item-section>
            <q-item-section>{{ $t('layout.nav.seriesSettings') }}</q-item-section>
          </q-item>
        </q-expansion-item>

        <!-- Staff section (Admin only) -->
        <q-expansion-item
          v-if="authStore.role === 'admin'"
          icon="badge"
          :label="$t('layout.nav.staff')"
          header-class="text-weight-bold"
        >
          <q-item
            clickable
            :active="isActive('/staff')"
            active-class="bg-white-alpha-8"
            @click="router.push('/staff')"
          >
            <q-item-section avatar><q-icon name="people" /></q-item-section>
            <q-item-section>{{ $t('layout.nav.staffList') }}</q-item-section>
          </q-item>
        </q-expansion-item>

        <!-- Players section -->
        <q-expansion-item
          icon="person"
          :label="$t('layout.nav.players')"
          header-class="text-weight-bold"
        >
          <q-item
            clickable
            :active="isActive('/players')"
            active-class="bg-white-alpha-8"
            @click="router.push('/players')"
          >
            <q-item-section avatar><q-icon name="list_alt" /></q-item-section>
            <q-item-section>{{ $t('layout.nav.playerList') }}</q-item-section>
          </q-item>
        </q-expansion-item>

        <!-- History section -->
        <q-expansion-item
          icon="history"
          :label="$t('layout.nav.history')"
          header-class="text-weight-bold"
        >
          <q-item
            clickable
            :active="isActive('/hand-history')"
            active-class="bg-white-alpha-8"
            @click="router.push('/hand-history')"
          >
            <q-item-section avatar><q-icon name="article" /></q-item-section>
            <q-item-section>{{ $t('layout.nav.staffActionHistory') }}</q-item-section>
          </q-item>

          <q-item
            v-if="authStore.role === 'admin'"
            clickable
            :active="isActive('/audit-logs')"
            active-class="bg-white-alpha-8"
            @click="router.push('/audit-logs')"
          >
            <q-item-section avatar><q-icon name="policy" /></q-item-section>
            <q-item-section>{{ $t('layout.nav.auditLogs') }}</q-item-section>
          </q-item>
        </q-expansion-item>

        <!-- Graphic Editor -->
        <q-item
          v-if="authStore.hasPermission('GraphicEditor', 'Read')"
          clickable
          :active="isActive('/graphic-editor')"
          active-class="bg-white-alpha-8"
          @click="router.push('/graphic-editor')"
        >
          <q-item-section avatar><q-icon name="palette" /></q-item-section>
          <q-item-section>{{ $t('layout.nav.graphicEditor') }}</q-item-section>
        </q-item>
      </q-list>
    </q-drawer>

    <q-page-container>
      <router-view />
    </q-page-container>

    <!-- WS disconnect banner (fixed bottom) -->
    <WsDisconnectBanner />
  </q-layout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter, useRoute } from 'vue-router';
import { useAuthStore } from 'stores/authStore';
import { useNavStore } from 'stores/navStore';
import { useWsStore } from 'stores/wsStore';
import WsDisconnectBanner from 'components/common/WsDisconnectBanner.vue';

const router = useRouter();
const route = useRoute();
const authStore = useAuthStore();
const navStore = useNavStore();
const wsStore = useWsStore();

const drawerOpen = ref(true);
const currentDateTime = ref('');
let clockTimer: ReturnType<typeof setInterval> | null = null;

const currentPath = computed(() => route.path);

// Sidebar hidden on Series list (full-screen card grid)
const showSidebar = computed(() => {
  return !currentPath.value.match(/^\/series\/?$/);
});

const wsConnected = computed(() => wsStore.connected);

const activeCcTables = computed(() => [] as string[]); // TODO: populate from wsStore

const roleBadgeColor = computed(() => {
  switch (authStore.role) {
    case 'admin': return 'red-7';
    case 'operator': return 'blue-7';
    case 'viewer': return 'grey-6';
    default: return 'grey';
  }
});

function updateClock(): void {
  const now = new Date();
  const offset = -now.getTimezoneOffset() / 60;
  const sign = offset >= 0 ? '+' : '';
  currentDateTime.value =
    now.toLocaleDateString('en-US', { month: '2-digit', day: '2-digit', year: 'numeric' }) +
    ' ' +
    now.toLocaleTimeString('en-US', { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' }) +
    ` UTC${sign}${offset}`;
}

function isActive(prefix: string): boolean {
  return currentPath.value.startsWith(prefix);
}

async function handleLogout(): Promise<void> {
  await authStore.logout();
  navStore.reset();
  await router.push('/login');
}

onMounted(() => {
  updateClock();
  clockTimer = setInterval(updateClock, 1000);
});

onUnmounted(() => {
  if (clockTimer) clearInterval(clockTimer);
});
</script>

<style scoped>
.bg-white-alpha-8 {
  background: rgba(255, 255, 255, 0.08);
}
</style>
