"""User profile business logic (Task A5)."""

from datetime import UTC, datetime

from sqlalchemy.orm import Session

from app.models.users import User
from app.schemas.users import UserUpdate


def update_user_profile(db: Session, user: User, payload: UserUpdate) -> User:
    """Apply partial profile updates and persist updated_at."""
    data = payload.model_dump(exclude_unset=True)
    for field, value in data.items():
        setattr(user, field, value)

    user.updated_at = datetime.now(UTC)
    db.add(user)
    db.commit()
    db.refresh(user)
    return user
