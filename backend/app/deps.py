# app/deps.py
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError
from sqlmodel import Session

from app.database import get_session
from app.models import User
from app.security import decode_jwt

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

def get_current_user(
    token: str = Depends(oauth2_scheme),
    session: Session = Depends(get_session),
) -> User:
    """
    Dependency: validates the JWT access token and returns the corresponding User.
    - Extracts token from Authorization header
    - Decodes JWT (raises if invalid/expired)
    - Loads the User from DB using `sub`
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = decode_jwt(token)   # verify signature & expiry
        subject: str = payload.get("sub")
        if subject is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    # In your case, `sub` is email (we’re storing user.email in JWT)
    user = session.query(User).filter(User.email == subject).first()
    if user is None:
        raise credentials_exception
    return user