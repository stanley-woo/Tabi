from typing import List
from fastapi import APIRouter, Depends, HTTPException, Path, status
from sqlmodel import Session, select

from ..database import get_session
from ..schemas import (ItineraryCreate,ItineraryRead,ItineraryUpdate,ItineraryFork)
from ..crud import (
    create_itinerary  as crud_create_itinerary,
    list_itineraries  as crud_list_itineraries,
    fork_itinerary,
)
from ..models import Itinerary

router = APIRouter(prefix="/itineraries", tags=["itineraries"])

@router.post("", response_model=ItineraryRead, status_code=status.HTTP_201_CREATED)
def create_itinerary_route(*, payload: ItineraryCreate, session: Session = Depends(get_session)):
    """Create a new itinerary (auto-seeds Day 1)."""
    return crud_create_itinerary(session, payload)

@router.get("", response_model=List[ItineraryRead], status_code=status.HTTP_200_OK)
def list_itineraries_route(*, session: Session = Depends(get_session)):
    """List all itineraries (root level)."""
    return crud_list_itineraries(session)

@router.get("/{itinerary_id}", response_model=ItineraryRead, status_code=status.HTTP_200_OK)
def get_itinerary_route(*, itinerary_id: int = Path(..., gt=0), session: Session = Depends(get_session)):
    """Fetch a single itinerary (with its days & blocks)."""
    itin = session.get(Itinerary, itinerary_id)
    if not itin:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Itinerary not found")
    return itin

@router.patch("/{itinerary_id}", response_model=ItineraryRead, status_code=status.HTTP_200_OK)
def update_itinerary_route(*, itinerary_id: int, payload: ItineraryUpdate, session: Session = Depends(get_session)):
    """Update itinerary metadata."""
    itin = session.get(Itinerary, itinerary_id)
    if not itin:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Itinerary not found")
    for field, value in payload.dict(exclude_unset=True).items():
        setattr(itin, field, value)
    session.add(itin); session.commit(); session.refresh(itin)
    return itin

@router.delete("/{itinerary_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_itinerary_route(*, itinerary_id: int, session: Session = Depends(get_session)):
    """Delete an itinerary."""
    itin = session.get(Itinerary, itinerary_id)
    if not itin:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Itinerary not found")
    session.delete(itin); session.commit()

@router.post("/{itinerary_id}/fork", response_model=ItineraryRead, status_code=status.HTTP_201_CREATED)
def fork_itinerary_route(*, itinerary_id: int, payload: ItineraryFork, session: Session = Depends(get_session)):
    """Fork an existing itinerary for a new creator."""
    return fork_itinerary(session, itinerary_id, payload.creator_id)