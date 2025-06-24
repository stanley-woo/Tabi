from pydantic import BaseModel
from typing import Optional, Literal

class ItineraryBase(BaseModel):
    title: str
    description: str
    visibility: Literal["public", "private"] = "public"

class ItineraryUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    visibility: Optional[Literal["public", "private"]] = None

class UserCreate(BaseModel):
    username: str

class ItineraryCreate(ItineraryBase):
    creator_id: int

class UserRead(BaseModel):
    id: int
    username: str

    class Config:
        orm_mode = True
    
class ItineraryRead(ItineraryBase):
    id: int
    creator_id: int
    slug: str

    class Config:
        orm_mode = True
    