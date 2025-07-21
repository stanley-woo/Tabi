# backend/app/routers/itineraries.py

from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Path, Query, status
from sqlmodel import select, Session

from ..database import get_session
from ..models   import Itinerary
from ..schemas  import (
    ItineraryCreate,
    ItineraryRead,
    ItineraryUpdate,
    ItineraryFork
)
from ..crud     import generate_unique_slug, fork_itinerary

router = APIRouter(prefix="/itineraries", tags=["itineraries"])

@router.post(
    "",
    response_model=ItineraryRead,
    status_code=status.HTTP_201_CREATED
)
def create_itinerary(
    payload: ItineraryCreate,
    session: Session = Depends(get_session),
):
    slug = generate_unique_slug(
        payload.title,
        payload.creator_id,
        session
    )
    data = payload.model_dump(exclude_none=True) 
    itin = Itinerary(**data, slug=slug)
    session.add(itin)
    session.commit()
    session.refresh(itin)
    return itin

@router.get("", response_model=List[ItineraryRead])
def list_itineraries(
    tags: Optional[str] = Query(None),
    search: Optional[str] = Query(None),
    limit: int = Query(20, ge=1),
    offset: int = Query(0, ge=0),
    session: Session = Depends(get_session),
):
    stmt = select(Itinerary).where(Itinerary.visibility == "public")
    # … apply tags/search filters here …
    stmt = stmt.offset(offset).limit(limit)
    return session.exec(stmt).all()

@router.get(
    "/{it_id}",
    response_model=ItineraryRead,
    status_code=status.HTTP_200_OK
)
def read_itinerary(
    it_id: int = Path(..., gt=0),
    session: Session = Depends(get_session),
):
    itin = session.get(Itinerary, it_id)
    if not itin:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Itinerary not found")
    return itin

@router.patch(
    "/{it_id}",
    response_model=ItineraryRead,
    status_code=status.HTTP_200_OK
)
def update_itinerary(
    it_id: int,
    payload: ItineraryUpdate,
    session: Session = Depends(get_session),
):
    itin = session.get(Itinerary, it_id)
    if not itin:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Itinerary not found")
    for k, v in payload.dict(exclude_unset=True).items():
        setattr(itin, k, v)
    session.add(itin)
    session.commit()
    session.refresh(itin)
    return itin

@router.delete(
    "/{it_id}",
    status_code=status.HTTP_204_NO_CONTENT
)
def delete_itinerary(
    it_id: int,
    session: Session = Depends(get_session),
):
    itin = session.get(Itinerary, it_id)
    if not itin:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Itinerary not found")
    session.delete(itin)
    session.commit()

@router.post(
    "/{it_id}/fork",
    response_model=ItineraryRead,
    status_code=status.HTTP_201_CREATED
)
def fork_itin_route(
    it_id: int,
    payload: ItineraryFork,
    session: Session = Depends(get_session),
):
    return fork_itinerary(it_id, payload.creator_id, session)