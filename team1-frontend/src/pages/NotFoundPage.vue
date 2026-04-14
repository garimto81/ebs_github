<!--
  src/pages/NotFoundPage.vue — 404 fallback route.
-->
<template>
  <q-page class="flex flex-center">
    <div class="text-center">
      <div class="text-h1 text-grey-5 text-weight-bold">404</div>
      <div class="text-h6 q-mt-sm">{{ $t('notFound.title') }}</div>
      <div class="text-body2 text-grey-7 q-mt-xs">
        {{ $t('notFound.message') }}
      </div>
      <q-btn
        unelevated
        color="primary"
        no-caps
        class="q-mt-md"
        :label="$t('notFound.goHome')"
        @click="router.push('/')"
      />
    </div>
  </q-page>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router';
const router = useRouter();
</script>
