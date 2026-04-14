<template>
  <q-banner v-if="message" class="bg-negative text-white q-my-md">
    <template #avatar>
      <q-icon name="error" />
    </template>
    {{ message }}
    <template v-if="onRetry" #action>
      <q-btn flat color="white" :label="$t('common.retry')" @click="onRetry" />
    </template>
  </q-banner>
</template>

<script setup lang="ts">
defineProps<{
  message: string | null;
  onRetry?: () => void;
}>();
</script>
