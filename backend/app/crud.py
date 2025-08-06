from typing import List
from datetime import date
from sqlmodel import Session, select
from slugify import slugify
from fastapi import HTTPException, status

from .models import User, Itinerary, ItineraryBlock, DayGroup
from .schemas import UserCreate, DayGroupCreate, ItineraryCreate

# ----------------------------------
# User CRUD
# ----------------------------------
def create_user(session: Session, data: UserCreate) -> User:
    """Create a new user."""
    user = User(username=data.username)
    session.add(user)
    session.commit()
    session.refresh(user)
    return user

def get_user(session: Session, user_id: int) -> User:
    """Fetch a single user by ID."""
    user = session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found.")
    return user

def list_users(session: Session) -> List[User]:
    """Return all users"""
    return session.exec(select(User)).all()

# ----------------------------------
# ItineraryBlock CRUD
# ----------------------------------
def create_block(session: Session, day_group_id: int, order: int, type: str, content: str) -> ItineraryBlock:
    """
    Create a new block under a specific DayGroup.
    """
    block = ItineraryBlock(day_group_id=day_group_id,order=order,type=type,content=content,)
    session.add(block)
    session.commit()
    session.refresh(block)
    return block

def get_blocks(session: Session, day_group_id: int) -> List[ItineraryBlock]:
    """
    Fetch all blocks for the given DayGroup, ordered by `order`.
    """
    stmt = select(ItineraryBlock).where(
        ItineraryBlock.day_group_id == day_group_id
    ).order_by(ItineraryBlock.order)
    return session.exec(stmt).all()

# ----------------------------------
# Itinerary Helpers
# ----------------------------------
def generate_unique_slug(session: Session, title: str, creator_id: int) -> str:
    """Helper functor to generate unique slug for each itinerary."""
    base = slugify(title)
    slug = base
    count = 1
    while session.exec(select(Itinerary).where(Itinerary.slug == slug,Itinerary.creator_id == creator_id)).first():
        slug = f"{base}-{count}"
        count += 1
    return slug

def fork_itinerary(session: Session, original_id: int, new_creator_id: int) -> Itinerary:
    """Helper functor to fork an itinerary."""
    original = session.get(Itinerary, original_id)
    if not original:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail="Original itinerary not found")

    title = f"{original.title} (forked)"
    suffix = 1
    while session.exec(
        select(Itinerary).where(Itinerary.title == title, Itinerary.creator_id == new_creator_id)).first():
        suffix += 1
        title = f"{original.title} (forked {suffix})"
    slug = generate_unique_slug(session, title, new_creator_id)

    forked = Itinerary(title=title, description=original.description, visibility=original.visibility, creator_id=new_creator_id, slug=slug, tags=list(original.tags), parent_id=original.id)
    session.add(forked)
    session.commit()
    session.refresh(forked)
    return forked

# ----------------------------------
# Itinerary CRUD (with seeded Day 1)
# ----------------------------------
def create_itinerary(session: Session, data: ItineraryCreate) -> Itinerary:
    """Create a new itinerary, generating a unique slug for the user, and automatically seed a default Day 1 group."""
    slug = generate_unique_slug(session, data.title, data.creator_id)

    itin = Itinerary(title=data.title, description=data.description, visibility=data.visibility, creator_id=data.creator_id, slug=slug, tags=data.tags or [])

    session.add(itin)
    session.commit()
    session.refresh(itin)

    create_day_group(session, itin.id, DayGroupCreate(date=date.today(), title="Day 1", order=0))

    return itin

def list_itineraries(session: Session) -> List[Itinerary]:
    """Return all itineraries."""
    return session.exec(select(Itinerary)).all()

# ----------------------------------
# DayGroup CRUD
# ----------------------------------
def get_day_groups(session: Session, itinerary_id: int) -> List[DayGroup]:
    """Get all DayGroups of the given itinerary_id."""
    stmt = select(DayGroup).where(DayGroup.itinerary_id == itinerary_id).order_by(DayGroup.order)
    return session.exec(stmt).all()

def create_day_group(session: Session, itinerary_id: int, data: DayGroupCreate) -> DayGroup:
    """Create a new DayGroup, auto-assigning its `order` at the end."""
    if not session.get(Itinerary, itinerary_id):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Itinerary not found.")
    
    max_order = session.exec(select(DayGroup.order).where(DayGroup.itinerary_id == itinerary_id).order_by(DayGroup.order.desc())).first() or 0

    payload = data.model_dump(exclude={"order"})
    day = DayGroup(itinerary_id=itinerary_id, order=max_order+1, **payload)

    session.add(day)
    session.commit()
    session.refresh(day)
    return day

def update_day_group(session: Session, day_id: int, data: DayGroupCreate) -> DayGroup:
    """Update a DayGroup’s date or title."""
    day = session.get(DayGroup, day_id)
    if not day:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Day group not found.")
    
    # only date/title metadata for now
    day.date = data.date
    day.title = data.title
    session.add(day)
    session.commit()
    session.refresh(day)
    return day

def delete_day_group(session: Session, day_id: int) -> None:
    """Delete a DayGroup."""
    day = session.get(DayGroup, day_id)
    if not day:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Day group not found.")
    session.delete(day)
    session.commit()

def reorder_day_groups(session: Session, itinerary_id: int, ordered_ids: List[int]) -> List[DayGroup]:
    """Reassign the `order` field of each DayGroup to match the given ID list."""
    days = get_day_groups(session, itinerary_id)
    existing_ids = {d.id for d in days}
    if set(ordered_ids) != existing_ids:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Provided IDs do not match existing day groups")
    for index, dg_id in enumerate(ordered_ids, start=1):
        dg = session.get(DayGroup, dg_id)
        dg.order = index
        session.add(dg)
    session.commit()
    return get_day_groups(session, itinerary_id)