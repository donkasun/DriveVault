"""Current-user endpoints (Task A5, docs/03-api-contract.md)."""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.deps import get_current_user
from app.models.users import User
from app.schemas.users import UserRead, UserUpdate
from app.services.users import update_user_profile

router = APIRouter(prefix="/me", tags=["me"])


@router.get("", response_model=UserRead)
def get_me(current_user: User = Depends(get_current_user)) -> User:
    return current_user


@router.patch("", response_model=UserRead)
def patch_me(
    payload: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> User:
    return update_user_profile(db, current_user, payload)
