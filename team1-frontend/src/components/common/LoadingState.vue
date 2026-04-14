<template>
  <div class="loading-state full-height column flex-center q-pa-lg">
    <q-spinner color="primary" size="48px" />
    <div class="q-mt-md text-subtitle2 text-grey-7">{{ message ?? $t('common.loading') }}</div>
  </div>
</template>

<script setup lang="ts">
defineProps<{ message?: string }>();
</script>

<style lang="scss" scoped>
.loading-state {
  min-height: 200px;
}
</style>
