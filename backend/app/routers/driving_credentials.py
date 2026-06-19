"""Driving credentials endpoints — /me/driving-credentials."""

from uuid import UUID

from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.deps import get_current_user
from app.models.users import User
from app.schemas.driving_credentials import CredentialCreate, CredentialRead, CredentialUpdate
from app.services import driving_credentials as svc

router = APIRouter(tags=["driving_credentials"])


@router.get("/me/driving-credentials", response_model=list[CredentialRead])
def list_credentials(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return svc.list_credentials(db, current_user)


@router.post(
    "/me/driving-credentials",
    response_model=CredentialRead,
    status_code=status.HTTP_201_CREATED,
)
def create_credential(
    payload: CredentialCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return svc.create_credential(db, current_user, payload)


@router.patch("/me/driving-credentials/{credential_id}", response_model=CredentialRead)
def update_credential(
    credential_id: UUID,
    payload: CredentialUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return svc.update_credential(db, current_user, credential_id, payload)


@router.delete("/me/driving-credentials/{credential_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_credential(
    credential_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    svc.delete_credential(db, current_user, credential_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
