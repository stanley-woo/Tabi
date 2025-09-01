from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlmodel import Session, select
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError

from ..utils.urls import to_avatar_url
from ..database import get_session
from ..crud import create_user, get_user, list_users
from ..models import User, Itinerary, Bookmark, Follow
from ..schemas import (
    ProfileOut, ProfileStats, BookmarkIn, FollowIn,
    ItineraryRead, UserCreate, UserRead, ProfileUpdate
)
from ..deps import get_current_user, is_admin

router = APIRouter(prefix="/users", tags=["users"])

# ---------- BASIC USER CRUD ----------
@router.post("", response_model=UserRead, status_code=status.HTTP_201_CREATED)
def create_user_route(*, data: UserCreate, session: Session = Depends(get_session)):
    """Create a new user."""
    return create_user(session, data)

@router.get("", response_model=List[UserRead], status_code=status.HTTP_200_OK)
def list_users_route(*, session: Session = Depends(get_session)):
    """List all users."""
    return list_users(session)

@router.get("/{user_id}", response_model=UserRead, status_code=status.HTTP_200_OK)
def get_user_route(*, user_id: int, session: Session = Depends(get_session)):
    """Fetch a single user by ID."""
    return get_user(session, user_id)

# ---------- PROFILE (HEADER) ----------
@router.put("/{username}/profile", response_model=ProfileOut)
def update_profile(username: str, payload: ProfileUpdate, session: Session = Depends(get_session)):
    """Update display_name, avatar_name, header_url, bio (nullable fields)."""
    user = session.exec(select(User).where(User.username == username)).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")

    # Apply only provided fields to avoid clobbering with nulls
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(user, k, v)

    session.add(user)
    session.commit()
    session.refresh(user)
    # Reuse the getter to ensure consistent response shape
    return get_profile(username, session)

@router.get("/{username}/profile", response_model=ProfileOut, status_code=status.HTTP_200_OK)
def get_profile(username: str, session: Session = Depends(get_session)):
    """Header payload for the profile screen (avatar, bio, stats)."""
    # 1) Look up by handle
    user: Optional[User] = session.exec(
        select(User).where(User.username == username)
    ).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")

    # 2) Count created trips
    trips = int(session.exec(
        select(func.count(Itinerary.id)).where(Itinerary.creator_id == user.id)
    ).one() or 0)

    # 3) Count saved/bookmarks
    saved = int(session.exec(
        select(func.count(Bookmark.id)).where(Bookmark.user_id == user.id)
    ).one() or 0)

    # 4) Count followers (how many users follow this user)
    followers = int(session.exec(
        select(func.count(Follow.id)).where(Follow.following_id == user.id)
    ).one() or 0)

    # 5) Places — placeholder until you decide the model
    places = 0

    return ProfileOut(
        id=user.id,
        username=user.username,
        display_name=user.display_name,
        avatar_url=to_avatar_url(user.avatar_name),  # map name -> URL
        header_url=user.header_url,
        bio=user.bio,
        stats=ProfileStats(
            places=places, followers=followers, trips=trips, saved=saved
        ),
    )

# ---------- LISTS FOR TABS ----------
@router.get("/{username}/itineraries", response_model=List[ItineraryRead], status_code=status.HTTP_200_OK)
def list_created_itins(
    username: str,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    session: Session = Depends(get_session),
):
    """Itineraries created by this user (Created tab)."""
    user = session.exec(select(User).where(User.username == username)).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")

    q = (
        select(Itinerary)
        .where(Itinerary.creator_id == user.id)
        .offset(offset)
        .limit(limit)
    )
    return session.exec(q).all()

@router.get("/{username}/saved", response_model=List[ItineraryRead], status_code=status.HTTP_200_OK)
def list_saved_itins(
    username: str,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    session: Session = Depends(get_session),
):
    """Itineraries this user saved (Saved tab)."""
    user = session.exec(select(User).where(User.username == username)).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")

    q = (
        select(Itinerary)
        .join(Bookmark, Bookmark.itinerary_id == Itinerary.id)
        .where(Bookmark.user_id == user.id)
        .offset(offset)
        .limit(limit)
    )
    return session.exec(q).all()

# ---------- BOOKMARK (SAVE/UNSAVE) ----------
@router.post("/{username}/bookmarks", status_code=status.HTTP_204_NO_CONTENT)
def add_bookmark(username: str, payload: BookmarkIn, session: Session = Depends(get_session)):
    """
    Save a trip. Idempotent: duplicate inserts are ignored via UniqueConstraint.
    """
    user = session.exec(select(User).where(User.username == username)).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")

    session.add(Bookmark(user_id=user.id, itinerary_id=payload.itinerary_id))
    try:
        session.commit()
    except IntegrityError:
        session.rollback()  # already saved; treat as success
    return

@router.delete("/{username}/bookmarks/{itinerary_id}", status_code=status.HTTP_204_NO_CONTENT)
def remove_bookmark(username: str, itinerary_id: int, session: Session = Depends(get_session)):
    """Unsave a trip. Deleting a missing row is treated as success (idempotent)."""
    user = session.exec(select(User).where(User.username == username)).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")

    row = session.exec(
        select(Bookmark).where(
            Bookmark.user_id == user.id, Bookmark.itinerary_id == itinerary_id
        )
    ).first()
    if row:
        session.delete(row)
        session.commit()
    return

# ---------- FOLLOW / UNFOLLOW ----------
@router.post("/{username}/follow", status_code=status.HTTP_204_NO_CONTENT)
def follow_user(username: str, payload: FollowIn, session: Session = Depends(get_session)):
    """
    Current user follows target user. Idempotent via UniqueConstraint.
    """
    follower = session.exec(select(User).where(User.username == username)).first()
    target = session.exec(select(User).where(User.username == payload.target_username)).first()
    if not follower or not target:
        raise HTTPException(status_code=404, detail="User(s) not found.")
    if follower.id == target.id:
        raise HTTPException(status_code=400, detail="Cannot follow yourself.")

    session.add(Follow(follower_id=follower.id, following_id=target.id))
    try:
        session.commit()
    except IntegrityError:
        session.rollback()  # already following; treat as success
    return

@router.delete("/{username}/follow/{target_username}", status_code=status.HTTP_204_NO_CONTENT)
def unfollow_user(username: str, target_username: str, session: Session = Depends(get_session)):
    """Unfollow. Deleting a missing row is treated as success (idempotent)."""
    follower = session.exec(select(User).where(User.username == username)).first()
    target = session.exec(select(User).where(User.username == target_username)).first()
    if not follower or not target:
        raise HTTPException(status_code=404, detail="User(s) not found.")

    row = session.exec(
        select(Follow).where(
            Follow.follower_id == follower.id,
            Follow.following_id == target.id,
        )
    ).first()
    if row:
        session.delete(row)
        session.commit()
    return

# ---------- SOCIAL LISTS ----------
@router.get("/{username}/followers", response_model=List[ProfileOut], status_code=status.HTTP_200_OK)
def list_followers(username: str, session: Session = Depends(get_session)):
    """People who follow {username}."""
    user = session.exec(select(User).where(User.username == username)).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")

    follower_rows = session.exec(
        select(User)
        .join(Follow, Follow.follower_id == User.id)
        .where(Follow.following_id == user.id)
    ).all()

    return [
        ProfileOut(
            id = u.id,
            username=u.username,
            display_name=u.display_name,
            avatar_url=to_avatar_url(u.avatar_name),
            header_url=u.header_url,
            bio=u.bio,
            stats=ProfileStats(places=0, followers=0, trips=0, saved=0),
        )
        for u in follower_rows
    ]

@router.get("/{username}/following", response_model=List[ProfileOut], status_code=status.HTTP_200_OK)
def list_following(username: str, session: Session = Depends(get_session)):
    """People {username} follows."""
    user = session.exec(select(User).where(User.username == username)).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found.")

    following_rows = session.exec(
        select(User)
        .join(Follow, Follow.following_id == User.id)
        .where(Follow.follower_id == user.id)
    ).all()

    return [
        ProfileOut(
            id=u.id,
            username=u.username,
            display_name=u.display_name,
            avatar_url=to_avatar_url(u.avatar_name),
            header_url=u.header_url,
            bio=u.bio,
            stats=ProfileStats(places=0, followers=0, trips=0, saved=0),
        )
        for u in following_rows
    ]