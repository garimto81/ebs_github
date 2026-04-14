// src/types/enums.ts — Shared enum maps (ported from ebs_lobby-react/types/enums.ts)

export const GameType: Record<number, string> = {
  0: "No Limit Hold'em",
  1: "Fixed Limit Hold'em",
  2: 'Pot Limit Omaha',
  3: 'Omaha Hi-Lo',
  4: 'Razz',
  5: '7-Card Stud',
  6: 'Stud Hi-Lo',
  7: '2-7 Triple Draw',
  8: '2-7 Single Draw',
  9: 'Badugi',
  10: '5-Card Omaha',
  11: 'Big O',
  12: 'Short Deck',
  13: 'Courchevel',
  14: 'Pineapple',
  15: '5-Card Draw',
  16: 'A-5 Triple Draw',
  17: 'Badeucy',
  18: 'Badeucey',
  19: '5-Card Omaha Hi-Lo',
  20: '6-Card Omaha',
  21: 'Mixed Games',
};

export const BetStructure: Record<number, string> = {
  0: 'No Limit',
  1: 'Pot Limit',
  2: 'Fixed Limit',
};

export const TableStatus = {
  EMPTY: 'empty',
  SETUP: 'setup',
  LIVE: 'live',
  PAUSED: 'paused',
  CLOSED: 'closed',
} as const;

export const SeatStatus = {
  VACANT: 'vacant',
  OCCUPIED: 'occupied',
  BUSTED: 'busted',
} as const;

export const EventStatus = {
  CREATED: 'created',
  ANNOUNCED: 'announced',
  REGISTERING: 'registering',
  RUNNING: 'running',
  COMPLETED: 'completed',
} as const;

export const UserRole = {
  ADMIN: 'admin',
  OPERATOR: 'operator',
  VIEWER: 'viewer',
} as const;
