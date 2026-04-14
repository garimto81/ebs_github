<!--
  src/components/table/SeatGrid.vue — Seat color cells for a single table row.
  WSOP LIVE style: colored cells (green=seated, grey=empty, red=busted).
  Used inside TableListPage q-table body rows.
-->
<template>
  <div class="row no-wrap q-gutter-xs">
    <div
      v-for="(seat, idx) in seats"
      :key="idx"
      class="seat-cell"
      :class="seatClass(seat)"
      :title="seatTitle(seat)"
    >
      {{ seatLabel(seat) }}
    </div>
  </div>
</template>

<script setup lang="ts">
interface SeatInfo {
  seat_index: number;
  status: 'occupied' | 'empty' | 'busted';
  player_id?: number;
  player_name?: string;
}

defineProps<{
  seats: SeatInfo[];
  maxSeats: number;
}>();

function seatClass(seat: SeatInfo): string {
  switch (seat.status) {
    case 'occupied': return 'seat-occupied';
    case 'busted': return 'seat-busted';
    default: return 'seat-empty';
  }
}

function seatLabel(seat: SeatInfo): string {
  if (seat.status === 'occupied' && seat.player_id) {
    return `#${seat.player_id}`;
  }
  if (seat.status === 'busted') return '✕';
  return '';
}

function seatTitle(seat: SeatInfo): string {
  if (seat.player_name) return `Seat ${seat.seat_index}: ${seat.player_name}`;
  return `Seat ${seat.seat_index}: ${seat.status}`;
}
</script>

<style scoped>
.seat-cell {
  width: 32px;
  height: 32px;
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 9px;
  font-weight: bold;
  color: white;
}
.seat-occupied {
  background: var(--q-green-4, #66bb6a);
}
.seat-empty {
  background: var(--q-grey-2, #eeeeee);
}
.seat-busted {
  background: var(--q-red-3, #e57373);
}
</style>
