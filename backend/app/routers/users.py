from typing import List
from fastapi import APIRouter, Depends, HTTPException, Path, status
from sqlmodel import select, Session

from ..database import get_session
from ..models import User
from ..schemas import UserCreate, UserRead

router = APIRouter(prefix="/users", tags=["users"])

@router.post("", response_model=UserRead, status_code=status.HTTP_201_CREATED)
def create_user(payload: UserCreate, session: Session = Depends(get_session)):
    """Register a new user."""
    user = User(username=payload.username)
    session.add(user)
    session.commit()
    session.refresh(user)
    return user

@router.get("", response_model=List[UserRead])
def list_users(session: Session = Depends(get_session)):
    """Return all users."""
    return session.exec(select(User)).all()

@router.get("/{username}", response_model=UserRead)
def get_user(username: str = Path(...), session: Session = Depends(get_session)):
    """Fetch a user by username."""
    user = session.exec(select(User).where(User.username == username)).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return user