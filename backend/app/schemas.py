from datetime import date
from typing import List, Optional, Literal
from pydantic import BaseModel, Field

# -----------------------------
# 1. User Schemas
# -----------------------------
class UserCreate(BaseModel):
    """Schema for creating a new user."""
    username: str


class UserRead(BaseModel):
    """Schema for returning user info."""
    id: int
    username: str

    class Config:
        orm_mode = True


# -----------------------------
# 2. Itinerary Schemas
# -----------------------------
class ItineraryBase(BaseModel):
    """Common fields for itineraries."""
    title: str = Field(..., description="Name of the itinerary")
    description: str = Field(..., description="Detailed description or summary")
    visibility: Literal["public", "private"] = Field("public", description="Access level of the itinerary")
    tags: List[str] = Field(default_factory=list, description="List of tags for filtering")


class ItineraryCreate(ItineraryBase):
    """Fields required to create an itinerary."""
    creator_id: int = Field(..., description="User ID of the creator")
    parent_id: Optional[int] = Field(None, description="Optional parent itinerary for forks")


class ItineraryUpdate(BaseModel):
    """Fields allowed when updating an itinerary."""
    title: Optional[str] = None
    description: Optional[str] = None
    visibility: Optional[Literal["public", "private"]]
    tags: Optional[List[str]]


class ItineraryFork(BaseModel):
    """Schema for forking an itinerary."""
    creator_id: int = Field(..., description="New owner of the forked itinerary")


class ItineraryDelete(BaseModel):
    """Schema for authorizing deletion."""
    creator_id: int = Field(..., description="User requesting deletion")


class ItineraryRead(ItineraryBase):
    """Schema for returning full itinerary details, including blocks & days."""
    id: int
    creator_id: int
    slug: str
    parent_id: Optional[int] = None
    blocks: List["ItineraryBlockRead"] = []
    days: List["DayGroupRead"] = []

    class Config:
        orm_mode = True


# -----------------------------
# 3. ItineraryBlock Schemas
# -----------------------------
class ItineraryBlockCreate(BaseModel):
    """Schema for creating a new block within an itinerary."""
    order: int
    type: str
    content: str


class ItineraryBlockRead(BaseModel):
    """Schema for returning a block's data."""
    id: int
    order: int
    type: str
    content: str

    class Config:
        orm_mode = True


# -----------------------------
# 4. DayGroup Schemas
# -----------------------------
class DayGroupBase(BaseModel):
    """Common fields for a day grouping."""
    date: date
    order: int = Field(..., description="Sequence order for the day group")
    title: Optional[str] = Field(None, description="Optional custom title for the day")


class DayGroupCreate(DayGroupBase):
    """Schema for creating a new day group."""
    pass


class DayGroupRead(DayGroupBase):
    """Schema for returning day group details."""
    id: int
    itinerary_id: int

    class Config:
        orm_mode = True