from datetime import datetime, timezone, timedelta
from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session
from fastapi_mail import FastMail, MessageSchema, ConnectionConfig
from jose import JWTError

from app.database import get_session
from app.deps import get_current_user, is_admin
from app.models import User
from app.schemas import PasswordReset, PasswordResetRequest, RegisterRequest, LoginRequest, RefreshRequest, TokenPair, UserRead, MeOut, EmailVerificationRequest, VerifyEmail, ChangePassword
from app import crud
from app.security import create_access_token, create_password_reset_token, create_email_verification_token, decode_jwt
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
async def register(data: RegisterRequest, session: Session = Depends(get_session)):
    """Create a new user account for authentication."""
    if crud.get_user_by_username(session=session, username=data.username):
        raise HTTPException(status_code=400, detail="Username already taken.")
    if crud.get_user_by_email(session=session, email=str(data.email)):
        raise HTTPException(status_code=400, detail="Email already taken.")
    
    user = crud.create_user_with_password(session, email=str(data.email), username=data.username, password=data.password)
    
    # Send verification email
    token = create_email_verification_token(subject=str(data.email))
    verification_url = f"tabi://verify-email?token={token}"
    email_body = f"""
    <html>
    <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <h2 style="color: #2E7D32;">Welcome to Tabi!</h2>
        <p>Please verify your email address by clicking the link below:</p>
        <div style="text-align: center; margin: 30px 0;">
            <a href="{verification_url}" style="background-color: #4CAF50; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;">Verify Email</a>
        </div>
        <p style="color: #666; font-size: 14px;">If you did not create an account, please ignore this email.</p>
        <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
        <p style="color: #999; font-size: 12px;">If the button doesn't work, copy and paste this link into your browser:</p>
        <p style="color: #999; font-size: 12px; word-break: break-all;">{verification_url}</p>
    </body>
    </html>
    """
    await send_email(
        subject="Welcome to Tabi - Verify Your Email",
        recipients=[str(data.email)],
        body=email_body
    )
    
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
    return MeOut(
        id=current_user.id,
        username=current_user.username,
        email=current_user.email,
        is_admin=is_admin(current_user),
        is_email_verified=current_user.is_email_verified
    )

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
    <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
        <h2 style="color: #1976D2;">Password Reset Request</h2>
        <p>Hello,</p>
        <p>You requested a password reset. Click the button below to reset your password:</p>
        <div style="text-align: center; margin: 30px 0;">
            <a href="{reset_url}" style="background-color: #2196F3; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;">Reset Password</a>
        </div>
        <p style="color: #666; font-size: 14px;">If you did not request this, please ignore this email.</p>
        <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
        <p style="color: #999; font-size: 12px;">If the button doesn't work, copy and paste this link into your browser:</p>
        <p style="color: #999; font-size: 12px; word-break: break-all;">{reset_url}</p>
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

@router.post("/verify-email", status_code=200)
def verify_email(data: VerifyEmail, session: Session = Depends(get_session)):
    """Verify user's email address using a verification token."""
    try:
        payload = decode_jwt(data.token)
        email = payload.get("sub")
        if not email:
            raise HTTPException(status_code=400, detail="Invalid token: Subject missing")
        
        user = crud.get_user_by_email(session, email=email)
        if not user:
            raise HTTPException(status_code=400, detail="User not found")
        
        if user.is_email_verified:
            return {"msg": "Email already verified"}
        
        # Mark email as verified
        user.is_email_verified = True
        session.add(user)
        session.commit()
        
        return {"msg": "Email verified successfully"}
    except JWTError:
        raise HTTPException(status_code=400, detail="Invalid or expired token")

@router.post("/resend-verification", status_code=202)
async def resend_verification(data: EmailVerificationRequest, session: Session = Depends(get_session)):
    """Resend email verification link to user."""
    user = crud.get_user_by_email(session, email=str(data.email))
    if user and not user.is_email_verified:
        # Create a verification token
        token = create_email_verification_token(subject=str(data.email))
        verification_url = f"tabi://verify-email?token={token}"
        email_body = f"""
        <html>
        <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
            <h2 style="color: #2E7D32;">Verify Your Email</h2>
            <p>Hello,</p>
            <p>Please verify your email address by clicking the button below:</p>
            <div style="text-align: center; margin: 30px 0;">
                <a href="{verification_url}" style="background-color: #4CAF50; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; display: inline-block; font-weight: bold;">Verify Email</a>
            </div>
            <p style="color: #666; font-size: 14px;">If you did not create an account, please ignore this email.</p>
            <hr style="margin: 30px 0; border: none; border-top: 1px solid #eee;">
            <p style="color: #999; font-size: 12px;">If the button doesn't work, copy and paste this link into your browser:</p>
            <p style="color: #999; font-size: 12px; word-break: break-all;">{verification_url}</p>
        </body>
        </html>
        """
        await send_email(
            subject="Verify Your Email",
            recipients=[str(data.email)],
            body=email_body
        )
    
    return {"msg": "If an unverified user with that email exists, a verification link has been sent."}

@router.post("/change-password", status_code=200)
def change_password(data: ChangePassword, current_user: User = Depends(get_current_user), session: Session = Depends(get_session)):
    """Change user's password. Requires current password verification."""
    # Verify current password
    if not crud.verify_user_credentials(session, email=current_user.email, password=data.current_password):
        raise HTTPException(status_code=400, detail="Current password is incorrect")
    
    # Update password
    crud.update_user_password(session, current_user, data.new_password)
    
    # Revoke all refresh tokens for this user (force re-login)
    crud.revoke_all_user_tokens(session, current_user.id)
    
    return {"msg": "Password changed successfully. Please log in again."}
    