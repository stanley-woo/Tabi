from typing import List, Optional
from datetime import date, datetime, timezone, timedelta
from sqlmodel import Session, select
from slugify import slugify
from fastapi import HTTPException, status
from sqlalchemy.exc import IntegrityError

import uuid

from .models import User, Itinerary, ItineraryBlock, DayGroup, RefreshToken
from .schemas import UserCreate, DayGroupCreate, ItineraryCreate
from app.security import (hash_password, verify_password, create_access_token, REFRESH_TOKEN_EXPIRE_DAYS)

# ----------------------------------
# User CRUD
# ----------------------------------
def create_user(session: Session, data: UserCreate) -> User:
    """Create a new user."""
    payload = data.model_dump(exclude_unset=True)
    user = User(**payload)
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


def generate_unique_title(session: Session, title: str, creator_id: int) -> str:
    base = title
    name = base
    count = 1
    while session.exec(select(Itinerary).where(Itinerary.title == name, Itinerary.creator_id == creator_id)).first():
        count += 1
        name = f"{base} ({count})"
    return name

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
    """Create a new itinerary + seed Day 1 atomically."""
    try:
        with session.begin():  # single atomic txn
            # do reads INSIDE the txn to avoid "txn already begun"
            # (optional) early check for duplicate title to return 409 fast:
            if session.exec(
                select(Itinerary).where(
                    Itinerary.title == data.title,
                    Itinerary.creator_id == data.creator_id
                )
            ).first():
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="You already have an itinerary with this title."
                )

            slug = generate_unique_slug(session, data.title, data.creator_id)

            itin = Itinerary(
                title=data.title,
                description=data.description,
                visibility=data.visibility,
                creator_id=data.creator_id,
                slug=slug,
                tags=data.tags or [],
            )
            session.add(itin)
            session.flush()  # get itin.id

            # seed Day 1 without committing inside the helper
            create_day_group(
                session,
                itin.id,
                DayGroupCreate(date=date.today(), title="Day 1", order=1),
                autocommit=False,
            )
        # committed by context manager if no exception
        session.refresh(itin)
        return itin

    except IntegrityError as e:
        # transaction already rolled back by the context manager
        if "itinerary_title_creator_id_key" in str(getattr(e, "orig", e)):
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="You already have an itinerary with this title."
            )
        raise

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

def create_day_group(session: Session, itinerary_id: int, data: DayGroupCreate, *, autocommit: bool = True) -> DayGroup:
    """Create a new DayGroup, auto-assigning its `order` at the end."""
    if not session.get(Itinerary, itinerary_id):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Itinerary not found.")
    
    max_order = (
    session.exec(select(DayGroup.order).where(DayGroup.itinerary_id == itinerary_id).order_by(DayGroup.order.desc())).first() or 0)
    payload = data.model_dump(exclude={"order"})
    day = DayGroup(itinerary_id=itinerary_id, order=max_order+1, **payload)
    session.add(day)
    if autocommit:
        session.commit()
        session.refresh(day)
    else:
        session.flush()
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


# ==============================
# Auth CRUD (Users & Refresh Tokens)
# ==============================

def get_user_by_email(session: Session, email: str) -> Optional[User]:
    """Fetch user by unique (non-null) email"""
    return session.exec(select(User).where(User.email == email)).first()

def get_user_by_username(session: Session, username: str) -> Optional[User]:
    """Fetch a user by unique username"""
    return session.exec(select(User).where(User.username == username)).first()

def create_user_with_password(session: Session, *, email: str, username: str, password: str) -> User:
    """Create a user with hashed password (auth flows)"""
    user = User(username=username, email=email, hashed_password=hash_password(password), created_at=datetime.now(timezone.utc))
    session.add(user)
    session.commit()
    session.refresh(user)
    return user

def verify_user_credentials(session: Session, *, email: str, password: str) -> Optional[User]:
    """Return user if email and password is valid"""
    user = get_user_by_email(session, email)
    if not user or not user.hashed_password:
        return None
    if not verify_password(password, user.hashed_password):
        return None
    return user

def create_refresh_token(session: Session, user_id: int) -> RefreshToken:
    """Persist a new refresh token now"""
    rt = RefreshToken(user_id=user_id, token=uuid.uuid4().hex, expires_at=datetime.now(timezone.utc) + timedelta(REFRESH_TOKEN_EXPIRE_DAYS), revoked=False)
    session.add(rt)
    session.commit()
    session.refresh(rt)
    return rt

def revoke_refresh_token(session: Session, token_str: str) -> None:
    """Mark a refresh token as revoked"""
    rt = session.exec(select(RefreshToken).where(RefreshToken.token == token_str)).first()
    if rt and not rt.revoked:
        rt.revoked = True
        session.add(rt)
        session.commit()

def rotate_refresh_token(session: Session, token_str: str) -> tuple[Optional[User], Optional[RefreshToken]]:
    """Revoke an old refresh token and return a new one + user"""
    rt = session.exec(select(RefreshToken).where(RefreshToken.token == token_str)).first()
    if not rt:
        return None, None
    
    expires_at = rt.expires_at
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)
    
    now = datetime.now(timezone.utc)
    if rt.revoked or expires_at <= now:
        return None, None
    
    user = session.get(User, rt.user_id)
    if not user:
        return None, None
    
    rt.revoked = True
    new_rt = RefreshToken(user_id=user.id, token=uuid.uuid4().hex, expires_at=datetime.now(timezone.utc) + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS), revoked=False)
    session.add(rt)
    session.add(new_rt)
    session.commit()
    session.refresh(new_rt)
    return user, new_rt

def issue_token_pair_for_user(session: Session, user: User) -> tuple[str, RefreshToken]:
    """Issue JWT access + persisted refresh token"""
    if not user.email:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="User has no email; cannot issue JWT.")
    access = create_access_token(subject=user.email)
    refresh = create_refresh_token(session=session, user_id=user.id)
    return access, refresh