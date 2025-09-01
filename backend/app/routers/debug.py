# app/routers/debug.py
from fastapi import APIRouter, Depends
from app.deps import get_current_user
from app.settings import ADMIN_EMAILS, ADMIN_BYPASS_ENABLED
from app.models import User
from app.deps import is_admin

router = APIRouter(prefix="/debug", tags=["debug"])

@router.get("/whoami")
def whoami(me: User = Depends(get_current_user)):
    return {
        "me": {"id": me.id, "email": me.email, "username": me.username},
        "admin_bypass_enabled": ADMIN_BYPASS_ENABLED,
        "admin_emails": list(ADMIN_EMAILS),
        "is_admin": is_admin(me),
    }