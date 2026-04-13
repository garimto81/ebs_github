from sqlmodel import SQLModel, Field, UniqueConstraint

from .base import utcnow


class Deck(SQLModel, table=True):
    __tablename__ = "decks"
    deck_id: int | None = Field(default=None, primary_key=True)
    table_id: int | None = Field(default=None, foreign_key="tables.table_id")
    label: str = Field(nullable=False)
    status: str = Field(default="unregistered")  # unregistered/registering/registered/partial/mock
    registered_count: int = Field(default=0)
    card_map: str | None = None  # JSON: 52-card mapping array
    scanned_count: int = Field(default=0)
    registered_at: str | None = None
    deactivated_at: str | None = None
    registered_by: int | None = Field(default=None, foreign_key="users.user_id")
    created_at: str = Field(default_factory=utcnow)
    updated_at: str = Field(default_factory=utcnow)


class DeckCard(SQLModel, table=True):
    __tablename__ = "deck_cards"
    __table_args__ = (UniqueConstraint("deck_id", "suit", "rank"),)
    id: int | None = Field(default=None, primary_key=True)
    deck_id: int = Field(foreign_key="decks.deck_id")
    suit: int = Field(nullable=False)
    rank: int = Field(nullable=False)
    rfid_uid: str | None = None
    display: str = Field(nullable=False)
    created_at: str = Field(default_factory=utcnow)
