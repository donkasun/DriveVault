"""CRUD service for user driving credentials."""

from datetime import UTC, datetime
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.user_documents import UserDocument
from app.models.users import User
from app.schemas.driving_credentials import CredentialCreate, CredentialRead, CredentialUpdate


def list_credentials(db: Session, user: User) -> list[CredentialRead]:
    rows = list(db.scalars(select(UserDocument).where(UserDocument.user_id == user.id)))
    return [CredentialRead.from_model(r) for r in rows]


def create_credential(db: Session, user: User, payload: CredentialCreate) -> CredentialRead:
    doc = UserDocument(user_id=user.id, **payload.model_dump(by_alias=False, exclude_none=True))
    db.add(doc)
    db.commit()
    db.refresh(doc)
    return CredentialRead.from_model(doc)


def _get_owned(db: Session, user: User, credential_id: UUID) -> UserDocument:
    doc = db.scalar(
        select(UserDocument).where(
            UserDocument.id == credential_id,
            UserDocument.user_id == user.id,
        )
    )
    if doc is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Credential not found")
    return doc


def update_credential(
    db: Session, user: User, credential_id: UUID, payload: CredentialUpdate
) -> CredentialRead:
    doc = _get_owned(db, user, credential_id)
    for field, value in payload.model_dump(by_alias=False, exclude_unset=True).items():
        setattr(doc, field, value)
    doc.updated_at = datetime.now(UTC)
    db.commit()
    db.refresh(doc)
    return CredentialRead.from_model(doc)


def delete_credential(db: Session, user: User, credential_id: UUID) -> None:
    doc = _get_owned(db, user, credential_id)
    db.delete(doc)
    db.commit()
