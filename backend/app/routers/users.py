from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from ..database import get_session
from ..schemas import UserCreate, UserRead
from ..crud import create_user, get_user, list_users
from ..models import User

router = APIRouter(prefix="/users", tags=["users"])

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