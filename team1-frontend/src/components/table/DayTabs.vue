<!--
  src/components/table/DayTabs.vue — Day1/Day2/Day3 tab switcher.
  Each tab = 1 Flight. Shows stats (out count, table count).
-->
<template>
  <q-tabs
    :model-value="modelValue"
    dense no-caps align="left"
    class="text-grey-8 q-mb-md"
    indicator-color="primary"
    active-color="primary"
    @update:model-value="$emit('update:modelValue', $event)"
  >
    <q-tab
      v-for="flight in flights"
      :key="flight.flight_id"
      :name="flight.day_index"
    >
      <div class="column items-center">
        <span class="text-weight-bold">{{ flight.flight_name }}</span>
        <span class="text-caption text-grey-6">
          {{ flight.player_count ?? 0 }} players · {{ flight.table_count ?? 0 }} tables
        </span>
      </div>
    </q-tab>
    <q-tab name="__add" icon="add" />
  </q-tabs>
</template>

<script setup lang="ts">
interface FlightInfo {
  flight_id: number;
  flight_name: string;
  day_index: number;
  player_count?: number;
  table_count?: number;
  status?: string;
}

defineProps<{
  modelValue: number;
  flights: FlightInfo[];
}>();

defineEmits<{
  (e: 'update:modelValue', value: number): void;
}>();
</script>
