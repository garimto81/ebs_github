from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session, select

from bo.db.engine import get_session
from bo.db.models import Config, User
from bo.db.models.base import utcnow
from bo.middleware.auth import get_current_user
from bo.middleware.rbac import require_role
from bo.schemas.common import ApiResponse
from bo.schemas.config import ConfigRead, ConfigUpdate
from bo.services.audit_service import record_audit

router = APIRouter(prefix="/configs", tags=["Configs"])

# BO-07 §3.1-3.6 default config values (69 keys, 6 categories)
CONFIG_DEFAULTS: list[tuple[str, str, str]] = [
    ("outputs.video_size", "1080p", "outputs"), ("outputs.vertical_916", "false", "outputs"),
    ("outputs.frame_rate", "60", "outputs"), ("outputs.ndi_enabled", "false", "outputs"),
    ("outputs.rtmp_enabled", "false", "outputs"), ("outputs.srt_enabled", "false", "outputs"),
    ("outputs.direct_enabled", "false", "outputs"), ("outputs.fill_key_enabled", "false", "outputs"),
    ("outputs.alpha_channel", "false", "outputs"), ("outputs.luma_key", "false", "outputs"),
    ("outputs.invert_key", "false", "outputs"),
    ("gfx.board_position", "left", "gfx"), ("gfx.leaderboard_position", "off", "gfx"),
    ("gfx.player_layout", "horizontal", "gfx"), ("gfx.x_margin", "0.04", "gfx"),
    ("gfx.top_margin", "0.05", "gfx"), ("gfx.bot_margin", "0.04", "gfx"),
    ("gfx.reveal_players", "immediate", "gfx"), ("gfx.how_to_show_fold", "immediate", "gfx"),
    ("gfx.reveal_cards", "immediate", "gfx"), ("gfx.show_leaderboard", "false", "gfx"),
    ("gfx.indent_action_player", "true", "gfx"), ("gfx.bounce_action_player", "false", "gfx"),
    ("gfx.transition_in", "default,0.3", "gfx"), ("gfx.transition_out", "default,0.3", "gfx"),
    ("display.show_blinds", "when_changed", "display"), ("display.show_hand_number", "false", "display"),
    ("display.currency_symbol", "$", "display"), ("display.trailing_currency", "false", "display"),
    ("display.divide_by_100", "false", "display"), ("display.leaderboard_precision", "exact_amount", "display"),
    ("display.player_stack_precision", "smart_km", "display"), ("display.player_action_precision", "smart_amount", "display"),
    ("display.blinds_precision", "smart_amount", "display"), ("display.pot_precision", "smart_amount", "display"),
    ("display.chipcounts_mode", "amount", "display"), ("display.pot_mode", "amount", "display"),
    ("display.bets_mode", "amount", "display"), ("display.display_side_pot", "true", "display"),
    ("rules.move_button_bomb_pot", "true", "rules"), ("rules.limit_raises", "false", "rules"),
    ("rules.straddle_sleeper", "utg_only", "rules"), ("rules.sleeper_final_action", "bb_rule", "rules"),
    ("rules.add_seat_number", "false", "rules"), ("rules.show_as_eliminated", "true", "rules"),
    ("rules.clear_previous_action", "on_street_change", "rules"), ("rules.order_players", "seat_order", "rules"),
    ("rules.hilite_winning_hand", "immediately", "rules"),
    ("stats.show_hand_equities", "never", "stats"), ("stats.show_outs", "off", "stats"),
    ("stats.true_outs", "true", "stats"), ("stats.outs_position", "stack", "stats"),
    ("stats.allow_rabbit_hunting", "false", "stats"), ("stats.ignore_split_pots", "false", "stats"),
    ("stats.show_knockout_rank", "false", "stats"), ("stats.show_chipcount_pct", "false", "stats"),
    ("stats.show_eliminated_in_stats", "true", "stats"), ("stats.show_cumulative_winnings", "false", "stats"),
    ("stats.hide_lb_when_hand_starts", "true", "stats"), ("stats.max_bb_multiple_in_lb", "999", "stats"),
    ("stats.score_strip", "never", "stats"), ("stats.show_eliminated_in_strip", "false", "stats"),
    ("stats.order_strip_by", "seating", "stats"),
    ("prefs.table_name", "Table 1", "prefs"), ("prefs.table_password", "", "prefs"),
    ("prefs.hand_history_folder", "./exports/", "prefs"), ("prefs.export_logs_folder", "./logs/", "prefs"),
    ("prefs.api_db_export_folder", "./db_exports/", "prefs"), ("prefs.rfid_mode", "mock", "prefs"),
]


@router.post("/reset", response_model=ApiResponse[dict])
def reset_configs(
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    """Admin: Reset all configs to defaults."""
    session.exec(select(Config)).all()  # force load
    # Delete all existing
    for cfg in session.exec(select(Config)).all():
        session.delete(cfg)
    session.flush()
    # Re-insert defaults
    for key, value, category in CONFIG_DEFAULTS:
        session.add(Config(key=key, value=value, category=category))
    session.commit()
    record_audit(session, user_id=current_user.user_id, action="config.reset", entity_type="config", detail="all configs reset to defaults")
    return ApiResponse(data={"reset": True, "count": len(CONFIG_DEFAULTS)})


@router.get("/{category}/{key}", response_model=ApiResponse[ConfigRead])
def get_config_by_key(
    category: str,
    key: str,
    _: User = Depends(require_role("admin", "operator")),
    session: Session = Depends(get_session),
):
    full_key = f"{category}.{key}"
    cfg = session.exec(
        select(Config).where(Config.key == full_key, Config.category == category)
    ).first()
    if not cfg:
        raise HTTPException(404, f"Config '{full_key}' not found")
    return ApiResponse(data=cfg)


@router.put("/{category}/{key}", response_model=ApiResponse[ConfigRead])
def update_config_by_key(
    category: str,
    key: str,
    body: dict,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    full_key = f"{category}.{key}"
    cfg = session.exec(
        select(Config).where(Config.key == full_key, Config.category == category)
    ).first()
    if not cfg:
        raise HTTPException(404, f"Config '{full_key}' not found")
    cfg.value = str(body.get("value", cfg.value))
    cfg.updated_at = utcnow()
    session.add(cfg)
    session.commit()
    session.refresh(cfg)
    record_audit(session, user_id=current_user.user_id, action="config.update", entity_type="config", detail=f"key={full_key}")
    return ApiResponse(data=cfg)


@router.get("/{section}", response_model=ApiResponse[list[ConfigRead]])
def get_configs_by_section(
    section: str,
    _: User = Depends(require_role("admin", "operator")),
    session: Session = Depends(get_session),
):
    configs = session.exec(
        select(Config).where(Config.category == section)
    ).all()
    return ApiResponse(data=configs)


@router.put("/{section}", response_model=ApiResponse[list[ConfigRead]])
def update_configs(
    section: str,
    body: ConfigUpdate,
    current_user: User = Depends(require_role("admin")),
    session: Session = Depends(get_session),
):
    for key, value in body.values.items():
        existing = session.exec(
            select(Config).where(Config.key == key, Config.category == section)
        ).first()
        if existing:
            existing.value = value
            existing.updated_at = utcnow()
            session.add(existing)
        else:
            new_config = Config(key=key, value=value, category=section)
            session.add(new_config)
    session.commit()

    for key in body.values:
        record_audit(session, user_id=current_user.user_id, action="config.update", entity_type="config", detail=f"key={key}")

    configs = session.exec(
        select(Config).where(Config.category == section)
    ).all()
    return ApiResponse(data=configs)
