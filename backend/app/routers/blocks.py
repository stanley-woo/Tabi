from typing import List
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlmodel import Session, select
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError
import uuid
import os
from google.cloud import storage

from ..database import get_session
from ..models import DayGroup, ItineraryBlock
from ..crud import create_block, get_blocks, delete_block
from ..schemas import ItineraryBlockCreate, ItineraryBlockRead
from ..deps import ensure_daygroup_owner, ensure_block_owner

router = APIRouter(prefix="/itineraries/{itinerary_id}/days/{day_id}/blocks", tags=["blocks"])

# Google Cloud Storage configuration
BUCKET_NAME = "tabi-cloud-storage"
CLOUD_STORAGE_BASE_URL = "https://storage.googleapis.com"

def get_storage_client():
    """Get Google Cloud Storage client using default credentials."""
    return storage.Client()

@router.get("", response_model=List[ItineraryBlockRead], status_code=status.HTTP_200_OK)
def list_blocks_route(*,itinerary_id: int, day_id: int, session: Session = Depends(get_session)):
    day = session.get(DayGroup, day_id)
    if not day or day.itinerary_id != itinerary_id:
        raise HTTPException(status_code=404, detail="Day not found on that itinerary")
    return get_blocks(session, day_id)

@router.post("", response_model=ItineraryBlockRead, status_code=status.HTTP_201_CREATED)
def create_block_route(*,itinerary_id: int,day_id: int,payload: ItineraryBlockCreate, day: DayGroup = Depends(ensure_daygroup_owner), session: Session = Depends(get_session)):
    if day.itinerary_id != itinerary_id:
        raise HTTPException(status_code=404, detail="Day not found on that itinerary")

    # Normalize type (so 'photo' still counts as an image on the client)
    normalized_type = payload.type.lower()
    if normalized_type == "photo":
        normalized_type = "image"

    # Compute next order; no explicit txn/locking since helper commits
    next_ord = session.exec(select(func.coalesce(func.max(ItineraryBlock.order), 0)).where(ItineraryBlock.day_group_id == day_id)).one() 
    order = (next_ord + 1) if payload.order is None else payload.order

    # All images should already be Cloud Storage URLs at this point
    content = payload.content

    try:
        # Use your existing helper (which commits + refreshes)
        return create_block(session=session,day_group_id=day_id,order=order,type=normalized_type,content=content)
    except IntegrityError:
        # If you added UNIQUE(day_group_id, order), this gives a friendly error on rare races
        session.rollback()
        raise HTTPException(status_code=409, detail="Block order conflict; please retry.")
    
@router.delete("/{block_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_block_route(*, itinerary_id: int, day_id: int, block_id: int, block: ItineraryBlock = Depends(ensure_block_owner), session: Session = Depends(get_session)):
    day = session.get(DayGroup, block.day_group_id)
    if not day or day.id != day_id or day.itinerary_id != itinerary_id:
        raise HTTPException(status_code=404, detail="Not Found")
    
    delete_block(session, block)
    return