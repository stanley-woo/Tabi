from pydantic import BaseModel
from typing import Optional, Literal, List

# User Models
class UserCreate(BaseModel):
    username: str

class UserRead(BaseModel):
    id: int
    username: str

    class Config:
        orm_mode = True

# Itinerary Models
class ItineraryBase(BaseModel):
    title: str
    description: str
    visibility: Literal["public", "private"] = "public"
    tags: Optional[list[str]] = []

class ItineraryUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    visibility: Optional[Literal["public", "private"]] = None
    tags: Optional[list[str]] = None

class ItineraryCreate(ItineraryBase):
    creator_id: int
    parent_id: Optional[int] = None

class ItineraryFork(BaseModel):
    creator_id : int

class ItineraryDelete(BaseModel):
    creator_id : int


# ItineraryBlocks Model
class ItineraryBlockRead(BaseModel):
    id: int
    order: int
    type: str
    content: str

    class Config:
        orm_mode = True

class ItineraryBlockCreate(BaseModel):
    order: int
    type: str
    content: str

class ItineraryRead(ItineraryBase):
    id: int
    creator_id: int
    slug: str
    parent_id: Optional[int] = None
    blocks: List[ItineraryBlockRead] = []

    class Config:
        orm_mode = True
