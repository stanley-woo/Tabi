from typing import List
from fastapi import APIRouter, Depends, HTTPException, Path, status
from sqlmodel import Session

from ..database import get_session
from ..models import DayGroup
from ..crud import create_block, get_blocks
from ..schemas import ItineraryBlockCreate, ItineraryBlockRead

router = APIRouter(prefix="/itineraries/{itinerary_id}/days/{day_id}/blocks", tags=["blocks"])

@router.get("", response_model=List[ItineraryBlockRead], status_code=status.HTTP_200_OK)
def list_blocks_route(*,itinerary_id: int, day_id: int, session: Session = Depends(get_session)):
    day = session.get(DayGroup, day_id)
    if not day or day.itinerary_id != itinerary_id:
        raise HTTPException(status_code=404, detail="Day not found on that itinerary")
    return get_blocks(session, day_id)

@router.post("", response_model=ItineraryBlockRead, status_code=status.HTTP_201_CREATED)
def create_block_route(*,itinerary_id: int, day_id: int, payload: ItineraryBlockCreate, session: Session = Depends(get_session)):
    return create_block(session, day_id, payload.order, payload.type, payload.content)