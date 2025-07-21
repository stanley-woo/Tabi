# backend/app/routers/users.py
from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import select, Session

from ..database import get_session
from ..models   import User
from ..schemas  import UserCreate, UserRead

router = APIRouter(prefix="/users", tags=["users"])

@router.post(
    "/",
    response_model=UserRead,
    status_code=status.HTTP_201_CREATED
)
def create_user(
    payload: UserCreate,
    session: Session = Depends(get_session),
):
    db_user = User(username=payload.username)
    session.add(db_user)
    session.commit()
    session.refresh(db_user)
    return db_user

@router.get("", response_model=list[UserRead])
def list_users(session: Session = Depends(get_session)):
    return session.exec(select(User)).all()

@router.get(
    "/{username}",
    response_model=UserRead,
    status_code=status.HTTP_200_OK
)
def get_user(username: str, session: Session = Depends(get_session)):
    user = session.exec(
        select(User).where(User.username == username)
    ).first()
    if not user:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")
    return user