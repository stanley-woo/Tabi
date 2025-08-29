from datetime import datetime, timezone, timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session

from app.database import get_session
from app.deps import get_current_user
from app.models import User
from app.schemas import RegisterRequest, LoginRequest, RefreshRequest, TokenPair, UserRead
from app import crud
from app.security import create_access_token


router = APIRouter(prefix="/auth", tags=["auth"])

@router.post("/register", response_model=UserRead, status_code=201)
def register(data: RegisterRequest, session: Session = Depends(get_session)):
    """Create a new user account for authentication."""
    if crud.get_user_by_username(session=session, username=data.username):
        raise HTTPException(status_code=400, detail="Username already taken.")
    if crud.get_user_by_email(session=session, email=str(data.email)):
        raise HTTPException(status_code=400, detail="Email already taken.")
    
    user = crud.create_user_with_password(session, email=str(data.email), username=data.username, password=data.password)
    return user

@router.post("/login", response_model=TokenPair, status_code=200)
def login(data: LoginRequest, session: Session = Depends(get_session)):
    """Log in with email + password"""
    user = crud.verify_user_credentials(session, email=data.email, password=data.password)
    if not user:
        raise HTTPException(status_code=400, detail="Invalid email or password.")
    
    access, refresh = crud.issue_token_pair_for_user(session, user)
    return TokenPair(access_token=access, refresh_token=refresh.token)

@router.post("/refresh", response_model=TokenPair, status_code=200)
def refresh_tokens(data: RefreshRequest, session: Session = Depends(get_session)):
    """Exchange a valid refresh token for a new token pair (rotation)"""
    user, new_refresh = crud.rotate_refresh_token(session, data.refresh_token)
    if not user or not new_refresh:
        # Covers: token not found, revoked, or expired
        raise HTTPException(status_code=401, detail="Invalid refresh token")
    
    # New short-lived access token
    if not user.email:
        raise HTTPException(status_code=400, detail="User has no email; cannot issue access token.")
    access = create_access_token(subject=user.email)
    return TokenPair(access_token=access, refresh_token=new_refresh.token)


@router.post("/logout", status_code=204)
def logout(data: RefreshRequest, session: Session = Depends(get_session)):
    """Log out the current session by revoking the provided refresh token"""
    crud.revoke_refresh_token(session, data.refresh_token)
    return

@router.get("/me", response_model=UserRead)
def me(current_user: User = Depends(get_current_user)):
    """
    Return the current authenticated user.
    - Requires Authorization: Bearer <access JWT>
    - get_current_user() decodes JWT + loads the user from DB
    """
    return current_user