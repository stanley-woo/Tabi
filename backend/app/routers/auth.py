from datetime import datetime, timezone, timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session
from fastapi_mail import FastMail, MessageSchema, ConnectionConfig
from jose import JWTError

from app.database import get_session
from app.deps import get_current_user, is_admin
from app.models import User
from app.schemas import PasswordReset, PasswordResetRequest, RegisterRequest, LoginRequest, RefreshRequest, TokenPair, UserRead, MeOut
from app import crud
from app.security import create_access_token, create_password_reset_token, decode_jwt
from app.settings import settings


# --- BEGIN: Mail Sending Logic ---
try:
    # Newer fastapi-mail exposes an enum for subtype; if not present, we’ll just pass "html" as a string
    from fastapi_mail import MessageType
    HTML_SUBTYPE = MessageType.html
except Exception:
    HTML_SUBTYPE = "html"

conf = ConnectionConfig(
    MAIL_USERNAME=settings.MAIL_USERNAME,
    MAIL_PASSWORD=settings.MAIL_PASSWORD,
    MAIL_FROM=settings.MAIL_FROM,
    MAIL_PORT=settings.MAIL_PORT,
    MAIL_SERVER=settings.MAIL_SERVER,
    MAIL_STARTTLS=settings.MAIL_STARTTLS,
    MAIL_SSL_TLS=settings.MAIL_SSL_TLS,
    USE_CREDENTIALS=True,
    VALIDATE_CERTS=True,
    MAIL_FROM_NAME=getattr(settings, "MAIL_FROM_NAME", None),
)

fm = FastMail(conf)

async def send_email(subject: str, recipients: list[str], body: str):
    message = MessageSchema(
        subject=subject,
        recipients=recipients,
        body=body,
        subtype=HTML_SUBTYPE
    )
    await fm.send_message(message)

# --- END: Mail Sending Logic ---


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

@router.get("/me", response_model=MeOut)
def me(current_user: User = Depends(get_current_user)):
    """
    Return the current authenticated user.
    - Requires Authorization: Bearer <access JWT>
    - get_current_user() decodes JWT + loads the user from DB
    """
    return MeOut(id=current_user.id,username=current_user.username,email=current_user.email,is_admin=is_admin(current_user))

@router.post("/forgot-password", status_code=202)
async def forget_password(data: PasswordResetRequest, session: Session = Depends(get_session)):
    """
    Send a password reset email to the user.
    """
    user = crud.get_user_by_email(session, email=str(data.email))
    if user:
        # Create a password reset token
        token = create_password_reset_token(subject=str(data.email))
        # This is where you would structure your email
        reset_url = f"tabi://reset-password?token={token}"
        email_body = f"""
        <html>
        <body>
            <p>Hello,</p>
            <p>You requested a password reset. Click the link below to reset your password:</p>
            <a href="{reset_url}">Reset Password</a>
            <p>If you did not request this, please ignore this email.</p>
        </body>
        </html>
        """
        await send_email(
            subject="Password Reset Request",
            recipients=[str(data.email)],
            body=email_body
        )

        return {"msg": "If a user with that email exists, a password reset link has been sent."}

@router.post("/reset-password", status_code=200)
def reset_password(data: PasswordReset, session: Session = Depends(get_session)):
    """Reset the user's password using a valid token."""
    try:
        payload = decode_jwt(data.token)
        email = payload.get("sub")
        if not email:
            raise HTTPException(status_code=400, detail="Invalid token: Subject missing")
        user = crud.get_user_by_email(session, email=email)

        if not user:
            raise HTTPException(status_code=400, detail="User not found")
        crud.update_user_password(session, user, data.new_password)
        return {"msg": "Password updated successfully"}
    except JWTError:
        raise HTTPException(status_code=400, detail="Invalid or expired token")
    