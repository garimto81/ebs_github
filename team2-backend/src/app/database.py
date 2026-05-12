"""Database engine & session dependency."""
from collections.abc import Generator

from passlib.hash import bcrypt
from sqlmodel import Session, SQLModel, create_engine, select

from src.app.config import settings

_engine = None


def get_engine():
    """Lazy engine creation."""
    global _engine
    if _engine is None:
        _engine = create_engine(
            settings.database_url,
            connect_args={"check_same_thread": False} if "sqlite" in settings.database_url else {},
            echo=False,
        )
    return _engine


def set_engine(engine) -> None:
    """Override engine (used in tests)."""
    global _engine
    _engine = engine


def init_db() -> None:
    """Create all tables from SQLModel metadata + seed admin + Cycle 17 defaults."""
    SQLModel.metadata.create_all(get_engine())
    _seed_admin()
    _seed_cycle17_defaults()


_DEV_SEED_ADMINS: tuple[tuple[str, str, str], ...] = (
    # (email, password, display_name) — dev/integration-tests seed targets.
    # SECURITY: AUTH_PROFILE != "dev" 환경에서는 seed 하지 않는다 (production 보호).
    ("admin@ebs.local", "admin123", "System Admin"),
    ("admin@ebs.test", "test-password-1234", "Integration Test Admin"),
)


def _seed_admin() -> None:
    """Ensure dev/integration-tests admin accounts exist (idempotent).

    seed 대상은 `_DEV_SEED_ADMINS` 표 참조. 기존 admin@ebs.local 은 backward
    compat 보존, admin@ebs.test (test-password-1234) 는 integration-tests
    scenarios (`_env.http`, `10-auth-login-profile.http`) 및 issue #236 KPI
    (`curl :18001/api/v1/auth/login 200 OK`) 정합용. `AUTH_PROFILE=live`
    환경에서는 settings.auth_profile 검사로 skip 한다 (production 보호).
    """
    from src.models.user import User

    # Production safety: 환경에 따라 seed skip.
    auth_profile = (getattr(settings, "auth_profile", "dev") or "dev").lower()
    if auth_profile == "live":
        return

    with Session(get_engine()) as db:
        for email, password, display_name in _DEV_SEED_ADMINS:
            existing = db.exec(select(User).where(User.email == email)).first()
            if existing is not None:
                continue
            db.add(User(
                email=email,
                password_hash=bcrypt.hash(password),
                display_name=display_name,
                role="admin",
                is_active=True,
            ))
        db.commit()


def _seed_cycle17_defaults() -> None:
    """Cycle 17 seed — 1 BrandPack + 1 BlindStructure (real, not mock).

    SSOT: docs/1. Product/RIVE_Standards.md Ch.7 (Brand Pack), DATA-04 (Blind Structure).

    Idempotent: 동일 name 이 이미 존재하면 skip. AUTH_PROFILE=live 환경에서는
    seed 하지 않는다 (production 보호 — admin seed 와 동일 정책).
    """
    from src.models.blind_structure import BlindStructure, BlindStructureLevel
    from src.models.brand_pack import BrandPack

    auth_profile = (getattr(settings, "auth_profile", "dev") or "dev").lower()
    if auth_profile == "live":
        return

    with Session(get_engine()) as db:
        # BrandPack: WSOP 2026 (default)
        if not db.exec(select(BrandPack).where(BrandPack.name == "wsop_2026")).first():
            db.add(BrandPack(
                name="wsop_2026",
                display_name="WSOP 2026",
                primary_color="#000000",
                secondary_color="#D4AF37",
                accent_color="#FFFFFF",
                font_family="Roboto",
                logo_primary_url="/assets/brand_packs/wsop_2026/logo_primary.svg",
                logo_secondary_url="/assets/brand_packs/wsop_2026/logo_secondary.svg",
                logo_tertiary_url="/assets/brand_packs/wsop_2026/logo_tertiary.svg",
                motif_data='{"grid":"diamond","border":"laurel"}',
                is_default=True,
            ))

        # BlindStructure: Standard 10-Level Tournament
        bs_name = "Standard 10-Level Tournament"
        if not db.exec(
            select(BlindStructure).where(BlindStructure.name == bs_name)
        ).first():
            bs = BlindStructure(name=bs_name)
            db.add(bs)
            db.flush()  # obtain bs.blind_structure_id

            # WSOP-style 10 levels (level_no, sb, bb, ante, duration_minutes)
            schedule = [
                (1, 100, 200, 0, 30),
                (2, 200, 400, 0, 30),
                (3, 300, 600, 100, 30),
                (4, 400, 800, 200, 30),
                (5, 500, 1000, 300, 30),
                (6, 600, 1200, 400, 30),
                (7, 800, 1600, 500, 40),
                (8, 1000, 2000, 600, 40),
                (9, 1500, 3000, 800, 40),
                (10, 2000, 4000, 1000, 40),
            ]
            for level_no, sb, bb, ante, dur in schedule:
                db.add(BlindStructureLevel(
                    blind_structure_id=bs.blind_structure_id,
                    level_no=level_no,
                    small_blind=sb,
                    big_blind=bb,
                    ante=ante,
                    duration_minutes=dur,
                    detail_type=0,
                ))

        db.commit()


def get_db() -> Generator[Session, None, None]:
    """FastAPI Depends — yields a DB session per request."""
    with Session(get_engine()) as session:
        yield session
