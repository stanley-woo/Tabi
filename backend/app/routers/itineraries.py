from typing import List
from fastapi import APIRouter, Depends, HTTPException, Path, status
from sqlmodel import Session, select

from ..database import get_session
from ..schemas import (ItineraryCreate,ItineraryRead,ItineraryUpdate, ItineraryCreateIn)
from ..crud import (
    create_itinerary  as crud_create_itinerary,
    list_itineraries  as crud_list_itineraries,
    fork_itinerary as crud_fork_itinerary,
    update_itinerary as crud_update_itinerary,
    delete_itinerary as crud_delete_itinerary
)
from ..models import Itinerary, User
from ..deps import get_current_user, ensure_itinerary_owner

router = APIRouter(prefix="/itineraries", tags=["itineraries"])

# -------------------------
# Public (read-only)
# -------------------------
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


# -------------------------
# Authenticated writes
# -------------------------
@router.post("", response_model=ItineraryRead, status_code=status.HTTP_201_CREATED)
def create_itinerary_route(*,payload: ItineraryCreateIn,session: Session = Depends(get_session),current_user: User = Depends(get_current_user),
):
    # enforce creator from JWT
    safe_payload = ItineraryCreate(
        title=payload.title,
        description=payload.description,
        visibility=payload.visibility,
        tags=payload.tags or [],
        creator_id=current_user.id,
        parent_id=payload.parent_id,
        start_date=payload.start_date,
    )
    return crud_create_itinerary(session, safe_payload)

@router.patch("/{itinerary_id}", response_model=ItineraryRead, status_code=status.HTTP_200_OK)
def update_itinerary_route(
    *,
    itinerary_id: int,
    payload: ItineraryUpdate,
    session: Session = Depends(get_session),
    _owner_itin: Itinerary = Depends(ensure_itinerary_owner),
):
    return crud_update_itinerary(session, itinerary_id, payload)

@router.post("/{itinerary_id}/fork", response_model=ItineraryRead, status_code=status.HTTP_201_CREATED)
def fork_itinerary_route(
    *,
    itinerary_id: int,
    session: Session = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    # New fork belongs to the caller
    return crud_fork_itinerary(session, itinerary_id, current_user.id)

@router.delete("/{itinerary_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_itinerary_route(
    *,
    itinerary_id: int,
    session: Session = Depends(get_session),
    _owner_itin: Itinerary = Depends(ensure_itinerary_owner),
):
    crud_delete_itinerary(session, itinerary_id)