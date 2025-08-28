from datetime import date
from typing import List, Optional, Literal, ForwardRef
from pydantic import BaseModel, Field, EmailStr

# Forward references for nested models
ItineraryBlockRead = ForwardRef("ItineraryBlockRead")
DayGroupRead       = ForwardRef("DayGroupRead")

# -----------------------------
# 1. User Schemas
# -----------------------------
class UserCreate(BaseModel):
    """Schema for creating a new user."""
    username: str
    avatar_name: Optional[str] = None
    header_url: Optional[str] = None
    bio: Optional[str] = None


class UserRead(BaseModel):
    """Schema for returning user info."""
    id: int
    username: str
    display_name: Optional[str] = None
    avatar_name: Optional[str] = None
    header_url: Optional[str] = None
    bio: Optional[str] = None

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
    tags: List[str] = Field(default_factory=list, description="Filtering Tags")

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
    days: List["DayGroupRead"] = []

    class Config:
        orm_mode = True


# -----------------------------
# 3. ItineraryBlock Schemas
# -----------------------------
class ItineraryBlockCreate(BaseModel):
    """Schema for creating a new block within an itinerary."""
    order: int | None = None
    type: str
    content: str


class ItineraryBlockRead(BaseModel):
    """Schema for returning a block's data."""
    id: int
    day_group_id: int
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
    blocks: List[ItineraryBlockRead] = []

    class Config:
        orm_mode = True


# -----------------------------
# 5. Profile Schemas
# -----------------------------
class ProfileStats(BaseModel):
    places: int
    followers: int
    trips: int
    saved: int

class ProfileOut(BaseModel):
    id: int
    username: str
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None
    header_url: Optional[str] = None
    bio: Optional[str] = None
    stats: ProfileStats

class ProfileUpdate(BaseModel):
    display_name: Optional[str] = None
    avatar_name: Optional[str] = None
    header_url: Optional[str] = None
    bio: Optional[str] = None

class BookmarkIn(BaseModel):
    itinerary_id: int

class FollowIn(BaseModel):
    target_username: str

# -----------------------------
# 6. Auth Schemas (non-breaking additions)
# -----------------------------
class RegisterRequest(BaseModel):
    """Input for auth/register. We separate auth DTOs from existing USER schemas so nothing breaks"""
    email: EmailStr
    username: str
    password: str

class LoginRequest(BaseModel):
    """Input for /auth/login"""
    email: EmailStr
    password: str

class RefreshRequest(BaseModel):
    """Input for /auth/refresh"""
    refresh_token: str

class TokenPair(BaseModel):
    """Output for /auth/login and /auth/refresh. Includes both tokens to let the client store/rotate securely."""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


# finalize forward refs for all three interdependent schemas
ItineraryRead.model_rebuild()
DayGroupRead.model_rebuild()
ItineraryBlockRead.model_rebuild()