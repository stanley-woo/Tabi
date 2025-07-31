"""
CRUD operations for Itinerary, ItineraryBlock, and DayGroup entities.
All functions assume a `Session` passed as an argument for consistency.
"""
from typing import List
from datetime import date
from sqlmodel import Session, select
from slugify import slugify
from fastapi import HTTPException, status

from .models import Itinerary, ItineraryBlock, DayGroup
from .schemas import DayGroupCreate, ItineraryCreate

# ----------------------------------
# ItineraryBlock CRUD
# ----------------------------------
def create_block(
    session: Session,
    itinerary_id: int,
    order: int,
    type: str,
    content: str,
) -> ItineraryBlock:
    block = ItineraryBlock(
        itinerary_id=itinerary_id,
        order=order,
        type=type,
        content=content,
    )
    session.add(block)
    session.commit()
    session.refresh(block)
    return block

def get_blocks(
    session: Session,
    itinerary_id: int,
) -> List[ItineraryBlock]:
    stmt = (
        select(ItineraryBlock)
        .where(ItineraryBlock.itinerary_id == itinerary_id)
        .order_by(ItineraryBlock.order)
    )
    return session.exec(stmt).all()

# ----------------------------------
# Itinerary Helpers
# ----------------------------------
def generate_unique_slug(
    session: Session,
    title: str,
    creator_id: int,
) -> str:
    base = slugify(title)
    slug = base
    count = 1
    while session.exec(
        select(Itinerary).where(
            Itinerary.slug == slug,
            Itinerary.creator_id == creator_id,
        )
    ).first():
        slug = f"{base}-{count}"
        count += 1
    return slug

def fork_itinerary(
    session: Session,
    original_id: int,
    new_creator_id: int,
) -> Itinerary:
    original = session.get(Itinerary, original_id)
    if not original:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Original itinerary not found",
        )

    # build new title / slug
    title = f"{original.title} (forked)"
    suffix = 1
    while session.exec(
        select(Itinerary).where(
            Itinerary.title == title,
            Itinerary.creator_id == new_creator_id,
        )
    ).first():
        suffix += 1
        title = f"{original.title} (forked {suffix})"
    slug = generate_unique_slug(session, title, new_creator_id)

    forked = Itinerary(
        title=title,
        description=original.description,
        visibility=original.visibility,
        creator_id=new_creator_id,
        slug=slug,
        tags=list(original.tags),
        parent_id=original.id,
    )
    session.add(forked)
    session.commit()
    session.refresh(forked)
    return forked

# ----------------------------------
# Itinerary CRUD (with seeded Day 1)
# ----------------------------------
def create_itinerary(
    session: Session,
    data: ItineraryCreate,
) -> Itinerary:
    """
    Create a new itinerary, generating a unique slug for the user,
    and automatically seed a default Day 1 group.
    """
    slug = generate_unique_slug(session, data.title, data.creator_id)

    # create the itinerary row
    itin = Itinerary(
        title=data.title,
        description=data.description,
        visibility=data.visibility,
        creator_id=data.creator_id,
        slug=slug,
        tags=data.tags or [],
    )
    session.add(itin)
    session.commit()
    session.refresh(itin)

    # seed Day 1
    create_day_group(
        session,
        itin.id,
        DayGroupCreate(
            date=date.today(),
            title="Day 1",
            order=0,  # ignored; helper auto-assigns next order
        ),
    )

    return itin

# ----------------------------------
# DayGroup CRUD
# ----------------------------------
def get_day_groups(
    session: Session,
    itinerary_id: int,
) -> List[DayGroup]:
    stmt = (
        select(DayGroup)
        .where(DayGroup.itinerary_id == itinerary_id)
        .order_by(DayGroup.order)
    )
    return session.exec(stmt).all()

def create_day_group(
    session: Session,
    itinerary_id: int,
    data: DayGroupCreate,
) -> DayGroup:
    if not session.get(Itinerary, itinerary_id):
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Itinerary not found",
        )
    max_order = session.exec(
        select(DayGroup.order)
        .where(DayGroup.itinerary_id == itinerary_id)
        .order_by(DayGroup.order.desc())
    ).first() or 0

    payload = data.model_dump(exclude={"order"})
    day = DayGroup(
        itinerary_id=itinerary_id,
        order=max_order + 1,
        **payload,
    )
    session.add(day)
    session.commit()
    session.refresh(day)
    return day

def delete_day_group(session: Session, day_id: int) -> None:
    day = session.get(DayGroup, day_id)
    if not day:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Day group not found",
        )
    session.delete(day)
    session.commit()

def reorder_day_groups(
    session: Session,
    itinerary_id: int,
    ordered_ids: List[int],
) -> List[DayGroup]:
    days = get_day_groups(session, itinerary_id)
    existing_ids = {d.id for d in days}
    if set(ordered_ids) != existing_ids:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Provided IDs do not match existing day groups",
        )
    for index, dg_id in enumerate(ordered_ids, start=1):
        dg = session.get(DayGroup, dg_id)
        dg.order = index
        session.add(dg)
    session.commit()
    return get_day_groups(session, itinerary_id)