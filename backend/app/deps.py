"""Shared FastAPI dependencies."""

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from firebase_admin import auth
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.models.users import User

security = HTTPBearer(auto_error=False)


async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(security),
    db: Session = Depends(get_db),
) -> User:
    """Verify Firebase ID token and lazily upsert the matching users row."""
    if credentials is None or not credentials.credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing authorization token",
        )

    # Bug 2 fix: pass check_revoked=True so revoked tokens are rejected immediately.
    try:
        decoded = auth.verify_id_token(credentials.credentials, check_revoked=True)
    except auth.RevokedIdTokenError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has been revoked",
        ) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        ) from exc

    firebase_uid = decoded["uid"]
    # Bug 3 fix: only use email when Firebase has verified it.
    email = decoded.get("email") if decoded.get("email_verified") is True else ""

    user = db.scalar(select(User).where(User.firebase_uid == firebase_uid))
    if user is None:
        # Bug 1 fix: handle race condition where two concurrent requests both see
        # user is None and both attempt to INSERT the same firebase_uid.
        try:
            user = User(firebase_uid=firebase_uid, email=email)
            db.add(user)
            db.commit()
            db.refresh(user)
        except IntegrityError:
            db.rollback()
            user = db.scalar(select(User).where(User.firebase_uid == firebase_uid))
            if user is None:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="User creation failed",
                )

    return user


__all__ = ["get_db", "get_current_user", "security"]
