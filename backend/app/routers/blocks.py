from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError

from ..database import get_session
from ..models import DayGroup, ItineraryBlock
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
def create_block_route(
    *,
    itinerary_id: int,
    day_id: int,
    payload: ItineraryBlockCreate,
    session: Session = Depends(get_session),
):
    # 1) Validate day belongs to itinerary
    day = session.get(DayGroup, day_id)
    if not day or day.itinerary_id != itinerary_id:
        raise HTTPException(status_code=404, detail="Day not found for this itinerary.")

    # 2) Normalize type (so 'photo' still counts as an image on the client)
    normalized_type = payload.type.lower()
    if normalized_type == "photo":
        normalized_type = "image"

    # 3) Compute next order; no explicit txn/locking since helper commits
    next_ord = session.exec(
        select(func.coalesce(func.max(ItineraryBlock.order), 0))
        .where(ItineraryBlock.day_group_id == day_id)
    ).one()
    order = int(next_ord) + 1 if payload.order is None else payload.order

    try:
        # 4) Use your existing helper (which commits + refreshes)
        return create_block(
            session=session,
            day_group_id=day_id,
            order=order,
            type=normalized_type,
            content=payload.content,
        )
    except IntegrityError:
        # If you added UNIQUE(day_group_id, order), this gives a friendly error on rare races
        session.rollback()
        raise HTTPException(status_code=409, detail="Block order conflict; please retry.")