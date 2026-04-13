<template>
  <div class="empty-state column flex-center q-pa-xl text-grey-6">
    <q-icon :name="icon ?? 'inbox'" size="64px" />
    <div class="q-mt-md text-subtitle1">{{ message ?? $t('common.empty') }}</div>
    <slot name="action" />
  </div>
</template>

<script setup lang="ts">
defineProps<{
  message?: string;
  icon?: string;
}>();
</script>

<style lang="scss" scoped>
.empty-state {
  min-height: 240px;
}
</style>
