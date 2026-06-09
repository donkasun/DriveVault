"""Firebase Admin SDK initialization (Task A4)."""

from __future__ import annotations

import json

import firebase_admin
from firebase_admin import credentials

from app.core.config import get_settings


def init_firebase() -> None:
    """Initialize Firebase Admin once when credentials are configured."""
    if firebase_admin._apps:
        return

    settings = get_settings()
    cred_value = settings.firebase_credentials_json.strip()
    if not cred_value:
        return

    if cred_value.startswith("{"):
        cred = credentials.Certificate(json.loads(cred_value))
    else:
        cred = credentials.Certificate(cred_value)

    firebase_admin.initialize_app(cred)
