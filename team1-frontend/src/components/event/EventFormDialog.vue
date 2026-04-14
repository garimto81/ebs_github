<!--
  src/components/event/EventFormDialog.vue — Create/Edit Tournament form.
  UI-01 §화면 2 "Create New Tournament" dialog.
  Features: Game Mode (Single/Fixed Rotation/Dealer's Choice), Mix presets,
  Blind Structure inline, Flight auto-creation.
-->
<template>
  <q-dialog :model-value="modelValue" persistent @update:model-value="$emit('update:modelValue', $event)">
    <q-card style="width: 700px; max-width: 95vw">
      <q-card-section class="row items-center bg-red-9 text-white">
        <div class="text-h6">{{ isEdit ? $t('lobby.events.editEvent') : $t('lobby.events.createTournament') }}</div>
        <q-space />
        <q-btn flat round dense icon="close" color="white" v-close-popup />
      </q-card-section>

      <q-card-section class="q-gutter-md" style="max-height: 70vh; overflow-y: auto">
        <!-- Basic Info -->
        <div class="text-subtitle1 text-weight-bold">Basic Information</div>
        <div class="row q-gutter-sm">
          <q-input v-model.number="form.event_no" type="number" label="Event No." outlined dense class="col" />
          <q-input v-model="form.event_name" label="Tournament Name *" outlined dense class="col-8" :rules="[v => !!v || 'Required']" />
        </div>
        <div class="row q-gutter-sm">
          <q-input v-model="form.start_at" label="Start Date/Time" outlined dense type="datetime-local" class="col" />
          <q-input v-model="form.display_buy_in" label="Buy-In ($)" outlined dense type="number" class="col" />
        </div>
        <div class="row q-gutter-sm">
          <q-input v-model.number="form.table_size" label="Table Size" outlined dense type="number" class="col" :rules="[v => v >= 2 && v <= 10 || '2-10']" />
          <q-input v-model.number="form.starting_chip" label="Starting Chips" outlined dense type="number" class="col" />
        </div>

        <q-separator />

        <!-- Game Mode -->
        <div class="text-subtitle1 text-weight-bold">Game Mode</div>
        <q-option-group
          v-model="form.game_mode"
          :options="gameModeOptions"
          type="radio"
          inline
        />

        <!-- Game Type (Single mode) -->
        <q-select
          v-if="form.game_mode === 'single'"
          v-model="form.game_type"
          :options="gameTypeOptions"
          label="Game Type"
          outlined dense
          emit-value map-options
        />

        <!-- Mix Preset (Fixed Rotation / Dealer's Choice) -->
        <template v-if="form.game_mode !== 'single'">
          <q-select
            v-model="form.mix_preset"
            :options="mixPresetOptions"
            label="Mix Preset"
            outlined dense
          />
          <div v-if="form.mix_preset === 'Custom'" class="q-ml-md">
            <q-select
              v-model="form.allowed_games"
              :options="gameTypeOptions"
              label="Allowed Games"
              outlined dense
              multiple
              emit-value map-options
              use-chips
            />
          </div>
          <q-select
            v-if="form.game_mode === 'fixed_rotation'"
            v-model="form.rotation_trigger"
            :options="['Every Hand', 'Every Orbit', 'Every Level']"
            label="Rotation Trigger"
            outlined dense
          />
        </template>

        <q-separator />

        <!-- Blind Structure -->
        <div class="text-subtitle1 text-weight-bold row items-center">
          Blind Structure
          <q-space />
          <q-btn flat dense no-caps icon="add" label="Add Level" @click="addBlindLevel" />
        </div>
        <q-table
          :rows="form.blind_levels"
          :columns="blindColumns"
          row-key="level"
          flat bordered dense
          :pagination="{ rowsPerPage: 0 }"
          hide-pagination
        >
          <template #body="props">
            <q-tr :props="props">
              <q-td>{{ props.row.level }}</q-td>
              <q-td>
                <q-input v-model.number="props.row.small_blind" dense borderless type="number" style="width:70px" />
              </q-td>
              <q-td>
                <q-input v-model.number="props.row.big_blind" dense borderless type="number" style="width:70px" />
              </q-td>
              <q-td>
                <q-input v-model.number="props.row.ante" dense borderless type="number" style="width:70px" />
              </q-td>
              <q-td>
                <q-input v-model.number="props.row.duration_minutes" dense borderless type="number" style="width:60px" />
              </q-td>
              <q-td>
                <q-btn flat dense round icon="delete" size="sm" color="negative" @click="removeBlindLevel(props.rowIndex)" />
              </q-td>
            </q-tr>
          </template>
        </q-table>

        <q-separator />

        <!-- Days / Flights -->
        <div class="text-subtitle1 text-weight-bold">Days / Flights</div>
        <div class="row q-gutter-sm items-center">
          <q-input v-model.number="form.day_count" label="Number of Days" outlined dense type="number" style="width:150px" :rules="[v => v >= 1 || 'Min 1']" />
          <div class="text-caption text-grey-7">
            {{ form.day_count }} Flight(s) will be auto-created (Day 1{{ form.day_count > 1 ? ` ~ Day ${form.day_count}` : '' }})
          </div>
        </div>

        <!-- Tournament Type -->
        <div class="text-subtitle1 text-weight-bold q-mt-sm">Tournament Type</div>
        <q-option-group
          v-model="form.tourn_type"
          :options="tournTypeOptions"
          type="radio"
          inline
        />
        <q-input
          v-if="form.tourn_type === 'reentry'"
          v-model.number="form.reentry_limit"
          label="Re-entry Limit"
          outlined dense type="number"
          style="width:150px"
        />
      </q-card-section>

      <q-separator />
      <q-card-actions align="right" class="q-pa-md">
        <q-btn flat no-caps :label="$t('common.cancel')" v-close-popup />
        <q-btn color="red" unelevated no-caps :label="$t('common.save')" :loading="saving" @click="handleSave" />
      </q-card-actions>
    </q-card>
  </q-dialog>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch } from 'vue';
import { GameType } from 'src/types/enums';
import * as eventsApi from 'src/api/events';

const props = defineProps<{
  modelValue: boolean;
  seriesId: number;
  event?: Record<string, unknown> | null;
}>();

const emit = defineEmits<{
  (e: 'update:modelValue', v: boolean): void;
  (e: 'saved'): void;
}>();

const isEdit = computed(() => !!props.event);
const saving = ref(false);

const form = reactive({
  event_no: 1,
  event_name: '',
  start_at: '',
  display_buy_in: 0,
  table_size: 9,
  starting_chip: 20000,
  game_mode: 'single' as 'single' | 'fixed_rotation' | 'dealers_choice',
  game_type: 0,
  mix_preset: 'HORSE',
  allowed_games: [] as number[],
  rotation_trigger: 'Every Hand',
  blind_levels: [
    { level: 1, small_blind: 100, big_blind: 200, ante: 0, duration_minutes: 60 },
    { level: 2, small_blind: 200, big_blind: 400, ante: 0, duration_minutes: 60 },
    { level: 3, small_blind: 300, big_blind: 600, ante: 100, duration_minutes: 60 },
  ],
  day_count: 1,
  tourn_type: 'standard' as 'standard' | 'reentry' | 'freezeout',
  reentry_limit: 1,
});

const gameModeOptions = [
  { label: 'Single Game', value: 'single' },
  { label: 'Fixed Rotation', value: 'fixed_rotation' },
  { label: "Dealer's Choice", value: 'dealers_choice' },
];

const gameTypeOptions = computed(() =>
  Object.entries(GameType).map(([value, label]) => ({ label: String(label), value: Number(value) })),
);

const mixPresetOptions = [
  'HORSE', 'TORSE', 'HEROS', '8-Game', '9-Game (PPC)', '10-Game',
  'Pick Your PLO', 'NL/PLO Mix', 'Omaha Mix', 'Stud Mix', 'Custom',
];

const tournTypeOptions = [
  { label: 'Standard', value: 'standard' },
  { label: 'Re-entry', value: 'reentry' },
  { label: 'Freezeout', value: 'freezeout' },
];

const blindColumns = [
  { name: 'level', label: 'Level', field: 'level', align: 'center' as const },
  { name: 'sb', label: 'SB', field: 'small_blind', align: 'right' as const },
  { name: 'bb', label: 'BB', field: 'big_blind', align: 'right' as const },
  { name: 'ante', label: 'Ante', field: 'ante', align: 'right' as const },
  { name: 'duration', label: 'Min', field: 'duration_minutes', align: 'right' as const },
  { name: 'actions', label: '', field: 'actions', align: 'center' as const },
];

watch(() => props.event, (ev) => {
  if (ev) {
    Object.assign(form, ev);
  }
});

function addBlindLevel(): void {
  const last = form.blind_levels[form.blind_levels.length - 1];
  form.blind_levels.push({
    level: form.blind_levels.length + 1,
    small_blind: last ? last.small_blind * 2 : 100,
    big_blind: last ? last.big_blind * 2 : 200,
    ante: last ? last.ante : 0,
    duration_minutes: last ? last.duration_minutes : 60,
  });
}

function removeBlindLevel(index: number): void {
  form.blind_levels.splice(index, 1);
  form.blind_levels.forEach((l, i) => { l.level = i + 1; });
}

async function handleSave(): Promise<void> {
  if (!form.event_name) return;
  saving.value = true;
  try {
    const payload = {
      series_id: props.seriesId,
      event_no: form.event_no,
      event_name: form.event_name,
      start_at: form.start_at || null,
      display_buy_in: String(form.display_buy_in),
      table_size: form.table_size,
      starting_chip: form.starting_chip,
      game_type: form.game_mode === 'single' ? form.game_type : 21,
      game_mode: form.game_mode,
      mix_preset: form.game_mode !== 'single' ? form.mix_preset : null,
      day_count: form.day_count,
      tourn_type: form.tourn_type,
      reentry_limit: form.tourn_type === 'reentry' ? form.reentry_limit : null,
    };
    await eventsApi.create(payload);
    emit('saved');
    emit('update:modelValue', false);
  } finally {
    saving.value = false;
  }
}
</script>
