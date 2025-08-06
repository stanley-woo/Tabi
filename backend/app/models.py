from datetime import date
from typing import List, Optional

from sqlalchemy import Column, ForeignKey, UniqueConstraint, JSON
from sqlmodel import Field, Relationship, SQLModel


class User(SQLModel, table=True):
    __table_args__ = (UniqueConstraint("username"),)

    id: Optional[int] = Field(default=None, primary_key=True)
    username: str
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