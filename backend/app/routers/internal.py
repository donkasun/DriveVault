"""Internal endpoints called by Cloud Scheduler — not for public use."""

from fastapi import APIRouter, Depends, Header, HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.db import get_db
from app.services.reminder_processing import process_reminders

router = APIRouter(prefix="/internal", tags=["internal"])


def _verify_secret(x_internal_secret: str = Header(default="")) -> None:
    settings = get_settings()
    expected = settings.internal_secret
    if not expected or x_internal_secret != expected:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Unauthorized")


@router.post("/process-reminders")
def run_process_reminders(
    _: None = Depends(_verify_secret),
    db: Session = Depends(get_db),
) -> dict:
    return process_reminders(db)
