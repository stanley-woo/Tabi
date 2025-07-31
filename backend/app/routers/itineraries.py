from typing import List
from fastapi import APIRouter, Depends, HTTPException, Path, status
from sqlmodel import select, Session
from sqlalchemy.orm import selectinload
from ..database import get_session
from ..models import Itinerary
from ..schemas import (
    ItineraryCreate,
    ItineraryRead,
    ItineraryUpdate,
    ItineraryFork,
)
from ..crud import create_itinerary as crud_create_itinerary, fork_itinerary

router = APIRouter(prefix="/itineraries", tags=["itineraries"])

@router.get("/", response_model=List[ItineraryRead])
def list_itineraries(
    session: Session = Depends(get_session)
):
    stmt = (
        select(Itinerary)
        .options(
            selectinload(Itinerary.blocks),
            selectinload(Itinerary.days)
        )
    )
    return session.exec(stmt).all()

@router.post("", response_model=ItineraryRead, status_code=status.HTTP_201_CREATED)
def create_itinerary(
    payload: ItineraryCreate,
    session: Session = Depends(get_session),
):
    # first create the row + Day 1 seed
    new = crud_create_itinerary(session, payload)

    # now re‐query with relationships loaded
    stmt = (
      select(Itinerary)
      .where(Itinerary.id == new.id)
      .options(
        selectinload(Itinerary.blocks),
        selectinload(Itinerary.days)
      )
    )
    return session.exec(stmt).one()


@router.get("/{itinerary_id}", response_model=ItineraryRead)
def read_itinerary(
    itinerary_id: int = Path(..., gt=0),
    session: Session = Depends(get_session),
) -> ItineraryRead:
    itin = session.get(Itinerary, itinerary_id)
    if not itin:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Itinerary not found",
        )
    return itin


@router.patch("/{itinerary_id}", response_model=ItineraryRead)
def update_itinerary(
    itinerary_id: int,
    payload: ItineraryUpdate,
    session: Session = Depends(get_session),
) -> ItineraryRead:
    itin = session.get(Itinerary, itinerary_id)
    if not itin:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Itinerary not found",
        )
    for field, value in payload.dict(exclude_unset=True).items():
        setattr(itin, field, value)
    session.add(itin)
    session.commit()
    session.refresh(itin)
    return itin


@router.delete("/{itinerary_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_itinerary(
    itinerary_id: int,
    session: Session = Depends(get_session),
):
    itin = session.get(Itinerary, itinerary_id)
    if not itin:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Itinerary not found",
        )
    session.delete(itin)
    session.commit()


@router.post(
    "/{itinerary_id}/fork",
    response_model=ItineraryRead,
    status_code=status.HTTP_201_CREATED,
)
def fork_itinerary_route(
    itinerary_id: int,
    payload: ItineraryFork,
    session: Session = Depends(get_session),
) -> ItineraryRead:
    """Fork an existing itinerary for a new creator."""
    return fork_itinerary(session, itinerary_id, payload.creator_id)