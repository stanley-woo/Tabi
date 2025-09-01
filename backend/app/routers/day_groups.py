from typing import List
from fastapi import APIRouter, Depends, HTTPException, Path, status, Body
from sqlmodel import Session

from ..database import get_session
from ..crud import (
    get_day_groups,
    create_day_group,
    update_day_group,
    delete_day_group,
    reorder_day_groups,
)
from ..schemas import DayGroupCreate, DayGroupRead
from ..models import DayGroup, Itinerary
from ..deps import ensure_itinerary_owner, ensure_daygroup_owner

router = APIRouter(prefix="/itineraries/{itinerary_id}/days", tags=["day-groups"])

# -------------------------
# Public (read-only)
# -------------------------
@router.get("", response_model=List[DayGroupRead], status_code=status.HTTP_200_OK)
def list_days_route(*, itinerary_id: int = Path(..., gt=0), session: Session = Depends(get_session)):
    """Fetch all day-groups for a given itinerary."""
    return get_day_groups(session, itinerary_id)

# -------------------------
# Authenticated writes
# -------------------------
@router.post("", response_model=DayGroupRead, status_code=status.HTTP_201_CREATED)
def create_day_route(*, itinerary_id: int, payload: DayGroupCreate, _owner_itin: Itinerary = Depends(ensure_itinerary_owner), session: Session = Depends(get_session)):
    """Create a new day-group."""
    return create_day_group(session, itinerary_id, payload)

@router.patch("/reorder", response_model=List[DayGroupRead], status_code=status.HTTP_200_OK)
def reorder_days_route(*, itinerary_id: int, ids: List[int] = Body(..., description="New sequence of day-group IDs"), _owner_itin: Itinerary = Depends(ensure_itinerary_owner), session: Session = Depends(get_session)):
    """
    Reorder day-groups.  
    Body: [3,1,2] → sets the new order by ID.
    """
    return reorder_day_groups(session, itinerary_id, ids)

@router.patch("/{day_id}", response_model=DayGroupRead, status_code=status.HTTP_200_OK)
def update_day_route(*, itinerary_id: int, day_id: int = Path(..., gt=0), payload: DayGroupCreate, day: DayGroup = Depends(ensure_daygroup_owner), session: Session = Depends(get_session)):
    """Update a day-group’s date/title."""
    if day.itinerary_id != itinerary_id:
        raise HTTPException(status_code=404, detail="Not Found")
    return update_day_group(session, day_id, payload)


@router.delete("/{day_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_day_route(*, itinerary_id: int, day_id: int = Path(..., gt=0), day: DayGroup = Depends(ensure_daygroup_owner), session: Session = Depends(get_session)):
    """Delete a day-group."""
    if day.itinerary_id != itinerary_id:
        raise HTTPException(status_code=404, detail="Not Found")
    delete_day_group(session, day_id)
