import datetime as dt
from datetime import date
from typing import List, Optional

from sqlalchemy import Column, ForeignKey, UniqueConstraint, JSON
from sqlmodel import Field, Relationship, SQLModel,String

def utcnow() -> dt.datetime:
    """Return a timezone-aware UTC datetime for default_factory."""
    return dt.datetime.now(dt.timezone.utc)

class User(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    username: str = Field(sa_column=Column(String, unique=True, index=True))
    display_name: str | None = None
    avatar_name: str | None = None
    header_url: str | None = None
    bio: str | None = None
    # existing relationship to itineraries
    itineraries: List["Itinerary"] = Relationship(back_populates="creator")




class DayGroup(SQLModel, table=True):
    __tablename__ = "day_group"

    id: Optional[int] = Field(default=None, primary_key=True)
    itinerary_id: int = Field(foreign_key="itinerary.id", nullable=False)
    date: date
    order: int = Field(sa_column_kwargs={"default": 0})
    title: Optional[str] = None

    # link back to parent Itinerary
    itinerary: "Itinerary" = Relationship(back_populates="days")

    blocks: List["ItineraryBlock"] = Relationship(back_populates="day_group", sa_relationship_kwargs={"lazy": "selectin", "cascade": "all, delete-orphan", "order_by": "ItineraryBlock.order"})


class Itinerary(SQLModel, table=True):
    __table_args__ = (UniqueConstraint("title", "creator_id"), UniqueConstraint("slug", "creator_id"),)

    id: Optional[int] = Field(default=None, primary_key=True)
    title: str = Field(default="Untitled Itinerary")
    slug: str = Field(index=True)
    visibility: str = Field(default="public")
    description: Optional[str] = Field(default="")
    creator_id: int = Field(foreign_key="user.id")
    creator: Optional[User] = Relationship(back_populates="itineraries")
    parent_id: Optional[int] = Field(default=None, foreign_key="itinerary.id")
    tags: List[str] = Field(default_factory=list,sa_column=Column(JSON, default_factory=list))
    days: List[DayGroup] = Relationship(back_populates="itinerary", sa_relationship_kwargs={"order_by": DayGroup.order, "cascade": "all, delete-orphan"})


class ItineraryBlock(SQLModel, table=True):
    __tablename__ = "itineraryblock"

    id: Optional[int] = Field(default=None, primary_key=True)
    day_group_id: int = Field(foreign_key="day_group.id", nullable=False)
    order: int
    type: str
    content: str

    day_group: DayGroup = Relationship(back_populates="blocks")

class Bookmark(SQLModel, table = True):
    __tablename__ = "bookmark"
    __table_args__ = (UniqueConstraint("user_id", "itinerary_id"),)

    id: int | None = Field(default=None, primary_key=True)
    user_id: int = Field(foreign_key="user.id", index=True)
    itinerary_id: int = Field(foreign_key="itinerary.id", index=True)
    created_at: dt.datetime = Field(default_factory=utcnow)

class Follow(SQLModel, table=True):
    __tablename__ = "follow"
    __table_args__ = (UniqueConstraint("follower_id", "following_id"),)

    id: int | None = Field(default=None, primary_key=True)
    follower_id: int = Field(foreign_key="user.id", index=True)
    following_id: int = Field(foreign_key="user.id", index=True)
    created_at: dt.datetime = Field(default_factory=utcnow)