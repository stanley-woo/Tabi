import os
from typing import Optional

AVATAR_CDN_BASE = os.getenv("AVATAR_CDN_BASE", "")

def to_avatar_url(avatar_name: Optional[str]) -> Optional[str]:
    """Return a full URL for avatar_name. If it's already a URL, pass through."""
    if not avatar_name:
        return None
    if avatar_name.startswith(("http://", "https://")):
        return avatar_name
    if AVATAR_CDN_BASE:
        return f"{AVATAR_CDN_BASE.rstrip('/')}/{avatar_name.lstrip('/')}"
    # Fallback: return a full static path (works if your client also talks to the same host:port)
    return f"/static/{avatar_name.lstrip('/')}"