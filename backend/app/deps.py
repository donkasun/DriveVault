"""Shared FastAPI dependencies.

`get_db` is re-exported here for convenience. `get_current_user` (Firebase token
verification) is added in Task A4.
"""

from app.core.db import get_db

__all__ = ["get_db"]
