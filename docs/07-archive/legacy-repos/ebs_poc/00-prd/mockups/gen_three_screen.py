import os, random

base_dir = "C:/claude/ebs_poc/docs/00-prd/mockups"

# Pre-assign random cards to each player (fixed seed for reproducibility)
random.seed(42)
RANKS = ["A","2","3","4","5","6","7","8","9","T","J","Q","K"]
SUITS = [("♠","black"),("♥","red"),("♦","red"),("♣","black")]
deck = [(r, s, c) for r in RANKS for s, c in SUITS]
random.shuffle(deck)
PLAYER_CARDS = {
    "s8": (deck[0], deck[1]),  # Ken UTG
    "s1": (deck[2], deck[3]),  # eric D
    "s3": (deck[4], deck[5]),  # kurt23 SB
    "s5": (deck[6], deck[7]),  # james BB
}

def card_html(rank, suit, color):
    return f'<div class="hole-card open {color}">{rank}{suit}</div>'

def read_base():
    with open(os.path.join(base_dir, "three-screen-base.html"), "r", encoding="utf-8") as f:
        return f.read()

def write_html(name, html):
    with open(os.path.join(base_dir, name), "w", encoding="utf-8") as f:
        f.write(html)
    print(f"Created: {name}")

DEFAULTS = {"s1": "30,000", "s3": "24,500", "s5": "39,000", "s8": "20,000"}

def apply(html, step_label, pot,
          active=None,      # current action player (glow)
          stayed=[],        # acted + still in hand (visible, no glow)
          folded=[],        # folded = removed from overlay
          hidden=[],        # not yet acted = hidden
          stacks=None, btn_hl=None, amount_val=None,
          action_player="", action_stack="",
          stayed_badges=None,  # badges for stayed players {seat: (text, class)}
          active_badge=None,   # badge for active player (text, class)
          open_cards=[]):     # list of seats whose cards should be revealed

    html = html.replace(">STEP<", f">{step_label}<")
    html = html.replace("POT 1,500", f"POT {pot}")

    # Overlay player states
    for s in ["s1","s3","s5","s8"]:
        old = f'class="player" id="p-{s}"'
        if s == active:
            html = html.replace(old, f'class="player active" id="p-{s}"')
        elif s in stayed:
            # visible but no glow
            html = html.replace(old, f'class="player" id="p-{s}"')
        elif s in folded or s in hidden:
            html = html.replace(old, f'class="player" id="p-{s}" style="display:none"')

    # Badges for stayed players
    if stayed_badges:
        for s, (text, cls) in stayed_badges.items():
            badge = f'<span class="p-badge {cls}">{text}</span>'
            html = html.replace(f'id="p-{s}">', f'id="p-{s}">{badge}', 1)

    # Badge for active player
    if active_badge and active:
        text, cls = active_badge
        badge = f'<span class="p-badge {cls}">{text}</span>'
        html = html.replace(f'id="p-{active}">', f'id="p-{active}">{badge}', 1)

    # AT seat states
    for s in ["s1","s3","s5","s8"]:
        old = f'class="at-seat" id="as-{s}"'
        cls = "at-seat"
        if s == active: cls += " s-active"
        if s in folded: cls += " s-folded"
        if s in stayed:
            # check if allin
            if stayed_badges and s in stayed_badges and "allin" in stayed_badges[s][1]:
                cls += " s-allin"
        html = html.replace(old, f'class="{cls}" id="as-{s}"')

    # Stacks
    if stacks:
        for s, val in stacks.items():
            html = html.replace(f'id="stack-{s}">{DEFAULTS[s]}<', f'id="stack-{s}">{val}<')

    # AT button highlight
    btn_map = {
        "fold": 'class="at-btn at-btn-fold" id="btn-fold"',
        "call": 'class="at-btn at-btn-call" id="btn-call"',
        "bet":  'class="at-btn at-btn-bet" id="btn-bet"',
        "allin":'class="at-btn at-btn-allin" id="btn-allin"',
    }
    if btn_hl and btn_hl in btn_map:
        html = html.replace(btn_map[btn_hl], btn_map[btn_hl].replace('class="at-btn', 'class="at-btn hl'))

    # Amount + keypad
    if amount_val:
        html = html.replace('class="at-amount inactive"', 'class="at-amount hl-row"')
        html = html.replace('placeholder="0" readonly', f'value="{amount_val}" readonly class="has-val"')
        html = html.replace('class="at-keypad hidden"', 'class="at-keypad"')
        for d in set(amount_val.replace(",","")):
            if d.isdigit():
                html = html.replace(f'class="kp-key">{d}<', f'class="kp-key kp-active">{d}<')

    # Open cards for visible/stayed players
    for s in open_cards:
        if s in PLAYER_CARDS:
            c1, c2 = PLAYER_CARDS[s]
            card1_html = card_html(c1[0], c1[1], c1[2])
            card2_html = card_html(c2[0], c2[1], c2[2])
            old_cards = f'id="p-{s}">'
            # Find the hole-card divs inside this player and replace
            # We'll replace the generic hole-card divs with open ones
            # Strategy: replace first two .hole-card after this player's id
            marker = f'id="p-{s}">'
            idx = html.find(marker)
            if idx > 0:
                # Find and replace first two hole-card divs after marker
                search_start = idx
                for card_replacement in [card1_html, card2_html]:
                    pos = html.find('<div class="hole-card"></div>', search_start)
                    if pos > 0 and pos < idx + 600:  # within player div
                        html = html[:pos] + card_replacement + html[pos+len('<div class="hole-card"></div>'):]
                        search_start = pos + len(card_replacement)

    # AT info
    if action_player:
        html = html.replace(">Ken (UTG)<", f">{action_player}<")
    if action_stack:
        html = html.replace(">Stack: 20,000<", f">{action_stack}<")

    return html


# ===== STEP 4.1: UTG(Ken) FOLD =====
# Ken 등장 (첫 액션). 나머지 미등장.
html = apply(read_base(),
    step_label="Step 4.1 — UTG(Ken) FOLD", pot="1,500",
    active="s8", stayed=[], folded=[], hidden=["s1","s3","s5"],
    btn_hl="fold",
    action_player="Ken (UTG)", action_stack="Stack: 20,000",
    open_cards=["s8"])
write_html("ts-4-1-fold.html", html)

# ===== STEP 4.2a: D(eric) BET =====
# eric 등장 (active). Ken 퇴장(fold). kurt23, james 미등장.
html = apply(read_base(),
    step_label="Step 4.2a — D(eric) BET", pot="1,500",
    active="s1", stayed=[], folded=["s8"], hidden=["s3","s5"],
    btn_hl="bet",
    action_player="eric (D)", action_stack="Stack: 30,000",
    open_cards=["s1"])
write_html("ts-4-2a-bet.html", html)

# ===== STEP 4.2b: D(eric) AMOUNT 2000 =====
html = apply(read_base(),
    step_label="Step 4.2b — AMOUNT 2,000", pot="1,500",
    active="s1", stayed=[], folded=["s8"], hidden=["s3","s5"],
    amount_val="2,000",
    action_player="eric (D)", action_stack="Stack: 30,000",
    open_cards=["s1"])
write_html("ts-4-2b-amount.html", html)

# ===== STEP 4.3: SB(kurt23) FOLD =====
# kurt23 등장 (active). eric 유지 (BET, 잔류). Ken 퇴장. james 미등장.
html = apply(read_base(),
    step_label="Step 4.3 — SB(kurt23) FOLD", pot="3,500",
    active="s3", stayed=["s1"], folded=["s8"], hidden=["s5"],
    stacks={"s1":"28,000"},
    btn_hl="fold",
    action_player="kurt23 (SB)", action_stack="Stack: 24,500",
    stayed_badges={"s1": ("BET 2K","badge-bet")},
    open_cards=["s1","s3"])
html = html.replace('>BET<', '>RAISE-TO<')
write_html("ts-4-3-fold.html", html)

# ===== STEP 4.4a: BB(james) RAISE =====
# james 등장 (active). eric 유지 (잔류). Ken, kurt23 퇴장.
html = apply(read_base(),
    step_label="Step 4.4a — BB(james) RAISE", pot="3,500",
    active="s5", stayed=["s1"], folded=["s8","s3"], hidden=[],
    stacks={"s1":"28,000"},
    btn_hl="bet",
    action_player="james (BB)", action_stack="Stack: 39,000",
    stayed_badges={"s1": ("BET 2K","badge-bet")},
    open_cards=["s1","s5"])
# BET → RAISE-TO 버튼 라벨 변경 (biggest_bet > 0)
html = html.replace('>BET<', '>RAISE-TO<')
write_html("ts-4-4a-raise.html", html)

# ===== STEP 4.4b: BB(james) AMOUNT 6000 =====
html = apply(read_base(),
    step_label="Step 4.4b — AMOUNT 6,000", pot="3,500",
    active="s5", stayed=["s1"], folded=["s8","s3"], hidden=[],
    stacks={"s1":"28,000"},
    amount_val="6,000",
    action_player="james (BB)", action_stack="Stack: 39,000",
    stayed_badges={"s1": ("BET 2K","badge-bet")},
    open_cards=["s1","s5"])
html = html.replace('>BET<', '>RAISE-TO<')
write_html("ts-4-4b-amount.html", html)

# ===== STEP 4.5: D(eric) ALL-IN =====
# eric (active). james 유지 (RAISE, 잔류). Ken, kurt23 퇴장.
html = apply(read_base(),
    step_label="Step 4.5 — D(eric) ALL-IN", pot="9,500",
    active="s1", stayed=["s5"], folded=["s8","s3"], hidden=[],
    stacks={"s1":"28,000","s5":"34,000"},
    btn_hl="allin",
    action_player="eric (D) ⏱ 10s", action_stack="Stack: 28,000",
    stayed_badges={"s5": ("RAISE 6K","badge-raise")},
    open_cards=["s1","s5"])
html = html.replace('>BET<', '>RAISE-TO<')
write_html("ts-4-5-allin.html", html)

# ===== STEP 4.6: BB(james) CALL =====
# james (active). eric 유지 (ALL-IN, 잔류). Ken, kurt23 퇴장.
html = apply(read_base(),
    step_label="Step 4.6 — BB(james) CALL", pot="37,500",
    active="s5", stayed=["s1"], folded=["s8","s3"], hidden=[],
    stacks={"s1":"0","s5":"34,000"},
    btn_hl="call",
    action_player="james (BB)", action_stack="Stack: 34,000",
    stayed_badges={"s1": ("ALL-IN","badge-allin")},
    open_cards=["s1","s5"])
html = html.replace('>BET<', '>RAISE-TO<')
write_html("ts-4-6-call.html", html)

# ========== §5 FLOP / TURN / RIVER ==========
# Both eric(ALL-IN) and james visible, cards open
# Community cards appear progressively

random.shuffle(deck[8:])  # shuffle remaining cards for board
BOARD = [deck[8+i] for i in range(5)]

def board_card_html(idx):
    r, s, c = BOARD[idx]
    return f'<div class="comm-card" style="background:#fff;border:2px solid #ccc;display:flex;align-items:center;justify-content:center;font-weight:700;font-size:28px;color:{"#d32f2f" if c=="red" else "#222"}">{r}{s}</div>'

def make_board_step(html, step_label, num_cards, pot_text):
    html = html.replace(">STEP<", f">{step_label}<")
    html = html.replace("POT 1,500", f"POT {pot_text}")
    # Show eric(allin) + james(active) both
    for s in ["s1","s5"]:
        old = f'class="player" id="p-{s}"'
        if s == "s1":
            html = html.replace(old, f'class="player allin" id="p-{s}"')
        else:
            html = html.replace(old, f'class="player" id="p-{s}"')
    for s in ["s3","s8"]:
        old = f'class="player" id="p-{s}"'
        html = html.replace(old, f'class="player" id="p-{s}" style="display:none"')
    # Update stacks
    html = html.replace(f'id="stack-s1">{DEFAULTS["s1"]}<', f'id="stack-s1">0<')
    html = html.replace(f'id="stack-s5">{DEFAULTS["s5"]}<', f'id="stack-s5">10,000<')
    # Open cards for both eric(s1) and james(s5) — find cards AFTER each player's id
    for s in ["s1","s5"]:
        c1, c2 = PLAYER_CARDS[s]
        player_marker = f'id="p-{s}">'
        player_pos = html.find(player_marker)
        if player_pos < 0:
            continue
        search_from = player_pos
        for card_data in [c1, c2]:
            ch = card_html(card_data[0], card_data[1], card_data[2])
            target = '<div class="hole-card"></div>'
            pos = html.find(target, search_from)
            if pos > 0 and pos < player_pos + 800:
                html = html[:pos] + ch + html[pos+len(target):]
                search_from = pos + len(ch)
    # Badges
    html = html.replace('id="p-s1">', 'id="p-s1"><span class="p-badge badge-allin">ALL-IN</span>')
    html = html.replace('id="p-s5">', 'id="p-s5"><span class="p-badge badge-call">CALL</span>')
    # Replace community cards
    for i in range(5):
        old_comm = '<div class="comm-card"></div>'
        if i < num_cards:
            html = html.replace(old_comm, board_card_html(i), 1)
        else:
            break  # leave rest as empty
    # AT seats
    for s in ["s8","s3"]:
        html = html.replace(f'class="at-seat" id="as-{s}"', f'class="at-seat s-folded" id="as-{s}"')
    html = html.replace(f'class="at-seat" id="as-s1"', f'class="at-seat s-allin" id="as-s1"')
    # AT info
    html = html.replace(">Ken (UTG)<", ">BOARD OPEN<")
    html = html.replace(">Stack: 20,000<", ">Equity 계산 중<")
    return html

# FLOP
html = make_board_step(read_base(), "Step 5.1 — FLOP", 3, "60,500")
write_html("ts-5-1-flop.html", html)

# TURN
html = make_board_step(read_base(), "Step 5.2 — TURN", 4, "60,500")
write_html("ts-5-2-turn.html", html)

# RIVER
html = make_board_step(read_base(), "Step 5.3 — RIVER", 5, "60,500")
write_html("ts-5-3-river.html", html)

# ========== §6 SHOWDOWN ==========
html = make_board_step(read_base(), "Step 6 — SHOWDOWN", 5, "60,500")
# Add winner highlight to eric (random winner for mockup)
html = html.replace('class="player allin" id="p-s1"', 'class="player active" id="p-s1" style="border-color:#ffd740;box-shadow:0 0 20px rgba(255,215,64,0.8)"')
html = html.replace('badge-allin">ALL-IN', 'badge-allin" style="background:#ffd740;color:#333">WINNER +60,500')
write_html("ts-6-showdown.html", html)

# ========== §7 LEADERBOARD ==========
html = read_base()
html = html.replace(">STEP<", ">Step 7 — LEADERBOARD<")
html = html.replace("POT 1,500", "HAND COMPLETE")
# Hide all players, show leaderboard instead
for s in ["s1","s3","s5","s8"]:
    html = html.replace(f'class="player" id="p-{s}"', f'class="player" id="p-{s}" style="display:none"')
# Replace players-stack with leaderboard
lb_html = """
<div style="position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);background:rgba(0,0,0,0.92);border-radius:20px;padding:40px 60px;min-width:700px;border:2px solid rgba(255,215,64,0.4);box-shadow:0 0 60px rgba(0,0,0,0.6);">
  <div style="text-align:center;color:#ffd740;font-size:32px;font-weight:700;margin-bottom:24px;letter-spacing:4px;">LEADERBOARD</div>
  <div style="display:flex;gap:12px;align-items:center;padding:14px 20px;background:rgba(255,215,64,0.15);border-radius:10px;margin-bottom:8px;border:1px solid rgba(255,215,64,0.3);">
    <span style="color:#ffd740;font-weight:700;font-size:28px;width:40px;">1</span>
    <span style="color:#fff;font-size:24px;font-weight:600;flex:1;">eric</span>
    <span style="color:#4caf50;font-size:16px;font-weight:600;margin-right:8px;">+60,500</span>
    <span style="color:#ffd740;font-size:24px;font-weight:700;">60,500</span>
  </div>
  <div style="display:flex;gap:12px;align-items:center;padding:10px 20px;margin-bottom:4px;">
    <span style="color:#888;font-weight:700;font-size:24px;width:40px;">2</span>
    <span style="color:#ccc;font-size:20px;flex:1;">kurt23</span>
    <span style="color:#aaa;font-size:20px;">24,500</span>
  </div>
  <div style="display:flex;gap:12px;align-items:center;padding:10px 20px;margin-bottom:4px;">
    <span style="color:#888;font-weight:700;font-size:24px;width:40px;">3</span>
    <span style="color:#ccc;font-size:20px;flex:1;">Ken</span>
    <span style="color:#aaa;font-size:20px;">20,000</span>
  </div>
  <div style="display:flex;gap:12px;align-items:center;padding:10px 20px;">
    <span style="color:#888;font-weight:700;font-size:24px;width:40px;">4</span>
    <span style="color:#ccc;font-size:20px;flex:1;">james</span>
    <span style="color:#e57373;font-size:16px;font-weight:600;margin-right:8px;">-30,000</span>
    <span style="color:#aaa;font-size:20px;">10,000</span>
  </div>
</div>
"""
html = html.replace('<div class="players-stack">', f'<div class="players-stack" style="display:none">')
html = html.replace('</div>\n\n      <!-- Board: bottom-right -->', f'</div>{lb_html}\n\n      <!-- Board: bottom-right -->')
# Hide board area
html = html.replace('<div class="board-area">', '<div class="board-area" style="display:none">')
# AT info
html = html.replace(">Ken (UTG)<", ">LEADERBOARD<")
html = html.replace(">Stack: 20,000<", ">핸드 완료<")
write_html("ts-7-leaderboard.html", html)

# ========== §3.1 START HAND ==========
html = read_base()
html = html.replace(">STEP<", ">Step 3.1 — START HAND<")
# All players hidden (hand not started yet)
for s in ["s1","s3","s5","s8"]:
    html = html.replace(f'class="player" id="p-{s}"', f'class="player" id="p-{s}" style="display:none"')
# AT: highlight a START HAND button - replace FOLD with START HAND
html = html.replace('>FOLD<', '>START HAND<')
html = html.replace('class="at-btn at-btn-fold"', 'class="at-btn hl" style="background:#4caf50;color:#fff;flex:2"')
# Hide other buttons
html = html.replace('class="at-btn at-btn-call"', 'class="at-btn" style="display:none"')
html = html.replace('class="at-btn at-btn-bet"', 'class="at-btn" style="display:none"')
html = html.replace('class="at-btn at-btn-allin"', 'class="at-btn" style="display:none"')
html = html.replace(">Ken (UTG)<", ">핸드 대기 중<")
html = html.replace(">Stack: 20,000<", ">START HAND를 눌러 시작<")
write_html("ts-3-1-start-hand.html", html)

# ========== §7.1 END HAND ==========
html = make_board_step(read_base(), "Step 7.1 — END HAND", 5, "60,500")
html = html.replace('class="player allin" id="p-s1"', 'class="player active" id="p-s1" style="border-color:#ffd740;box-shadow:0 0 20px rgba(255,215,64,0.8)"')
html = html.replace('badge-allin">ALL-IN', 'badge-allin" style="background:#ffd740;color:#333">WINNER +60,500')
# AT: highlight END HAND button - replace FOLD with END HAND
html = html.replace('>FOLD<', '>END HAND<')
html = html.replace('class="at-btn at-btn-fold"', 'class="at-btn hl" style="background:#f44336;color:#fff;flex:2"')
html = html.replace('class="at-btn at-btn-call"', 'class="at-btn" style="display:none"')
html = html.replace('class="at-btn at-btn-bet"', 'class="at-btn" style="display:none"')
html = html.replace('class="at-btn at-btn-allin"', 'class="at-btn" style="display:none"')
html = html.replace(">BOARD OPEN<", ">Showdown 완료<")
html = html.replace(">Equity 계산 중<", ">END HAND를 눌러 종료<")
write_html("ts-7-1-end-hand.html", html)

# ========== §7.2c START HAND 재활성화 (Leaderboard + START HAND) ==========
html = read_base()
html = html.replace(">STEP<", ">Step 7.2c — START HAND 재활성화<")
html = html.replace("POT 1,500", "HAND COMPLETE")
# Hide all players
for s in ["s1","s3","s5","s8"]:
    html = html.replace(f'class="player" id="p-{s}"', f'class="player" id="p-{s}" style="display:none"')
# Leaderboard overlay (same as ts-7-leaderboard)
lb_html = """
<div style="position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);background:rgba(0,0,0,0.92);border-radius:20px;padding:40px 60px;min-width:700px;border:2px solid rgba(255,215,64,0.4);box-shadow:0 0 60px rgba(0,0,0,0.6);">
  <div style="text-align:center;color:#ffd740;font-size:32px;font-weight:700;margin-bottom:24px;letter-spacing:4px;">LEADERBOARD</div>
  <div style="display:flex;gap:12px;align-items:center;padding:14px 20px;background:rgba(255,215,64,0.15);border-radius:10px;margin-bottom:8px;border:1px solid rgba(255,215,64,0.3);">
    <span style="color:#ffd740;font-weight:700;font-size:28px;width:40px;">1</span>
    <span style="color:#fff;font-size:24px;font-weight:600;flex:1;">eric</span>
    <span style="color:#4caf50;font-size:16px;font-weight:600;margin-right:8px;">+60,500</span>
    <span style="color:#ffd740;font-size:24px;font-weight:700;">60,500</span>
  </div>
  <div style="display:flex;gap:12px;align-items:center;padding:10px 20px;margin-bottom:4px;">
    <span style="color:#888;font-weight:700;font-size:24px;width:40px;">2</span>
    <span style="color:#ccc;font-size:20px;flex:1;">kurt23</span>
    <span style="color:#aaa;font-size:20px;">24,500</span>
  </div>
  <div style="display:flex;gap:12px;align-items:center;padding:10px 20px;margin-bottom:4px;">
    <span style="color:#888;font-weight:700;font-size:24px;width:40px;">3</span>
    <span style="color:#ccc;font-size:20px;flex:1;">Ken</span>
    <span style="color:#aaa;font-size:20px;">20,000</span>
  </div>
  <div style="display:flex;gap:12px;align-items:center;padding:10px 20px;">
    <span style="color:#888;font-weight:700;font-size:24px;width:40px;">4</span>
    <span style="color:#ccc;font-size:20px;flex:1;">james</span>
    <span style="color:#e57373;font-size:16px;font-weight:600;margin-right:8px;">-30,000</span>
    <span style="color:#aaa;font-size:20px;">10,000</span>
  </div>
</div>
"""
html = html.replace('<div class="players-stack">', '<div class="players-stack" style="display:none">')
html = html.replace('</div>\n\n      <!-- Board: bottom-right -->', f'</div>{lb_html}\n\n      <!-- Board: bottom-right -->')
html = html.replace('<div class="board-area">', '<div class="board-area" style="display:none">')
# AT: START HAND button (green, highlighted)
html = html.replace('>FOLD<', '>START HAND<')
html = html.replace('class="at-btn at-btn-fold"', 'class="at-btn hl" style="background:#4caf50;color:#fff;flex:2"')
html = html.replace('class="at-btn at-btn-call"', 'class="at-btn" style="display:none"')
html = html.replace('class="at-btn at-btn-bet"', 'class="at-btn" style="display:none"')
html = html.replace('class="at-btn at-btn-allin"', 'class="at-btn" style="display:none"')
html = html.replace(">Ken (UTG)<", ">다음 핸드 대기<")
html = html.replace(">Stack: 20,000<", ">START HAND로 다음 핸드 시작<")
write_html("ts-7-2c-start-hand.html", html)

print("\nAll 16 three-screen HTML files created")



