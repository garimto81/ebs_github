<!--
  src/components/common/WsDisconnectBanner.vue — Persistent bottom banner
  shown when WebSocket connection is lost.
  Displays reconnect attempt count and animates while reconnecting.
-->
<template>
  <transition name="slide-up">
    <div
      v-if="visible"
      class="ws-disconnect-banner row items-center justify-center q-pa-sm"
    >
      <q-icon name="wifi_off" size="sm" class="q-mr-sm" />
      <span class="text-body2">
        WebSocket disconnected
        <template v-if="wsStore.status === 'reconnecting'">
          — reconnecting (attempt {{ wsStore.reconnectAttempts }})...
        </template>
        <template v-else-if="wsStore.status === 'error'">
          — connection error
        </template>
      </span>
      <q-spinner-dots
        v-if="wsStore.status === 'reconnecting'"
        size="18px"
        class="q-ml-sm"
      />
      <q-btn
        v-if="wsStore.status === 'error'"
        flat dense no-caps
        color="white"
        label="Retry"
        class="q-ml-md"
        @click="wsStore.connect()"
      />
    </div>
  </transition>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useWsStore } from 'stores/wsStore';

const wsStore = useWsStore();

const visible = computed(() =>
  wsStore.status === 'reconnecting' || wsStore.status === 'error',
);
</script>

<style scoped>
.ws-disconnect-banner {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  z-index: 9000;
  background: #c62828;
  color: #fff;
  min-height: 40px;
}

.slide-up-enter-active,
.slide-up-leave-active {
  transition: transform 0.3s ease, opacity 0.3s ease;
}
.slide-up-enter-from,
.slide-up-leave-to {
  transform: translateY(100%);
  opacity: 0;
}
</style>
