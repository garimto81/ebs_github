<!--
  src/pages/AuditLogPage.vue — Audit log viewer (Admin only).
  Route: /audit-logs
-->
<template>
  <q-page padding>
    <div class="text-h5 text-weight-bold q-mb-md">
      {{ $t('auditLog.title') }}
    </div>

    <LoadingState v-if="loading" />
    <EmptyState
      v-else-if="logs.length === 0"
      :message="$t('auditLog.empty')"
      icon="policy"
    />

    <q-table
      v-else
      :rows="logs"
      :columns="columns"
      row-key="id"
      flat
      bordered
      :pagination="{ rowsPerPage: 25 }"
      :rows-per-page-options="[10, 25, 50, 100]"
      :filter="filter"
    >
      <template #top-right>
        <q-input
          v-model="filter"
          dense
          outlined
          debounce="300"
          :placeholder="$t('common.search')"
        >
          <template #append>
            <q-icon name="search" />
          </template>
        </q-input>
      </template>
    </q-table>
  </q-page>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import LoadingState from 'components/common/LoadingState.vue';
import EmptyState from 'components/common/EmptyState.vue';
import * as auditLogsApi from 'src/api/audit-logs';
import type { AuditLog } from 'src/types/models';
import type { QTableColumn } from 'quasar';

const { t } = useI18n();
const logs = ref<AuditLog[]>([]);
const loading = ref(true);
const filter = ref('');

const columns = computed<QTableColumn[]>(() => [
  { name: 'created_at', label: t('auditLog.timestamp'), field: 'created_at', align: 'left', sortable: true },
  { name: 'user_id', label: t('auditLog.user'), field: 'user_id', align: 'left', sortable: true },
  { name: 'action', label: t('auditLog.action'), field: 'action', align: 'left', sortable: true },
  { name: 'entity_type', label: t('auditLog.entity'), field: 'entity_type', align: 'left', sortable: true },
  { name: 'detail', label: t('auditLog.details'), field: 'detail', align: 'left' },
  { name: 'ip_address', label: t('auditLog.ip'), field: 'ip_address', align: 'left' },
]);

onMounted(async () => {
  try {
    const res = await auditLogsApi.list();
    if (res.data) logs.value = res.data;
  } finally {
    loading.value = false;
  }
});
</script>
