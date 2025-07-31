from fastapi import APIRouter, Depends, HTTPException, Path, status
from sqlmodel import Session

from ..database import get_session
from ..models import Itinerary
from ..schemas import ItineraryBlockCreate, ItineraryBlockRead
from ..crud import create_block

router = APIRouter(prefix="/itineraries/{itinerary_id}/blocks", tags=["blocks"])

@router.post("", response_model=ItineraryBlockRead, status_code=status.HTTP_201_CREATED,)
def post_block(payload: ItineraryBlockCreate, itinerary_id: int = Path(..., gt=0), session: Session = Depends(get_session)):
    """Create a new block under an itinerary."""
    # 1) Verify itinerary exists
    if not session.get(Itinerary, itinerary_id):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Itinerary not found")
    # 2) Delegate to CRUD (session-first signature)
    return create_block(session, itinerary_id, payload.order, payload.type, payload.content)