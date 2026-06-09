"""Documents CRUD endpoints (Task B5)."""

from datetime import UTC, date, datetime
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.deps import get_current_user
from app.models.documents import Document
from app.models.users import User
from app.models.vehicles import Vehicle
from app.schemas.documents import DocumentCreate, DocumentRead, DocumentUpdate

router = APIRouter(tags=["documents"])


def get_vehicle_for_user(db: Session, user: User, vehicle_id: UUID) -> None:
    stmt = select(1).where(
        Vehicle.id == vehicle_id,
        Vehicle.user_id == user.id,
    )
    if db.scalar(stmt) is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Vehicle not found")


def get_document_by_id_and_owner(db: Session, user: User, document_id: UUID) -> Document:
    stmt = select(Document).join(Vehicle).where(
        Document.id == document_id,
        Vehicle.user_id == user.id,
    )
    result = db.scalar(stmt)
    if result is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Document not found")
    return result


@router.get("/vehicles/{vehicle_id}/documents", response_model=list[DocumentRead])
def list_documents(
    vehicle_id: UUID,
    doc_type: str | None = Query(default=None, alias="docType"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    get_vehicle_for_user(db, current_user, vehicle_id)
    stmt = select(Document).where(Document.vehicle_id == vehicle_id)
    if doc_type is not None:
        stmt = stmt.where(Document.doc_type == doc_type)
    stmt = stmt.order_by(Document.expiry_date.desc(), Document.created_at.desc())
    return list(db.scalars(stmt))


@router.post(
    "/vehicles/{vehicle_id}/documents",
    response_model=DocumentRead,
    status_code=status.HTTP_201_CREATED,
)
def create_document(
    vehicle_id: UUID,
    payload: DocumentCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    get_vehicle_for_user(db, current_user, vehicle_id)
    document = Document(vehicle_id=vehicle_id, **payload.model_dump())
    db.add(document)
    try:
        db.commit()
        db.refresh(document)
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Failed to create document: {e}")
    return document


@router.get("/documents/{document_id}", response_model=DocumentRead)
def get_document(
    document_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return get_document_by_id_and_owner(db, current_user, document_id)


@router.patch("/documents/{document_id}", response_model=DocumentRead)
def update_document(
    document_id: UUID,
    payload: DocumentUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    document = get_document_by_id_and_owner(db, current_user, document_id)
    data = payload.model_dump(exclude_unset=True)
    for field, value in data.items():
        setattr(document, field, value)
    document.updated_at = datetime.now(UTC)
    try:
        db.add(document)
        db.commit()
        db.refresh(document)
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Failed to update document: {e}")
    return document


@router.delete("/documents/{document_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_document(
    document_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    document = get_document_by_id_and_owner(db, current_user, document_id)
    db.delete(document)
    try:
        db.commit()
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Failed to delete document: {e}")
    return Response(status_code=status.HTTP_204_NO_CONTENT)
