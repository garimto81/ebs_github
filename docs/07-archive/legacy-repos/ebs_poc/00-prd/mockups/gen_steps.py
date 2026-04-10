import os

base_dir = "C:/claude/ebs_poc/docs/00-prd/mockups"

def read_base():
    with open(os.path.join(base_dir, "at-preflop-base.html"), "r", encoding="utf-8") as f:
        return f.read()

def write_step(filename, html):
    path = os.path.join(base_dir, filename)
    with open(path, "w", encoding="utf-8") as f:
        f.write(html)
    print(f"Created: {filename}")

def make_step(title, seat_states, highlight_btn, pot, amount_active=False, amount_val="", stack_overrides=None):
    html = read_base()
    html = html.replace("<title>EBS AT " + chr(8212) + " Pre-Flop Base</title>", f"<title>{title}</title>")

    # Seat states: dict of seat_id -> "active"|"folded"|"allin"|""
    for seat_id, state in seat_states.items():
        old_classes = {
            "s1": 'class="seat s1 active"',
            "s3": 'class="seat s3"',
            "s5": 'class="seat s5"',
            "s8": 'class="seat s8 active"',
        }
        if state:
            new_cls = f'class="seat {seat_id} {state}"'
        else:
            new_cls = f'class="seat {seat_id}"'
        html = html.replace(old_classes[seat_id], new_cls)

    # Highlight button
    btn_map = {
        "fold": ('class="action-btn btn-fold" data-label="FOLD"', 'class="action-btn btn-fold highlight" data-label="FOLD"'),
        "call": ('class="action-btn btn-call" data-label="CALL"', 'class="action-btn btn-call highlight" data-label="CALL"'),
        "bet": ('class="action-btn btn-bet" data-label="BET"', 'class="action-btn btn-bet highlight" data-label="BET"'),
        "raise": ('class="action-btn btn-bet" data-label="BET"', 'class="action-btn btn-bet highlight" data-label="RAISE"'),
        "allin": ('class="action-btn btn-allin" data-label="ALL IN"', 'class="action-btn btn-allin highlight" data-label="ALL IN"'),
    }
    if highlight_btn and highlight_btn in btn_map:
        old, new = btn_map[highlight_btn]
        html = html.replace(old, new)

    # Pot
    html = html.replace("POT: 1,500", f"POT: {pot}")

    # Amount row
    if amount_active:
        html = html.replace('class="amount-row inactive"', 'class="amount-row highlight-row"')
        html = html.replace('class="amount-input" type="text" placeholder="0"', f'class="amount-input has-value" type="text" value="{amount_val}"')

    # Stack overrides
    if stack_overrides:
        for name, val in stack_overrides.items():
            # Find the seat-info span near the player name
            # eric -> S1, kurt23 -> S3, james -> S5, Ken -> S8
            orig_stacks = {"eric": "30,000", "kurt23": "24,500", "james": "39,000", "Ken": "20,000"}
            if name in orig_stacks:
                html = html.replace(
                    f'<span class="seat-name">{name}</span>\n      <span class="seat-info">{orig_stacks[name]}</span>',
                    f'<span class="seat-name">{name}</span>\n      <span class="seat-info">{val}</span>'
                )

    return html

# Step 4.1: UTG(Ken) FOLD
html = make_step(
    "Step 4.1 - UTG(Ken) FOLD",
    {"s1": "", "s3": "", "s5": "", "s8": "active"},
    "fold", "1,500"
)
write_step("step-4-1-fold.html", html)

# Step 4.2a: D(eric) BET button
html = make_step(
    "Step 4.2a - D(eric) BET",
    {"s1": "active", "s3": "", "s5": "", "s8": "folded"},
    "bet", "1,500"
)
write_step("step-4-2a-bet.html", html)

# Step 4.2b: D(eric) AMOUNT 2000
html = make_step(
    "Step 4.2b - AMOUNT 2,000",
    {"s1": "active", "s3": "", "s5": "", "s8": "folded"},
    None, "1,500", amount_active=True, amount_val="2,000"
)
write_step("step-4-2b-amount.html", html)

# Step 4.3: SB(kurt23) FOLD
html = make_step(
    "Step 4.3 - SB(kurt23) FOLD",
    {"s1": "", "s3": "active", "s5": "", "s8": "folded"},
    "fold", "3,500",
    stack_overrides={"eric": "28,000"}
)
write_step("step-4-3-fold.html", html)

# Step 4.4a: BB(james) RAISE button
html = make_step(
    "Step 4.4a - BB(james) RAISE",
    {"s1": "", "s3": "folded", "s5": "active", "s8": "folded"},
    "raise", "3,500",
    stack_overrides={"eric": "28,000"}
)
write_step("step-4-4a-raise.html", html)

# Step 4.4b: BB(james) AMOUNT 6000
html = make_step(
    "Step 4.4b - AMOUNT 6,000",
    {"s1": "", "s3": "folded", "s5": "active", "s8": "folded"},
    None, "3,500", amount_active=True, amount_val="6,000",
    stack_overrides={"eric": "28,000"}
)
write_step("step-4-4b-amount.html", html)

# Step 4.5: D(eric) ALL-IN
html = make_step(
    "Step 4.5 - D(eric) ALL-IN",
    {"s1": "active", "s3": "folded", "s5": "", "s8": "folded"},
    "allin", "9,500",
    stack_overrides={"eric": "28,000", "james": "34,000"}
)
write_step("step-4-5-allin.html", html)

# Step 4.6: BB(james) CALL
html = make_step(
    "Step 4.6 - BB(james) CALL",
    {"s1": "allin", "s3": "folded", "s5": "active", "s8": "folded"},
    "call", "37,500",
    stack_overrides={"eric": "0", "james": "34,000"}
)
write_step("step-4-6-call.html", html)

print("\nAll 8 step HTML files created successfully")
