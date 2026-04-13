<!--
  Root component — delegates to router-view.
  Boot files (quasar.config.js > boot) handle i18n/pinia/axios/ws/msw/router-guards
  before this component mounts.
-->
<template>
  <router-view />
</template>

<script setup lang="ts">
// No logic here. All initialization is in boot files.
</script>
