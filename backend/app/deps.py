from fastapi import Depends, HTTPException, status, Path
from jose import JWTError
from sqlmodel import Session, select
from app.database import get_session
from app.models import User, Itinerary, DayGroup, ItineraryBlock
from app.security import decode_jwt
from app.settings import ADMIN_EMAILS, ADMIN_BYPASS_ENABLED
from fastapi.security import OAuth2PasswordBearer, HTTPBearer

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")
bearer_scheme = HTTPBearer(auto_error=True)

def get_current_user(token: str = Depends(oauth2_scheme), session: Session = Depends(get_session)) -> User:
    """
    Dependency: validates the JWT access token and returns the corresponding User.
    - Extracts token from Authorization header
    - Decodes JWT (raises if invalid/expired)
    - Loads the User from DB using `sub`
    """
    credentials_exception = HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Could not validate credentials", headers={"WWW-Authenticate": "Bearer"})

    try:
        payload = decode_jwt(token)   # verify signature & expiry
        subject: str = payload.get("sub")
        if subject is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    # In your case, `sub` is email (we’re storing user.email in JWT)
    user = session.exec(select(User).where(User.email == subject)).first()
    if user is None:
        raise credentials_exception
    return user


def is_admin(user: User) -> bool:
    """Dev-only admin check based on email allowlist."""
    if not ADMIN_BYPASS_ENABLED:
        return False
    return bool(user and user.email and user.email.lower() in ADMIN_EMAILS)

def ensure_itinerary_owner(itinerary_id : int = Path(...), session: Session = Depends(get_session), current_user: User = Depends(get_current_user)) -> Itinerary:
    """Loads itinerary and ensures the current user owns it; else 404."""
    itin = session.get(Itinerary, itinerary_id)
    if not itin:
        raise HTTPException(status_code=404, detail="Not Found")
    if itin.creator_id == current_user.id or is_admin(current_user):
        return itin
    raise HTTPException(status_code=404, detail="Not Found")

def ensure_daygroup_owner(day_id: int = Path(...), session: Session = Depends(get_session), current_user: User = Depends(get_current_user)) -> DayGroup:
    day = session.get(DayGroup, day_id)
    if not day:
        raise HTTPException(status_code=404, detail="Not Found")
    itin = session.get(Itinerary, day.itinerary_id)
    if itin and (itin.creator_id == current_user.id or is_admin(current_user)):
        return day
    raise HTTPException(status_code=404, detail="Not Found")

def ensure_block_owner(block_id: int = Path(...), session: Session = Depends(get_session), current_user: User = Depends(get_current_user)) -> ItineraryBlock:
    blk = session.get(ItineraryBlock, block_id)
    if not blk:
        raise HTTPException(status_code=404, detail="Not Found")
    day = session.get(DayGroup, blk.day_group_id)
    if not day:
        raise HTTPException(status_code=404, detail="Not Found")
    itin = session.get(Itinerary, day.itinerary_id)
    if not itin:
        raise HTTPException(status_code=404, detail="Not Found")
    if itin.creator_id == current_user.id or is_admin(current_user):
        return blk
    raise HTTPException(status_code=404, detail="Not Found") 


def ensure_user_self(target_user_id: int, current_user: User = Depends(get_current_user)) -> None:
    if target_user_id != current_user.id and not is_admin(current_user):
        raise HTTPException(status_code=404, detail="Not Found")