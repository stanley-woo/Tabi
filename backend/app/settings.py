# app/settings.py
from __future__ import annotations

from typing import Set
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict
import json


class Settings(BaseSettings):
    # Load from .env and ignore unknown keys
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    # Read the env var as a plain string (so pydantic won't JSON-decode it first)
    admin_emails_raw: str | None = Field(
        default=None,
        validation_alias="ADMIN_EMAILS",  # map env var -> this field
    )
    admin_bypass_enabled: bool = Field(
        default=False,
        validation_alias="ADMIN_BYPASS_ENABLED",
    )

    @property
    def admin_emails(self) -> Set[str]:
        """
        Parse ADMIN_EMAILS from either:
        - CSV string:  "a@b.com, c@d.com"
        - JSON array:  '["a@b.com","c@d.com"]'
        Returns a lowercased, trimmed set.
        """
        raw = self.admin_emails_raw
        if not raw:
            return set()

        # Try JSON array first
        try:
            val = json.loads(raw)
            if isinstance(val, (list, tuple, set)):
                return {str(x).strip().lower() for x in val if str(x).strip()}
        except Exception:
            pass

        # Fallback: CSV
        return {p.strip().lower() for p in raw.split(",") if p.strip()}


settings = Settings()

# Optional convenience exports (so existing imports keep working)
ADMIN_EMAILS = settings.admin_emails
ADMIN_BYPASS_ENABLED = settings.admin_bypass_enabled