<template>
  <q-page class="page-container">
    <div class="page-header">
      <div>
        <div class="page-title">{{ $t('staff.title') }}</div>
      </div>

      <div class="row items-center q-gutter-sm">
        <q-input
          v-model="search"
          :placeholder="$t('common.search')"
          dense
          outlined
          clearable
          style="min-width: 240px"
        >
          <template #prepend>
            <q-icon name="search" />
          </template>
        </q-input>
        <q-select
          v-model="roleFilter"
          dense
          outlined
          :options="roleOptions"
          emit-value
          map-options
          style="width: 150px"
        />
        <q-btn
          color="primary"
          icon="add"
          :label="$t('staff.addUser')"
          @click="openCreateForm"
        />
      </div>
    </div>

    <LoadingState v-if="loading" />
    <ErrorBanner :message="errorMsg" :on-retry="loadUsers" />

    <q-table
      v-if="!loading"
      :rows="filtered"
      :columns="columns"
      row-key="user_id"
      flat
      bordered
      :loading="loading"
    >
      <template #body-cell-role="props">
        <q-td :props="props">
          <q-badge :color="roleBadgeColor(props.row.role)">{{ props.row.role }}</q-badge>
        </q-td>
      </template>
      <template #body-cell-is_active="props">
        <q-td :props="props">
          <q-icon
            :name="props.row.is_active ? 'circle' : 'radio_button_unchecked'"
            :color="props.row.is_active ? 'positive' : 'grey'"
            size="sm"
          />
          {{ props.row.is_active ? 'Active' : 'Disabled' }}
        </q-td>
      </template>
      <template #body-cell-last_login_at="props">
        <q-td :props="props">
          {{ formatRelativeTime(props.row.last_login_at) }}
        </q-td>
      </template>
      <template #body-cell-actions="props">
        <q-td :props="props">
          <q-btn flat dense icon="edit" @click="editUser(props.row)" />
          <q-btn-dropdown flat dense icon="more_vert">
            <q-list>
              <q-item clickable v-close-popup @click="forceLogout(props.row)">
                <q-item-section>{{ $t('staff.forceLogout') }}</q-item-section>
              </q-item>
              <q-item clickable v-close-popup @click="deleteUser(props.row)">
                <q-item-section class="text-negative">{{ $t('common.delete') }}</q-item-section>
              </q-item>
            </q-list>
          </q-btn-dropdown>
        </q-td>
      </template>
    </q-table>

    <UserFormDialog v-model="showForm" :user="editingUser" @saved="loadUsers" />
  </q-page>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import { useQuasar } from 'quasar';
import { useI18n } from 'vue-i18n';
import * as usersApi from 'src/api/users';
import type { User } from 'src/types/models';
import type { QTableColumn } from 'quasar';
import LoadingState from 'components/common/LoadingState.vue';
import ErrorBanner from 'components/common/ErrorBanner.vue';
import UserFormDialog from 'components/staff/UserFormDialog.vue';

const $q = useQuasar();
const { t } = useI18n();

const users = ref<User[]>([]);
const loading = ref(false);
const errorMsg = ref<string | null>(null);
const search = ref('');
const roleFilter = ref('all');
const showForm = ref(false);
const editingUser = ref<User | null>(null);

const roleOptions = [
  { label: 'All', value: 'all' },
  { label: 'Admin', value: 'admin' },
  { label: 'Operator', value: 'operator' },
  { label: 'Viewer', value: 'viewer' },
];

const columns: QTableColumn[] = [
  { name: 'email', label: 'Email', field: 'email', align: 'left', sortable: true },
  { name: 'display_name', label: 'Display Name', field: 'display_name', align: 'left', sortable: true },
  { name: 'role', label: 'Role', field: 'role', align: 'center', sortable: true },
  { name: 'is_active', label: 'Status', field: 'is_active', align: 'center', sortable: true },
  { name: 'last_login_at', label: 'Last Login', field: 'last_login_at', align: 'left', sortable: true },
  { name: 'actions', label: '', field: 'user_id', align: 'right' },
];

const filtered = computed<User[]>(() => {
  let result = users.value;
  const q = search.value.trim().toLowerCase();
  if (q) {
    result = result.filter(
      (u) =>
        u.email.toLowerCase().includes(q) ||
        u.display_name.toLowerCase().includes(q),
    );
  }
  if (roleFilter.value !== 'all') {
    result = result.filter((u) => u.role === roleFilter.value);
  }
  return result;
});

function roleBadgeColor(role: string): string {
  switch (role) {
    case 'admin':
      return 'negative';
    case 'operator':
      return 'primary';
    case 'viewer':
      return 'grey';
    default:
      return 'grey';
  }
}

function formatRelativeTime(iso: string | null): string {
  if (!iso) return '--';
  const diff = Date.now() - new Date(iso).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.floor(hrs / 24);
  return `${days}d ago`;
}

async function loadUsers(): Promise<void> {
  loading.value = true;
  errorMsg.value = null;
  const res = await usersApi.list();
  loading.value = false;
  if (res.error) {
    errorMsg.value = res.error.message;
    return;
  }
  users.value = res.data ?? [];
}

function openCreateForm(): void {
  editingUser.value = null;
  showForm.value = true;
}

function editUser(user: User): void {
  editingUser.value = user;
  showForm.value = true;
}

function forceLogout(user: User): void {
  $q.dialog({
    title: t('staff.forceLogout'),
    message: t('staff.confirmForceLogout'),
    cancel: true,
    persistent: true,
  }).onOk(async () => {
    await usersApi.forceLogout(user.user_id);
    void loadUsers();
  });
}

function deleteUser(user: User): void {
  $q.dialog({
    title: t('common.delete'),
    message: t('staff.confirmDelete'),
    cancel: true,
    persistent: true,
  }).onOk(async () => {
    await usersApi.remove(user.user_id);
    void loadUsers();
  });
}

onMounted(() => {
  void loadUsers();
});
</script>
