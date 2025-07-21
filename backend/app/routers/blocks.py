# backend/app/routers/blocks.py

from fastapi import APIRouter, Depends, HTTPException, Path, status
from sqlmodel import Session

from ..database import get_session
from ..schemas  import ItineraryBlockCreate, ItineraryBlockRead
from ..crud     import create_block

router = APIRouter(
    prefix="/itineraries/{it_id}/blocks",
    tags=["blocks"]
)

@router.post(
    "",
    response_model=ItineraryBlockRead,
    status_code=status.HTTP_201_CREATED
)
def post_block(
    payload: ItineraryBlockCreate,
    it_id: int = Path(..., gt=0),
    session: Session = Depends(get_session),
):
    # Ensure parent itinerary exists
    from ..models import Itinerary
    if not session.get(Itinerary, it_id):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Itinerary not found")
    return create_block(it_id, payload.order, payload.type, payload.content, session)