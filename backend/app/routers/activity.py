from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.deps import get_current_user
from app.models.users import User
from app.schemas.activity import ActivityItemRead
from app.services.activity_service import get_activity

router = APIRouter(tags=["activity"])


@router.get("/activity", response_model=list[ActivityItemRead])
def list_activity(
    limit: int = Query(default=50, ge=1, le=200),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[ActivityItemRead]:
    return get_activity(db, current_user, limit=limit)
