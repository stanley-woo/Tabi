from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session

from app.models import DayGroup
from app.schemas import DayGroupCreate, DayGroupRead
from app.crud import (get_day_groups      as crud_get_days, create_day_group    as crud_create_day, delete_day_group    as crud_delete_day, reorder_day_groups  as crud_reorder_days)
from app.database import get_session

router = APIRouter(prefix="/itineraries/{itinerary_id}/days",tags=["days"],)

@router.get("/", response_model=List[DayGroupRead])
def list_day_groups(itinerary_id: int, session: Session = Depends(get_session)):
    """List all day groups for an itinerary."""
    return crud_get_days(session, itinerary_id)


@router.post("/", response_model=DayGroupRead, status_code=status.HTTP_201_CREATED)
def add_day_group(itinerary_id: int, day_in: DayGroupCreate, session: Session = Depends(get_session)):
    """Create a new day group for the itinerary."""
    return crud_create_day(session, itinerary_id, day_in)


@router.delete("/{day_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_day_group(itinerary_id: int, day_id: int, session: Session = Depends(get_session),):
    """Delete a specific day group."""
    day = session.get(DayGroup, day_id)
    if not day:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Day group not found")
    if day.itinerary_id != itinerary_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Day does not belong to this itinerary.")
    crud_delete_day(session, day_id)


@router.patch("/reorder", response_model=List[DayGroupRead])
def reorder_day_groups(itinerary_id: int, ordered_ids: List[int], session: Session = Depends(get_session)):
    """Reorder day groups by the provided list of IDs."""
    return crud_reorder_days(session, itinerary_id, ordered_ids)