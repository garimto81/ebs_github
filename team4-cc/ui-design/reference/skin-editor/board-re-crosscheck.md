# Board GE Reverse Engineering Crosscheck

Canvas: 296x197px (5:2 aspect ratio) | Elements: 14 | Source: `ebs-ge-board.html` + PRD-pokergfx-reverse-engineering

## Verification Summary

| # | Check | Status | Detail |
|---|-------|--------|--------|
| 1 | Element count (14) | **PASS** | 5 Cards + Pot + 100,000 + Sponsor Logo + Blinds + 50k/100k + Hand + 123 + Game Variant + PokerGFX.io |
| 2 | Coordinates (% -> px) | **PASS** | 9 rendered elements mapped; 5 non-rendered use placeholder (0,0,40,20) |
| 3 | Field types coverage | **FAIL** | Transform missing 4 fields, Text missing 9 fields, Animation missing 2 fields |
| 4 | Import modes (BG) | **WARN** | Background needs AT Mode (Flop) / AT Mode (Draw/Stud) / Auto options |
| 5 | Control completeness | **FAIL** | 15 fields in RE spec have no type representation in skin-types.ts |

## BOARD_DEFAULT_ELEMENTS

```typescript
const BOARD_DEFAULT_ELEMENTS: GfxElement[] = [
  // Cards row (top) — rendered on canvas
  { id: 'card1',        label: 'Card 1',        x: 3,   y: 4,   w: 56,  h: 134 },
  { id: 'card2',        label: 'Card 2',        x: 62,  y: 4,   w: 56,  h: 134 },
  { id: 'card3',        label: 'Card 3',        x: 121, y: 4,   w: 56,  h: 134 },
  { id: 'card4',        label: 'Card 4',        x: 181, y: 4,   w: 56,  h: 134 },
  { id: 'card5',        label: 'Card 5',        x: 240, y: 4,   w: 56,  h: 134 },
  // Info row (bottom) — rendered on canvas
  { id: 'pot',          label: 'Pot',            x: 3,   y: 146, w: 41,  h: 43  },
  { id: 'potValue',     label: '100,000',        x: 47,  y: 146, w: 95,  h: 43  },
  { id: 'blinds',       label: 'Blinds',         x: 148, y: 146, w: 41,  h: 43  },
  { id: 'blindsValue',  label: '50,000/100,000', x: 192, y: 146, w: 101, h: 43  },
  // Non-rendered elements — default placeholder position
  { id: 'sponsorLogo',  label: 'Sponsor Logo',   x: 0,   y: 0,   w: 40,  h: 20  },
  { id: 'hand',         label: 'Hand',            x: 0,   y: 0,   w: 40,  h: 20  },
  { id: 'handNumber',   label: '123',             x: 0,   y: 0,   w: 40,  h: 20  },
  { id: 'gameVariant',  label: 'Game Variant',    x: 0,   y: 0,   w: 40,  h: 20  },
  { id: 'branding',     label: 'PokerGFX.io',     x: 0,   y: 0,   w: 40,  h: 20  },
];
```

## GAP List — Type Augmentation Required

### GAP-1: TransformProps (4 fields missing)

| EID | Field | Type | Note |
|-----|-------|------|------|
| GE-07 | zOrder | `number` | Z-order layer index |
| GE-08c | marginX | `number` | Horizontal margin |
| GE-08d | marginY | `number` | Vertical margin |
| GE-08e | cornerRadius | `number` | Border radius |

### GAP-2: TextProps (9 fields missing)

| EID | Field | Type | Note |
|-----|-------|------|------|
| GE-15 | visible | `boolean` | Text visibility toggle |
| GE-18 | hiliteColor | `string` | Highlight color |
| GE-20 | shadow | `boolean \| string` | Shadow toggle + direction |
| GE-21 | shadowColor | `string` | Shadow color |
| GE-22 | byLang | `boolean` | Per-language text toggle |
| GE-22a | outline | `boolean` | Outline toggle |
| GE-22b | outlineWidth | `number` | Outline stroke width |
| GE-22c | outlineColor | `string` | Outline color |

### GAP-3: AnimationProps (2 fields missing)

| EID | Field | Type | Note |
|-----|-------|------|------|
| GE-11 | entryFile | `string` | Animation-in file import |
| GE-13 | exitFile | `string` | Animation-out file import |

### GAP-4: BackgroundProps (mode select)

| EID | Field | Type | Note |
|-----|-------|------|------|
| GE-23 | bgMode | `'Auto' \| 'AT Flop' \| 'AT DrawStud'` | Background mode selector |
