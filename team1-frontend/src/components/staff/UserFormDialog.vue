<template>
  <q-dialog v-model="dialogOpen" persistent>
    <q-card style="width: 500px; max-width: 90vw">
      <q-card-section class="row items-center">
        <div class="text-h6">{{ isEdit ? $t('staff.editUser') : $t('staff.addUser') }}</div>
        <q-space />
        <q-btn flat round dense icon="close" v-close-popup />
      </q-card-section>
      <q-separator />
      <q-card-section>
        <q-input
          v-model="form.email"
          :label="$t('staff.email')"
          type="email"
          :readonly="isEdit"
          outlined
          class="q-mb-md"
        />
        <q-input
          v-model="form.display_name"
          :label="$t('staff.displayName')"
          outlined
          class="q-mb-md"
        />
        <q-input
          v-if="!isEdit"
          v-model="form.password"
          :label="$t('staff.password')"
          type="password"
          outlined
          class="q-mb-md"
        />

        <div class="text-subtitle2 q-mb-sm">{{ $t('staff.role') }}</div>
        <q-option-group
          v-model="form.role"
          :options="roleOpts"
          type="radio"
          inline
          class="q-mb-md"
        />

        <!-- Table Access (Operator only) -->
        <template v-if="form.role === 'operator'">
          <div class="text-subtitle2 q-mb-sm">{{ $t('staff.tableAccess') }}</div>
          <q-option-group
            v-model="form.table_access"
            :options="accessOpts"
            type="radio"
            inline
            class="q-mb-sm"
          />
          <div v-if="form.table_access === 'specific'" class="q-ml-lg">
            <q-option-group
              v-model="form.table_ids"
              :options="tableOptions"
              type="checkbox"
            />
          </div>
        </template>

        <div class="text-subtitle2 q-mb-sm q-mt-md">{{ $t('staff.accountStatus') }}</div>
        <q-toggle v-model="form.is_active" :label="form.is_active ? 'Active' : 'Disabled'" />
      </q-card-section>
      <q-separator />
      <q-card-actions align="right">
        <q-btn flat :label="$t('common.cancel')" v-close-popup />
        <q-btn color="primary" :label="$t('common.save')" :loading="saving" @click="save" />
      </q-card-actions>
    </q-card>
  </q-dialog>
</template>

<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import * as usersApi from 'src/api/users';
import type { User } from 'src/types/models';

const props = defineProps<{
  modelValue: boolean;
  user: User | null;
}>();

const emit = defineEmits<{
  (e: 'update:modelValue', val: boolean): void;
  (e: 'saved'): void;
}>();

const { t } = useI18n();

const dialogOpen = computed({
  get: () => props.modelValue,
  set: (val: boolean) => emit('update:modelValue', val),
});

const isEdit = computed(() => !!props.user);
const saving = ref(false);

const form = reactive({
  email: '',
  display_name: '',
  password: '',
  role: 'operator' as string,
  table_access: 'all' as string,
  table_ids: [] as number[],
  is_active: true,
});

const roleOpts = [
  { label: 'Admin', value: 'admin' },
  { label: 'Operator', value: 'operator' },
  { label: 'Viewer', value: 'viewer' },
];

const accessOpts = computed(() => [
  { label: t('staff.allTables'), value: 'all' },
  { label: t('staff.specificTables'), value: 'specific' },
]);

// TODO: populate from actual table list via lobbyStore
const tableOptions = computed(() => [
  { label: 'Table 1', value: 1 },
  { label: 'Table 2', value: 2 },
  { label: 'Table 3', value: 3 },
  { label: 'Table 4', value: 4 },
  { label: 'Table 5', value: 5 },
]);

watch(
  () => props.user,
  (user) => {
    if (user) {
      form.email = user.email;
      form.display_name = user.display_name;
      form.password = '';
      form.role = user.role;
      form.is_active = user.is_active;
      form.table_access = 'all';
      form.table_ids = [];
    } else {
      form.email = '';
      form.display_name = '';
      form.password = '';
      form.role = 'operator';
      form.is_active = true;
      form.table_access = 'all';
      form.table_ids = [];
    }
  },
);

async function save(): Promise<void> {
  saving.value = true;
  const payload: Record<string, unknown> = {
    email: form.email,
    display_name: form.display_name,
    role: form.role,
    is_active: form.is_active,
  };
  if (!isEdit.value && form.password) {
    payload.password = form.password;
  }
  if (form.role === 'operator') {
    payload.table_access = form.table_access;
    if (form.table_access === 'specific') {
      payload.table_ids = form.table_ids;
    }
  }

  if (isEdit.value && props.user) {
    await usersApi.update(props.user.user_id, payload as Partial<User>);
  } else {
    await usersApi.create(payload as Partial<User> & { password?: string });
  }
  saving.value = false;
  emit('saved');
  dialogOpen.value = false;
}
</script>
