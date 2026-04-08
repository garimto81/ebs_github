# PokerGFX Game State Machine

> Decompiled from `vpt_remote/core.cs` (25,643 LOC, heavily obfuscated).
> Obfuscation layer: `Kusbq8F7xd8hvTfPmi.grulUC7Fy()` for string decryption,
> `_003CModule_003E_007B...007D` guards for control-flow flattening.

---

## 1. State Transition Diagram

### 1.1 High-Level Hand Lifecycle (Flop Games)

```
                            +-----------+
                            |   IDLE    |
                            | (between  |
                            |  hands)   |
                            +-----+-----+
                                  |
                      SendStartHand() / SendNextHand()
                      hand_in_progress = true
                                  |
                                  v
                        +---------+---------+
                        |    SETUP_HAND     |
                        | (blinds/antes     |
                        |  posted, cards    |
                        |  dealt)           |
                        +---------+---------+
                                  |
                      _cards_per_player cards dealt
                      action_on = first_to_act
                                  |
                                  v
                        +---------+---------+
                        |    PRE_FLOP       |
                        | betting round #1  |
                        | (2 hole cards)    |
                        +---------+---------+
                                  |
                  Fold/Check/Bet/Call/Raise/AllIn
                  until action complete
                                  |
                                  v
              +-------------------+-------------------+
              |                                       |
     all fold / 1 player                     2+ players remain
              |                                       |
              v                                       v
    +---------+---------+                   +---------+---------+
    |   HAND_COMPLETE   |                   |       FLOP        |
    | (award pot,       |                   | board_cards[0]=3  |
    |  hand_in_progress |                   | betting round #2  |
    |  = false)         |                   +---------+---------+
    +-------------------+                             |
                                        Fold/Check/Bet/Call/Raise
                                                      |
                                                      v
                                            +---------+---------+
                                            |       TURN        |
                                            | board_cards[0]=4  |
                                            | betting round #3  |
                                            +---------+---------+
                                                      |
                                  final_betting_round check
                                                      |
                                                      v
                                            +---------+---------+
                                            |      RIVER        |
                                            | board_cards[0]=5  |
                                            | betting round #4  |
                                            | final_betting_    |
                                            | round = true      |
                                            +---------+---------+
                                                      |
                                        +-------------+-------------+
                                        |                           |
                                all fold / 1               2+ players
                                        |                           |
                                        v                           v
                              +---------+-------+         +---------+---------+
                              |  HAND_COMPLETE  |         |     SHOWDOWN      |
                              +-----------------+         | (cards revealed,  |
                                                          |  payout awarded)  |
                                                          +---------+---------+
                                                                    |
                                                   optional: Run It Times
                                                   (run_it_times > 0)
                                                                    |
                                                                    v
                                                          +---------+---------+
                                                          | RUN_IT_MULTIPLE   |
                                                          | board reset to    |
                                                          | run_it_times_     |
                                                          | board_cards       |
                                                          | (0=flop,3=turn,  |
                                                          |  4=river)         |
                                                          +---------+---------+
                                                                    |
                                                    run_it_times_remaining--
                                                    until remaining == 0
                                                                    |
                                                                    v
                                                          +-------------------+
                                                          |   HAND_COMPLETE   |
                                                          | hand_in_progress  |
                                                          |   = false         |
                                                          | next_hand_ok chk  |
                                                          +-------------------+
                                                                    |
                                                         ManualNextHand()
                                                         or auto via
                                                         overrideButton
                                                                    |
                                                                    v
                                                              +-----+-----+
                                                              |   IDLE    |
                                                              +-----------+
```

### 1.2 Stud Game Variant

```
    IDLE --> SETUP_HAND --> 3RD_STREET --> 4TH_STREET --> 5TH_STREET
             (bring_in)    (3 cards:      (4th card     (5th card
                            2 down,       dealt)        dealt)
                            1 up)
         --> 6TH_STREET --> 7TH_STREET --> SHOWDOWN --> HAND_COMPLETE
            (6th card      (7th card,
             dealt)         final_
                            betting_
                            round=true)
```

### 1.3 Draw Game Variant

```
    IDLE --> SETUP_HAND --> PRE_DRAW_BET --> DRAW_ROUND --> POST_DRAW_BET
             (5 cards       (betting)        (drawing_     (betting)
              dealt)                          player set,
                                              draw_completed
                                              tracked)
         --> [OPTIONAL 2ND DRAW] --> SHOWDOWN --> HAND_COMPLETE
```

---

## 2. State Definitions

### 2.1 IDLE (Between Hands)

| Property | Value |
|----------|-------|
| `hand_in_progress` | `false` |
| `action_on` | `-1` or last value |
| `cards_on_table` | `false` |
| UI | Init panel visible, play panel hidden |

**Entry Conditions:**
- Application startup (initial state)
- Previous hand completed (`hand_in_progress` set to `false` by server)
- `ManualNextHand()` post-cleanup

**Exit Conditions:**
- Operator presses "Start Hand" --> `SendStartHand()`
- Operator presses "Next Hand" --> `SendNextHand()`
- `start_hand_flop_draw` or `start_hand_stud` returns `true` (all preconditions met)

**Preconditions for start_hand_flop_draw** (line 5400-5649):
- `hand_in_progress == false`
- `pl_dealer != -1` (dealer assigned)
- If `num_blinds == 0`: ready immediately
- If `num_blinds == 1`: `pl_big != -1`, `big > 0`, blind != dealer
- If `num_blinds == 2`: SB and BB assigned, distinct, non-zero stacks
- If `num_blinds == 3`: SB, BB, Third all assigned, distinct, non-zero stacks

### 2.2 SETUP_HAND (Dealing / Blinds)

| Property | Value |
|----------|-------|
| `hand_in_progress` | `true` (set by server) |
| `hand_count` | incremented |
| `cards_on_table` | transitioning to `true` |

**Entry:** Server processes `SendStartHand()`, responds with `GameInfoResponse`

**Exit:** All blinds posted, cards dealt --> betting begins

### 2.3 BETTING_ROUND (PRE_FLOP / FLOP / TURN / RIVER)

| Property | Value |
|----------|-------|
| `action_on` | seat index (0-9) of active player |
| `biggest_bet_amt` | current largest bet |
| `final_betting_round` | `true` on last street |
| `_num_active_players` | count of non-folded players |

**Player Actions (via check_cmd, line 12415+):**
- `SendPlayerFold(action_on)` -- player folds
- `SendPlayerBet(action_on, amount)` -- bet/raise
- `SendPlayerCheckCall(action_on, biggest_bet_amt)` -- check/call
- All-in: `SendPlayerBet(action_on, player[action_on].stack + player[action_on].bet)`

**Street Progression (Flop Games):**
- Board cards tracked in `_board_cards[]` array (up to 3 boards)
- `num_cards(_board_cards[0])` determines current street:
  - 0 cards = PRE_FLOP
  - 3 cards = FLOP
  - 4 cards = TURN
  - 5 cards = RIVER

### 2.4 SHOWDOWN

| Property | Value |
|----------|-------|
| `hand_in_progress` | `true` |
| `final_betting_round` | `true` |
| `cards_on_table` | `true` |

**Entry:** All betting complete with 2+ players remaining

**Actions:**
- Muck or show cards
- Payout calculation via `payout_win`
- Optional: `SendChop()` if `can_chop == true`

### 2.5 RUN_IT_MULTIPLE

| Property | Value |
|----------|-------|
| `run_it_times` | number of runs requested |
| `run_it_times_remaining` | decremented per run |
| `run_it_times_board_cards` | 0=from flop, 3=from turn, 4=from river |
| `can_select_run_it_times` | `true` when eligible |
| `can_trigger_next_board` | `true` when ready |

**Trigger:** `SendRunItTimes()` (line 13426)
**Clear:** `SendRunItTimesClearBoard()` (line 12523)

### 2.6 HAND_COMPLETE

| Property | Value |
|----------|-------|
| `hand_in_progress` | `false` |
| `next_hand_ok` | determines if auto-advance is possible |
| `overrideButton` | manual override availability |

**Exit:** `ManualNextHand()` or override timer triggers `SendNextHand()`

---

## 3. Core State Variables

### 3.1 Game Flow Control

| Variable | Type | Line | Role |
|----------|------|------|------|
| `hand_in_progress` | `bool` | 5196 | Master flag: hand active or idle |
| `action_on` | `int` | 5154 | Seat index (0-9) of player whose turn it is |
| `prev_action_on` | `int` | 5290 | Previous action_on for transition detection |
| `next_hand_ok` | `bool` | 5206 | Server signals readiness for next hand |
| `final_betting_round` | `bool` | 5216 | Last betting round (river/7th street) |
| `cards_on_table` | `bool` | 5214 | Board cards have been dealt |
| `hand_count` | `int` | 5164 | Cumulative hand counter |
| `allow_at_updates` | `bool` | 5198 | Whether Action Tracker can receive updates |

### 3.2 Game Classification

| Variable | Type | Line | Role |
|----------|------|------|------|
| `game_class` | `int` | 5180 | 0=Flop, 1=Draw, 2=Stud |
| `game_type` | `int` | 5182 | 0=Cash, 1=Tournament, 2=SNG, 3=Other |
| `_game_variant` | `string` | 5244 | Current variant name (e.g., "NL Hold'em") |
| `game_variant_list` | `GameVariant[]` | 5380 | Available game variants |
| `_bet_structure` | `bet_structure` | 5284 | NL/FL/PL |
| `_ante_type` | `ante_type` | 5282 | Ante posting method |
| `enh_mode` | `bool` | 5194 | Enhanced mode (auto start hand etc.) |

### 3.3 Table Structure

| Variable | Type | Line | Role |
|----------|------|------|------|
| `num_seats` | `int` | 5108 | Total seats at table (up to 10) |
| `pl_dealer` | `int` | 5126 | Dealer button seat index |
| `pl_small` | `int` | 5128 | Small blind seat index |
| `pl_big` | `int` | 5130 | Big blind seat index |
| `pl_third` | `int` | 5132 | Third blind seat index |
| `num_blinds` | `int` | 5134 | Number of blinds (0-3) |
| `small` | `int` | 5148 | Small blind amount |
| `big` | `int` | 5150 | Big blind amount |
| `third` | `int` | 5152 | Third blind amount |
| `ante` | `int` | 5136 | Ante amount |
| `button_blind` | `int` | 5138 | Button blind (straddle) amount |
| `bring_in` | `int` | 5174 | Stud bring-in amount |
| `smallest_chip` | `int` | 5162 | Minimum denomination |
| `blind_level` | `int` | 5190 | Current blind level (tournament) |

### 3.4 Betting State

| Variable | Type | Line | Role |
|----------|------|------|------|
| `biggest_bet_amt` | `int` | 5156 | Current largest bet on table |
| `min_raise_amt` | `int` | 5262 | Minimum raise size |
| `cap` | `int` | 5140 | Bet cap (0=no cap) |
| `low_limit` | `int` | 5176 | Fixed limit low bet |
| `high_limit` | `int` | 5178 | Fixed limit high bet |
| `predictive_bet` | `bool` | 5272 | Predictive bet entry mode |
| `bomb_pot` | `int` | 5142 | Bomb pot multiplier |
| `seven_deuce` | `int` | 5144 | 7-2 game bounty amount |

### 3.5 Board & Card State

| Variable | Type | Line | Role |
|----------|------|------|------|
| `_board_cards` | `string[]` | 5252 | Board cards per board (up to 3 boards) |
| `num_boards` | `int` | 5146 | Number of simultaneous boards (1-3) |
| `_cards_per_player` | `int` | 5166 | Hole cards per player |
| `_extra_cards_per_player` | `int` | 5168 | Extra cards (e.g., Omaha discard) |
| `_cards_max_len` | `int` | 5158 | Maximum card string length |
| `_num_active_players` | `int` | 5160 | Players still in hand |
| `card_rescan` | `bool` | 5270 | RFID re-scan needed |
| `_card_verify_mode` | `bool` | 5278 | Card verification active |
| `_card_verify_list` | `string` | 5280 | Verified card list |

### 3.6 Draw Game State

| Variable | Type | Line | Role |
|----------|------|------|------|
| `draw_completed` | `int` | 5170 | Number of draw rounds completed |
| `drawing_player` | `int` | 5172 | Seat currently drawing (-1=none) |
| `stud_draw_in_progress` | `bool` | 5218 | Stud dealing in progress |
| `stud_community_card` | `bool` | 5220 | Stud community card variant |

### 3.7 Run It Times

| Variable | Type | Line | Role |
|----------|------|------|------|
| `run_it_times` | `int` | 5112 | Number of run-it-times runs |
| `run_it_times_remaining` | `int` | 5114 | Remaining runs |
| `run_it_times_board_cards` | `int` | 5116 | Board card count at time of agreement |
| `can_select_run_it_times` | `bool` | 5212 | Eligible for run-it-times |
| `can_trigger_next_board` | `bool` | 5276 | Ready for next board run |

### 3.8 Side Game State (Nit Game)

| Variable | Type | Line | Role |
|----------|------|------|------|
| `nit_game_amt` | `int` | 5184 | Nit game pot amount |
| `nit_game_players` | `int` | 5186 | Players in nit game |
| `nit_game_won_player` | `int` | 5188 | Winner seat index |

### 3.9 Transfer / Chop

| Variable | Type | Line | Role |
|----------|------|------|------|
| `xfer_cumwin` | `bool` | 5222 | Transfer cumulative win |
| `can_chop` | `bool` | 5224 | Chop eligible |
| `is_chopped` | `bool` | 5226 | Hand was chopped |
| `overrideButton` | `bool` | 5228 | Manual override active |

### 3.10 Broadcast / AV State

| Variable | Type | Line | Role |
|----------|------|------|------|
| `streaming` | `bool` | 5200 | Stream active |
| `recording` | `bool` | 5202 | Recording active |
| `at_gfx` | `bool` | 5316 | AT graphics overlay enabled |
| `gfx_enable` | `bool` | 5328 | GFX engine enabled |
| `auto_cam` | `bool` | 5318 | Automatic camera switching |
| `ticker_visible` | `bool` | 5308 | Lower third ticker |
| `vid_delay_cam` | `int` | 5292 | Video delay camera |
| `full_video` | `bool` | 5306 | Full video mode |
| `insert_audio` | `bool` | 5312 | Audio insert active |
| `insert_video` | `bool` | 5314 | Video insert active |

---

## 4. Enum Definitions

### 4.1 nit_game_enum (line 327)

```csharp
public enum nit_game_enum
{
    not_playing = 0,  // Player not in nit game
    at_risk     = 1,  // Player is at risk (shortest stack)
    won_hand    = 2,  // Player won the nit game hand
    safe        = 3   // Player is safe (not shortest)
}
```

### 4.2 panel_type (line 335)

```csharp
public enum panel_type
{
    none       = 0,   // No stats panel
    chipcount  = 1,   // Chip count display
    vpip       = 2,   // VPIP percentage
    pfr        = 3,   // PFR percentage
    blinds     = 4,   // Blind amounts
    agr        = 5,   // Aggression factor
    wtsd       = 6,   // Went to showdown %
    position   = 7,   // Table position
    cum_win    = 8,   // Cumulative win/loss
    payouts    = 9,   // Tournament payouts
    pl_stat_1  = 10,  // Custom stat 1
    pl_stat_2  = 11,  // Custom stat 2
    pl_stat_3  = 12,  // Custom stat 3
    pl_stat_4  = 13,  // Custom stat 4
    pl_stat_5  = 14,  // Custom stat 5
    pl_stat_6  = 15,  // Custom stat 6
    pl_stat_7  = 16,  // Custom stat 7
    pl_stat_8  = 17,  // Custom stat 8
    pl_stat_9  = 18,  // Custom stat 9
    pl_stat_10 = 19   // Custom stat 10
}
```

### 4.3 strip_display_type (line 359)

```csharp
public enum strip_display_type
{
    off    = 0,  // Strip display off
    stack  = 1,  // Show stack size
    cumwin = 2   // Show cumulative win
}
```

### 4.4 ante_type (line 366)

```csharp
public enum ante_type
{
    std_ante      = 0,  // Standard ante (each player posts)
    button_ante   = 1,  // Button posts ante for table
    bb_ante       = 2,  // Big blind posts ante for table
    bb_ante_bb1st = 3,  // BB ante, BB acts first
    live_ante     = 4,  // Live ante (counts toward bet)
    tb_ante       = 5,  // Third blind ante
    tb_ante_tb1st = 6   // Third blind ante, TB acts first
}
```

### 4.5 bet_structure (line 377)

```csharp
public enum bet_structure
{
    no_limit    = 0,  // No Limit
    fixed_limit = 1,  // Fixed Limit
    pot_limit   = 2   // Pot Limit
}
```

### 4.6 delayed_audio_type (line 384)

```csharp
public enum delayed_audio_type
{
    none   = 0,  // No delayed audio
    normal = 1,  // Normal delayed audio
    all    = 2   // All audio delayed
}
```

### 4.7 game_class (implicit, via is_*_game properties, line 5760-5764)

```
game_class == 0  -->  is_flop_game  (Hold'em, Omaha, Short Deck, etc.)
game_class == 1  -->  is_draw_game  (5-Card Draw, 2-7 Triple Draw, Badugi, etc.)
game_class == 2  -->  is_stud_game  (7-Card Stud, Razz, etc.)
```

### 4.8 game_type (implicit, via game_type_str, line 5706-5756)

```
game_type == 0  -->  "Cash Game"       (is_cash_game == true)
game_type == 1  -->  "[obfuscated]"    (Tournament)
game_type == 2  -->  "[obfuscated]"    (Sit & Go)
game_type == 3  -->  "[obfuscated]"    (Other/Special)
default         -->  "[obfuscated]"    (Unknown)
```

---

## 5. GameType Variant Matrix

### 5.1 game_class x bet_structure x ante_type Matrix

| game_class | bet_structure | ante_type | Typical Variant |
|:----------:|:-------------:|:---------:|-----------------|
| 0 (Flop) | no_limit (0) | std_ante (0) | NL Hold'em w/ ante |
| 0 (Flop) | no_limit (0) | button_ante (1) | NL Hold'em (WSOP style) |
| 0 (Flop) | no_limit (0) | bb_ante (2) | NL Hold'em (BB ante) |
| 0 (Flop) | no_limit (0) | bb_ante_bb1st (3) | NL Hold'em (BB ante, BB 1st) |
| 0 (Flop) | no_limit (0) | live_ante (4) | NL Hold'em (live ante) |
| 0 (Flop) | no_limit (0) | tb_ante (5) | NL Hold'em (3rd blind ante) |
| 0 (Flop) | fixed_limit (1) | std_ante (0) | FL Hold'em |
| 0 (Flop) | pot_limit (2) | std_ante (0) | PLO (Pot Limit Omaha) |
| 0 (Flop) | pot_limit (2) | button_ante (1) | PLO (button ante) |
| 1 (Draw) | no_limit (0) | std_ante (0) | NL 5-Card Draw |
| 1 (Draw) | fixed_limit (1) | std_ante (0) | FL 2-7 Triple Draw |
| 1 (Draw) | pot_limit (2) | std_ante (0) | PL Badugi |
| 2 (Stud) | fixed_limit (1) | std_ante (0) | 7-Card Stud |
| 2 (Stud) | no_limit (0) | std_ante (0) | NL Stud |
| 2 (Stud) | pot_limit (2) | std_ante (0) | PL Stud |

### 5.2 GameVariant Class (line 29-232)

```csharp
public class GameVariant
{
    public int num;          // Variant index
    public string at_name;   // Action Tracker display name
    public string tag;       // Internal tag identifier
    public int game_class;   // 0=Flop, 1=Draw, 2=Stud
    public bool available;   // Currently available for selection
}
```

`game_variant_list` (line 5380) stores all supported variants. The server sends
`GameVariantListResponse` which populates this array. The operator selects a
variant via the variant form (`_tf_variant`), which sets `_game_variant` and
triggers `write_game_info()` to update the server.

### 5.3 Cards Per Player by game_class

| game_class | _cards_per_player | _extra_cards_per_player | Notes |
|:----------:|:-----------------:|:----------------------:|-------|
| 0 (Flop) | 2 (Hold'em) | 0 | Standard |
| 0 (Flop) | 4 (Omaha) | 0 | PLO/NLO |
| 0 (Flop) | 5 (Omaha-5) | 0 | Big-O |
| 0 (Flop) | 6 (Omaha-6) | 0 | Six-Plus Omaha |
| 1 (Draw) | 5 | varies | 5-card draw, 2-7 |
| 2 (Stud) | 7 (max) | 0 | 7-Card Stud, Razz |

### 5.4 Blind Configurations

| num_blinds | Blind Setup | Seats Required |
|:----------:|-------------|----------------|
| 0 | No blinds (ante-only) | Dealer only |
| 1 | BB only | Dealer + BB |
| 2 | SB + BB | Dealer + SB + BB |
| 3 | SB + BB + Third | Dealer + SB + BB + Third |

---

## 6. Hand Lifecycle Sequence Diagram

### 6.1 Complete Flop Game Hand (NL Hold'em)

```
  Operator              ActionTracker (core.cs)           PokerGFX Server
     |                        |                                |
     |  [Start Hand btn]      |                                |
     |----------------------->|                                |
     |                        |-- SendStartHand() ------------>|
     |                        |                                |
     |                        |<-- GameInfoResponse -----------|
     |                        |    hand_in_progress=true       |
     |                        |    action_on=first_player      |
     |                        |    _board_cards=["","",""]      |
     |                        |                                |
     |                        |-- do_game_update() ----------->|  (UI refresh)
     |                        |-- do_player_update(-1) ------->|  (all players)
     |                        |                                |
     |  [Player cards via     |                                |
     |   RFID reader]         |                                |
     |                        |<-- PlayerInfoResponse ---------|
     |                        |    player[n].has_cards=true     |
     |                        |    player[n].cards="Ah Kd"     |
     |                        |                                |
     |  === PRE-FLOP BETTING ===                               |
     |                        |                                |
     |  [Fold btn]            |                                |
     |----------------------->|                                |
     |                        |-- SendPlayerFold(action_on) -->|
     |                        |                                |
     |                        |<-- GameInfoResponse -----------|
     |                        |    action_on=next_player       |
     |                        |    _num_active_players--       |
     |                        |                                |
     |  [Bet/Raise btn]       |                                |
     |----------------------->|                                |
     |                        |-- show_num_pad(tag) ---------->|  (UI: enter amt)
     |  [Enter amount]        |                                |
     |----------------------->|                                |
     |                        |-- SendPlayerBet(seat, amt) --->|
     |                        |                                |
     |  [Check/Call btn]      |                                |
     |----------------------->|                                |
     |                        |-- SendPlayerCheckCall -------->|
     |                        |    (action_on, biggest_bet)    |
     |                        |                                |
     |  === FLOP (3 board cards dealt) ===                     |
     |                        |                                |
     |                        |<-- GameInfoResponse -----------|
     |                        |    _board_cards[0]="Th 7s 2c"  |
     |                        |    action_on=first_post_flop   |
     |                        |                                |
     |  === TURN (4th board card) ===                          |
     |                        |                                |
     |                        |<-- GameInfoResponse -----------|
     |                        |    _board_cards[0]="Th 7s 2c Jd"|
     |                        |                                |
     |  === RIVER (5th board card) ===                         |
     |                        |                                |
     |                        |<-- GameInfoResponse -----------|
     |                        |    _board_cards[0]="Th 7s 2c Jd 9h"|
     |                        |    final_betting_round=true    |
     |                        |                                |
     |  === SHOWDOWN / PAYOUT ===                              |
     |                        |                                |
     |                        |<-- GameInfoResponse -----------|
     |                        |    hand_in_progress=false      |
     |                        |    next_hand_ok=true/false     |
     |                        |                                |
     |  [Payout window]       |                                |
     |  [Next Hand btn]       |                                |
     |----------------------->|                                |
     |                        |-- ManualNextHand() ----------->|
     |                        |    SendNextHand()              |
     |                        |    StopOverrideTimer()         |
     |                        |    _cards_inp_str = ""         |
     |                        |    _dead_cards_inp_str = ""    |
     |                        |    update_card_controls(-1)    |
     |                        |    do_game_update()            |
     |                        |                                |
     |                        |<-- GameInfoResponse -----------|
     |                        |    hand_count++                |
     |                        |    (return to IDLE)            |
     |                        |                                |
```

### 6.2 Network Message Flow Summary

| Phase | AT -> Server | Server -> AT |
|-------|-------------|--------------|
| Setup | `SendStartHand()` | `GameInfoResponse` (full state) |
| Blinds | `WriteGameInfo(...)` | `GameInfoResponse` (updated) |
| Deal | (auto via RFID) | `PlayerInfoResponse` (per player) |
| Bet | `SendPlayerBet(seat, amt)` | `GameInfoResponse` |
| Fold | `SendPlayerFold(seat)` | `GameInfoResponse` |
| Check/Call | `SendPlayerCheckCall(seat, amt)` | `GameInfoResponse` |
| All-In | `SendPlayerBet(seat, stack+bet)` | `GameInfoResponse` |
| Draw | `SendDraw(player, count)` | `GameInfoResponse` |
| Run It | `SendRunItTimes()` | `GameInfoResponse` |
| Clear Board | `SendRunItTimesClearBoard()` | `GameInfoResponse` |
| Chop | `SendChop()` | `GameInfoResponse` |
| Nit Game | `SendNitGameAmount(amt)` | `GameInfoResponse` |
| Next | `SendNextHand()` | `GameInfoResponse` |
| Verify | `SendVerifyReset()` | (verify state reset) |
| Save | `SendGameSaveBack()` | (game state saved) |

### 6.3 Player Class (line 247-325)

```csharp
public class Player
{
    public object name;             // Display name
    public bool has_cards;          // Player has been dealt cards
    public bool folded;             // Player has folded
    public int bet;                 // Current bet amount this round
    public bool all_in;             // Player is all-in
    public int stack;               // Current chip stack
    public int vpip;                // VPIP stat (voluntary put $ in pot)
    public int wtsd;                // WTSD stat (went to showdown)
    public int cum_win;             // Cumulative win/loss
    public int agr;                 // Aggression factor
    public int pfr;                 // PFR stat (pre-flop raise %)
    public bool sit_out;            // Player is sitting out
    public object cards;            // Hole card string (e.g., "Ah Kd")
    public object pic;              // Player photo
    public object country;          // Country flag
    public bool has_extra_cards;    // Has extra hole cards (Omaha etc.)
    public bool has_pic;            // Photo loaded
    public int dead_bet;            // Dead money posted
    public nit_game_enum nit_game;  // Nit game status
    public bool xfer_from;          // Chip transfer source
    public bool xfer_to;            // Chip transfer destination
    public object long_name;        // Full name
}
```

---

## 7. UI Form State Machine

The Action Tracker uses a `touch_form` based panel system. Key panels and their visibility rules:

| Panel | Variable | Visible When |
|-------|----------|-------------|
| Init (`_tf_init`) | `mLItJpsmuiDA3J0OiHe` | `!hand_in_progress` |
| Play (`_tf_play`) | `mLItJpsmuiDA3J0OiHe` | `hand_in_progress` |
| Video (`_tf_video`) | always | context-dependent per control |
| Cards (`_tf_cards`) | `mLItJpsmuiDA3J0OiHe` | card entry requested |
| NumPad (`_tf_num`) | `mLItJpsmuiDA3J0OiHe` | numeric entry requested |
| Alpha (`_tf_alpha`) | `mLItJpsmuiDA3J0OiHe` | text entry requested |
| Draw (`_tf_draw`) | `mLItJpsmuiDA3J0OiHe` | `hand_in_progress & drawing_player != -1` |
| Game (`_tf_game`) | `mLItJpsmuiDA3J0OiHe` | game type selection |
| Variant (`_tf_variant`) | context | variant selection |
| Confirm (`_tf_confirm`) | context | confirmation dialogs |
| Delete (`_tf_del`) | context | player/item deletion |
| Country (`_tf_country`) | context | country flag selection |
| Move (`_tf_move`) | context | player seat move |
| Xfer (`_tf_xfer`) | context | chip transfer |
| Verify (`_tf_verify`) | `_card_verify_mode` | card verification |
| Register (`_tf_reg`) | context | deck registration |

### Key UI Conditionals (from do_game_update, line 21138+)

- **"Start Hand" button**: `!hand_in_progress & enh_mode & ((is_flop_game | is_draw_game) & start_hand_flop_draw) | (is_stud_game & start_hand_stud)`
- **"Fold" button**: `hand_in_progress` (within play panel)
- **"Board Card" button**: `hand_in_progress & is_flop_game`
- **"Deal" button**: `!hand_in_progress & !is_stud_game`
- **"Bring In" label**: visible when `is_stud_game`
- **Multi-board controls**: `num_boards >= 2` or `num_boards == 3`
- **Nit game winner**: `hand_in_progress & nit_game_won_player != -1`
- **Override button**: `overrideButton` flag

---

## 8. Key Observations for EBS Replication

### 8.1 Server-Driven Architecture

PokerGFX uses a strict server-authoritative model. The Action Tracker (AT) is a
remote control that sends commands and receives state snapshots via
`GameInfoResponse`. The AT never locally modifies `hand_in_progress` -- it
only reads the value from server responses.

### 8.2 State Machine is Implicit

There is no explicit state enum for game phases (PRE_FLOP, FLOP, etc.). Instead,
the current phase is derived from:
- `hand_in_progress` (hand active)
- `num_cards(_board_cards[0])` (0/3/4/5 = pre-flop/flop/turn/river)
- `final_betting_round` (last street)
- `drawing_player` (draw phase active)
- `stud_draw_in_progress` (stud dealing)

### 8.3 Multi-Board Support

The system supports up to 3 simultaneous boards (`num_boards`), tracked
independently in `_board_cards[0]`, `_board_cards[1]`, `_board_cards[2]`.
This enables "Run It Twice/Thrice" and multi-board variants.

### 8.4 Game Classification Hierarchy

```
bet_structure (NL/FL/PL)
    x game_class (Flop/Draw/Stud)
        x ante_type (7 variants)
            x num_blinds (0-3)
                x game_variant (specific name)
```

This produces a large combinatorial space. The `do_game_update()` method
(line 21138) and `OnGameInfoReceived()` (line 17865) handle all combinations
through extensive switch/case and conditional logic.

### 8.5 RFID Integration Points

- `_reader_state` (ReaderState enum): tracks RFID reader status
- `card_rescan`: triggers re-reading when cards are unclear
- `_card_verify_mode` / `_card_verify_list`: verification workflow
- Cards arrive via `PlayerInfoResponse` and `GameInfoResponse`
- `OnReaderStatusReceived()` (line 17386) handles reader status changes

### 8.6 Critical for EBS

For EBS replication, the key insight is that the state machine needs only:

1. A `hand_in_progress` boolean
2. Board card count to derive the street
3. Player action tracking (`action_on`, `folded`, `all_in`, `bet`)
4. Server-authoritative state updates

The obfuscated control flow in the decompiled code is defensive anti-RE, not
functional complexity. The underlying state machine is straightforward.

---

## Version

**Version**: 1.0.0 | **Updated**: 2026-02-13

**Source**: `vpt_remote/core.cs` (25,643 LOC)
**Decompiler**: ILSpy / dnSpy (inferred from IL comments)
**Obfuscation**: Control-flow flattening + string encryption
