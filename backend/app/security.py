import os
from datetime import datetime, timedelta, timezone
from typing import Any, Dict
from jose import jwt, JWTError
from passlib.context import CryptContext

SECRET_KEY = os.getenv("SECRET_KEY", "174d29a2dbfa4bde33f636011aa18faa8274ed8d72ab72de6fe532e8c43e3567")
ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")

ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))
REFRESH_TOKEN_EXPIRE_DAYS = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", "14"))
PASSWORD_RESET_TOKEN_EXPIRE_MINUTES = int(os.getenv("PASSWORD_RESET_TOKEN_EXPIRE_MINUTES", "15"))
EMAIL_VERIFICATION_TOKEN_EXPIRE_HOURS = int(os.getenv("EMAIL_VERIFICATION_TOKEN_EXPIRE_HOURS", "24"))

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(plain: str) -> str:
    """Hash a plaintext password for storage"""
    return pwd_context.hash(plain)

def verify_password(plain: str, hashed: str) -> bool:
    """Verify a user login attempt against a stored hash."""
    return pwd_context.verify(plain, hashed)


def _create_jwt(subject: str, expires_delta: timedelta) -> str:
    """Internal helper to create a signed JWT with expiry."""
    now = datetime.now(timezone.utc)
    payload: Dict[str, Any] = {"sub": subject, "iat": int(now.timestamp())}
    payload["exp"] = int((now + expires_delta).timestamp())
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)

def create_access_token(subject: str) -> str:
    """Create a short-lived access token"""
    return _create_jwt(subject, timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES))

def create_password_reset_token(subject: str) -> str:
    """Create a short-lived token for password reset"""
    return _create_jwt(subject, timedelta(minutes=PASSWORD_RESET_TOKEN_EXPIRE_MINUTES))

def create_email_verification_token(subject: str) -> str:
    """Create a token for email verification"""
    return _create_jwt(subject, timedelta(hours=EMAIL_VERIFICATION_TOKEN_EXPIRE_HOURS))

def decode_jwt(token: str) -> dict:
    """Decode and validate a JWT; raises JWTError on invalid/expired tokens"""
    return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])

