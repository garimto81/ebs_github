"""Seed script for EBS Back-Office database.

Usage:
    cd /c/claude/ebs_bo && python -m bo.db.seed
"""

import json

from passlib.context import CryptContext
from sqlmodel import Session, select

from bo.db.engine import create_db_and_tables, engine
from bo.db.models import (
    AuditLog,
    BlindStructure,
    BlindStructureLevel,
    Competition,
    Config,
    Event,
    EventFlight,
    OutputPreset,
    Player,
    Series,
    Skin,
    Table,
    TableSeat,
    User,
)

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def seed(session: Session) -> dict[str, int]:
    """Insert seed data. Returns dict of entity->count inserted."""
    # Check if already seeded
    existing = session.exec(select(User)).first()
    if existing:
        print("Database already seeded. Skipping.")
        return {}

    counts: dict[str, int] = {}

    # --- Users ---
    users_data = [
        ("admin@ebs.local", "admin1234!", "EBS Admin", "admin"),
        ("operator1@ebs.local", "test1234!", "Operator 1", "operator"),
        ("operator2@ebs.local", "test1234!", "Operator 2", "operator"),
        ("viewer@ebs.local", "test1234!", "Viewer", "viewer"),
    ]
    for email, pw, name, role in users_data:
        session.add(User(
            email=email,
            password_hash=pwd_context.hash(pw),
            display_name=name,
            role=role,
        ))
    session.flush()
    counts["User"] = len(users_data)

    # --- Competitions ---
    comp_wsop = Competition(name="WSOP", competition_type=0)
    comp_wpt = Competition(name="WPT", competition_type=0)
    session.add(comp_wsop)
    session.add(comp_wpt)
    session.flush()
    counts["Competition"] = 2

    # --- Series ---
    s1 = Series(
        competition_id=comp_wsop.competition_id,
        series_name="2026 WSOP",
        year=2026,
        begin_at="2026-05-27",
        end_at="2026-07-17",
        time_zone="America/Los_Angeles",
        currency="USD",
    )
    s2 = Series(
        competition_id=comp_wsop.competition_id,
        series_name="2026 WSOP Europe",
        year=2026,
        begin_at="2026-10-05",
        end_at="2026-10-20",
        time_zone="Europe/Paris",
        currency="EUR",
    )
    session.add(s1)
    session.add(s2)
    session.flush()
    counts["Series"] = 2

    # --- Events ---
    e1 = Event(
        series_id=s1.series_id,
        event_no=1,
        event_name="$10K NL Hold'em Championship",
        game_type=0,
        buy_in=10000,
        table_size=9,
    )
    e2 = Event(
        series_id=s1.series_id,
        event_no=2,
        event_name="$1,500 Pot Limit Omaha",
        game_type=2,
        buy_in=1500,
        table_size=9,
    )
    e3 = Event(
        series_id=s1.series_id,
        event_no=3,
        event_name="$50K Poker Players Championship",
        game_type=0,
        buy_in=50000,
        table_size=8,
    )
    session.add_all([e1, e2, e3])
    session.flush()
    counts["Event"] = 3

    # --- Flights ---
    f1a = EventFlight(event_id=e1.event_id, display_name="Day 1A", status="created")
    f1b = EventFlight(event_id=e1.event_id, display_name="Day 1B", status="created")
    f2 = EventFlight(event_id=e1.event_id, display_name="Day 2", status="created")
    f_omaha = EventFlight(event_id=e2.event_id, display_name="Day 1", status="created")
    session.add_all([f1a, f1b, f2, f_omaha])
    session.flush()
    counts["EventFlight"] = 4

    # --- Tables ---
    t1 = Table(
        event_flight_id=f1a.event_flight_id,
        table_no=1,
        name="Feature Table 1",
        type="feature",
        max_players=9,
        game_type=0,
    )
    t2 = Table(
        event_flight_id=f1a.event_flight_id,
        table_no=2,
        name="Feature Table 2",
        type="feature",
        max_players=9,
        game_type=0,
    )
    t3 = Table(
        event_flight_id=f1a.event_flight_id,
        table_no=3,
        name="General Table 1",
        type="general",
        max_players=9,
        game_type=0,
    )
    session.add_all([t1, t2, t3])
    session.flush()
    counts["Table"] = 3

    # --- Players ---
    players_data = [
        ("Daniel", "Negreanu", "Canada", "CA"),
        ("Phil", "Ivey", "USA", "US"),
        ("Fedor", "Holz", "Germany", "DE"),
        ("Bryn", "Kenney", "USA", "US"),
        ("Justin", "Bonomo", "USA", "US"),
        ("Erik", "Seidel", "USA", "US"),
        ("Phil", "Hellmuth", "USA", "US"),
        ("Vanessa", "Selbst", "USA", "US"),
        ("Liv", "Boeree", "UK", "GB"),
    ]
    players = []
    for first, last, nat, cc in players_data:
        p = Player(
            first_name=first,
            last_name=last,
            nationality=nat,
            country_code=cc,
            is_demo=True,
        )
        session.add(p)
        players.append(p)
    session.flush()
    counts["Player"] = len(players_data)

    # --- Seats (10 for Feature Table 1) ---
    # seat_no -> player index (None = vacant)
    seat_assignments = {
        0: 0, 1: 1, 2: None, 3: 2, 4: None,
        5: 3, 6: 4, 7: None, 8: 5, 9: None,
    }
    for seat_no, player_idx in seat_assignments.items():
        if player_idx is not None:
            p = players[player_idx]
            seat = TableSeat(
                table_id=t1.table_id,
                seat_no=seat_no,
                player_id=p.player_id,
                player_name=f"{p.first_name} {p.last_name}",
                nationality=p.nationality,
                country_code=p.country_code,
                chip_count=50000,
                status="occupied",
            )
        else:
            seat = TableSeat(
                table_id=t1.table_id,
                seat_no=seat_no,
                status="vacant",
            )
        session.add(seat)
    session.flush()
    counts["TableSeat"] = 10

    # --- BlindStructure ---
    bs = BlindStructure(name="Standard NLH Structure")
    session.add(bs)
    session.flush()
    counts["BlindStructure"] = 1

    levels_data = [
        (1, 100, 200, 0, 60),
        (2, 200, 400, 50, 60),
        (3, 300, 600, 100, 60),
        (4, 500, 1000, 100, 60),
        (5, 800, 1600, 200, 60),
        (6, 1000, 2000, 300, 60),
        (7, 1500, 3000, 400, 60),
        (8, 2000, 4000, 500, 60),
        (9, 3000, 6000, 1000, 45),
        (10, 4000, 8000, 1000, 45),
        (11, 5000, 10000, 1000, 45),
        (12, 8000, 16000, 2000, 45),
    ]
    for lvl, sb, bb, ante, dur in levels_data:
        session.add(BlindStructureLevel(
            blind_structure_id=bs.blind_structure_id,
            level_no=lvl,
            small_blind=sb,
            big_blind=bb,
            ante=ante,
            duration_minutes=dur,
        ))
    session.flush()
    counts["BlindStructureLevel"] = len(levels_data)

    # --- Configs (BO-07 §3.1-3.6, 69 keys, 6 categories) ---
    configs_data = [
        # Outputs (BO-07 §3.1) — 11 keys
        ("outputs.video_size", "1080p", "outputs"),
        ("outputs.vertical_916", "false", "outputs"),
        ("outputs.frame_rate", "60", "outputs"),
        ("outputs.ndi_enabled", "false", "outputs"),
        ("outputs.rtmp_enabled", "false", "outputs"),
        ("outputs.srt_enabled", "false", "outputs"),
        ("outputs.direct_enabled", "false", "outputs"),
        ("outputs.fill_key_enabled", "false", "outputs"),
        ("outputs.alpha_channel", "false", "outputs"),
        ("outputs.luma_key", "false", "outputs"),
        ("outputs.invert_key", "false", "outputs"),
        # GFX (BO-07 §3.2) — 14 keys
        ("gfx.board_position", "left", "gfx"),
        ("gfx.leaderboard_position", "off", "gfx"),
        ("gfx.player_layout", "horizontal", "gfx"),
        ("gfx.x_margin", "0.04", "gfx"),
        ("gfx.top_margin", "0.05", "gfx"),
        ("gfx.bot_margin", "0.04", "gfx"),
        ("gfx.reveal_players", "immediate", "gfx"),
        ("gfx.how_to_show_fold", "immediate", "gfx"),
        ("gfx.reveal_cards", "immediate", "gfx"),
        ("gfx.show_leaderboard", "false", "gfx"),
        ("gfx.indent_action_player", "true", "gfx"),
        ("gfx.bounce_action_player", "false", "gfx"),
        ("gfx.transition_in", "default,0.3", "gfx"),
        ("gfx.transition_out", "default,0.3", "gfx"),
        # Display (BO-07 §3.3) — 14 keys
        ("display.show_blinds", "when_changed", "display"),
        ("display.show_hand_number", "false", "display"),
        ("display.currency_symbol", "$", "display"),
        ("display.trailing_currency", "false", "display"),
        ("display.divide_by_100", "false", "display"),
        ("display.leaderboard_precision", "exact_amount", "display"),
        ("display.player_stack_precision", "smart_km", "display"),
        ("display.player_action_precision", "smart_amount", "display"),
        ("display.blinds_precision", "smart_amount", "display"),
        ("display.pot_precision", "smart_amount", "display"),
        ("display.chipcounts_mode", "amount", "display"),
        ("display.pot_mode", "amount", "display"),
        ("display.bets_mode", "amount", "display"),
        ("display.display_side_pot", "true", "display"),
        # Rules (BO-07 §3.4) — 9 keys
        ("rules.move_button_bomb_pot", "true", "rules"),
        ("rules.limit_raises", "false", "rules"),
        ("rules.straddle_sleeper", "utg_only", "rules"),
        ("rules.sleeper_final_action", "bb_rule", "rules"),
        ("rules.add_seat_number", "false", "rules"),
        ("rules.show_as_eliminated", "true", "rules"),
        ("rules.clear_previous_action", "on_street_change", "rules"),
        ("rules.order_players", "seat_order", "rules"),
        ("rules.hilite_winning_hand", "immediately", "rules"),
        # Stats (BO-07 §3.5) — 15 keys
        ("stats.show_hand_equities", "never", "stats"),
        ("stats.show_outs", "off", "stats"),
        ("stats.true_outs", "true", "stats"),
        ("stats.outs_position", "stack", "stats"),
        ("stats.allow_rabbit_hunting", "false", "stats"),
        ("stats.ignore_split_pots", "false", "stats"),
        ("stats.show_knockout_rank", "false", "stats"),
        ("stats.show_chipcount_pct", "false", "stats"),
        ("stats.show_eliminated_in_stats", "true", "stats"),
        ("stats.show_cumulative_winnings", "false", "stats"),
        ("stats.hide_lb_when_hand_starts", "true", "stats"),
        ("stats.max_bb_multiple_in_lb", "999", "stats"),
        ("stats.score_strip", "never", "stats"),
        ("stats.show_eliminated_in_strip", "false", "stats"),
        ("stats.order_strip_by", "seating", "stats"),
        # Preferences (BO-07 §3.6) — 6 keys
        ("prefs.table_name", "Table 1", "prefs"),
        ("prefs.table_password", "", "prefs"),
        ("prefs.hand_history_folder", "./exports/", "prefs"),
        ("prefs.export_logs_folder", "./logs/", "prefs"),
        ("prefs.api_db_export_folder", "./db_exports/", "prefs"),
        ("prefs.rfid_mode", "mock", "prefs"),
    ]
    for key, value, category in configs_data:
        session.add(Config(key=key, value=value, category=category))
    session.flush()
    counts["Config"] = len(configs_data)

    # --- Skins ---
    skins_data = [
        ("Default", True, {"primary": "#1a1a2e", "accent": "#e94560"}),
        ("WSOP Classic", False, {"primary": "#0d1b2a", "accent": "#ffd700"}),
        ("Modern Dark", False, {"primary": "#121212", "accent": "#bb86fc"}),
    ]
    for name, is_default, theme in skins_data:
        session.add(Skin(
            name=name,
            is_default=is_default,
            theme_data=json.dumps(theme),
        ))
    session.flush()
    counts["Skin"] = len(skins_data)

    # --- OutputPresets ---
    presets_data = [
        ("NDI 1080p60", "ndi", 1920, 1080, 60, True, False),
        ("NDI 720p30", "ndi", 1280, 720, 30, False, False),
        ("SDI 1080i", "sdi", 1920, 1080, 30, False, False),
        ("Chroma 1080p", "ndi", 1920, 1080, 60, False, True),
    ]
    for name, otype, w, h, fps, is_def, chroma in presets_data:
        session.add(OutputPreset(
            name=name,
            output_type=otype,
            width=w,
            height=h,
            framerate=fps,
            is_default=is_def,
            chroma_key=chroma,
        ))
    session.flush()
    counts["OutputPreset"] = len(presets_data)

    session.commit()
    return counts


def main():
    create_db_and_tables()
    with Session(engine) as session:
        counts = seed(session)
        if counts:
            print("Seed data inserted:")
            for entity, count in counts.items():
                print(f"  {entity}: {count}")
            total = sum(counts.values())
            print(f"  Total: {total} records")
        else:
            print("No data inserted (already seeded).")


if __name__ == "__main__":
    main()
