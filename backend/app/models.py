from sqlmodel import SQLModel, Field, Relationship, UniqueConstraint, JSON
from datetime import datetime
from sqlalchemy import Column 
from sqlalchemy.dialects.postgresql import JSONB
from typing import Optional, List


class User(SQLModel, table=True):
    __table_args__ = (UniqueConstraint("username"),)

    id : Optional[int] = Field(default=None, primary_key=True)
    username : str
    itineraries: List["Itinerary"] = Relationship(back_populates="creator")

class Itinerary(SQLModel, table=True):
    __table_args__ = (
        UniqueConstraint("title", "creator_id"),
        UniqueConstraint("slug", "creator_id")
    )
    id: Optional[int] = Field(default=None, primary_key=True)
    title: str = Field(default="Untitled Itinerary")
    slug: str = Field(index=True)
    visibility: str = Field(default="public")
    description: Optional[str] = Field(default="")
    creator_id: int = Field(foreign_key="user.id")
    creator: Optional[User] = Relationship(back_populates="itineraries")
    parent_id: Optional[int] = Field(default=None, foreign_key="itinerary.id")
    tags: List[str] = Field(default_factory=list, sa_column=Column(JSONB))

    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)