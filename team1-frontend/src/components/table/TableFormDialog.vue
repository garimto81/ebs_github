<!--
  src/components/table/TableFormDialog.vue — Create/Edit Table dialog.
  UI-01 §화면 3 "New Table" / "Edit Table" form.
  Props: modelValue (v-model open), flightId, table (null = create).
-->
<template>
  <q-dialog :model-value="modelValue" persistent @update:model-value="$emit('update:modelValue', $event)">
    <q-card style="width: 500px; max-width: 90vw">
      <q-card-section class="row items-center">
        <div class="text-h6">{{ isEdit ? $t('common.edit') : $t('lobby.tables.newTable') }}</div>
        <q-space />
        <q-btn flat round dense icon="close" v-close-popup />
      </q-card-section>
      <q-separator />

      <q-card-section class="q-gutter-md">
        <div class="row q-gutter-sm">
          <q-input
            v-model.number="form.table_no"
            :label="$t('lobby.tables.tableNo')"
            type="number"
            outlined dense
            class="col"
            :rules="[v => v > 0 || $t('common.required')]"
          />
          <q-input
            v-model="form.name"
            :label="$t('lobby.tables.tableName')"
            outlined dense
            class="col"
            :rules="[v => !!v || $t('common.required')]"
          />
        </div>

        <q-input
          v-model.number="form.max_players"
          :label="$t('lobby.tables.maxPlayers')"
          type="number"
          outlined dense
          :rules="[v => (v >= 2 && v <= 10) || '2-10']"
        />

        <div class="row q-gutter-sm">
          <q-input
            v-model.number="form.small_blind"
            label="Small Blind"
            type="number"
            outlined dense
            class="col"
          />
          <q-input
            v-model.number="form.big_blind"
            label="Big Blind"
            type="number"
            outlined dense
            class="col"
          />
          <q-input
            v-model.number="form.ante"
            label="Ante"
            type="number"
            outlined dense
            class="col"
          />
        </div>

        <q-toggle
          v-model="form.is_feature"
          :label="$t('lobby.tables.isFeature')"
        />
      </q-card-section>

      <q-separator />
      <q-card-actions align="right">
        <q-btn flat no-caps :label="$t('common.cancel')" v-close-popup />
        <q-btn color="primary" unelevated no-caps :label="$t('common.save')" :loading="saving" @click="handleSave" />
      </q-card-actions>
    </q-card>
  </q-dialog>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch } from 'vue';
import * as tablesApi from 'src/api/tables';
import type { Table } from 'src/types/entities';

const props = defineProps<{
  modelValue: boolean;
  flightId: number;
  table?: Table | null;
}>();

const emit = defineEmits<{
  (e: 'update:modelValue', v: boolean): void;
  (e: 'saved'): void;
}>();

const isEdit = computed(() => !!props.table);
const saving = ref(false);

const form = reactive({
  table_no: 1,
  name: 'Table 1',
  max_players: 9,
  small_blind: 100,
  big_blind: 200,
  ante: 0,
  is_feature: false,
});

watch(() => props.table, (t) => {
  if (t) {
    form.table_no = t.table_no;
    form.name = t.name;
    form.max_players = t.max_players;
    form.small_blind = t.small_blind ?? 0;
    form.big_blind = t.big_blind ?? 0;
    form.ante = t.ante_amount ?? 0;
    form.is_feature = t.type === 'feature';
  } else {
    form.table_no = 1;
    form.name = 'Table 1';
    form.max_players = 9;
    form.small_blind = 100;
    form.big_blind = 200;
    form.ante = 0;
    form.is_feature = false;
  }
});

async function handleSave(): Promise<void> {
  if (!form.name || form.table_no <= 0) return;
  saving.value = true;
  try {
    const payload: Partial<Table> = {
      event_flight_id: props.flightId,
      table_no: form.table_no,
      name: form.name,
      max_players: form.max_players,
      small_blind: form.small_blind,
      big_blind: form.big_blind,
      ante_amount: form.ante,
      type: form.is_feature ? 'feature' : 'general',
    };
    if (isEdit.value && props.table) {
      await tablesApi.update(props.table.table_id, payload);
    } else {
      await tablesApi.create(payload);
    }
    emit('saved');
    emit('update:modelValue', false);
  } finally {
    saving.value = false;
  }
}
</script>
