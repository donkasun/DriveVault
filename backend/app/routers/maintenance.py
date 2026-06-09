"""Maintenance and upload-signing endpoints (Tasks B4/B4b)."""

from datetime import date
from uuid import UUID

from fastapi import APIRouter, Depends, Query, Response, status
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.deps import get_current_user
from app.models.users import User
from app.schemas.maintenance import MaintenanceCreate, MaintenanceRead, MaintenanceUpdate
from app.schemas.uploads import CloudinarySignatureRead, CloudinarySignatureRequest
from app.services import maintenance as maintenance_service
from app.services import uploads as upload_service

router = APIRouter(tags=["maintenance"])


@router.get("/vehicles/{vehicle_id}/maintenance", response_model=list[MaintenanceRead])
def list_maintenance_records(
    vehicle_id: UUID,
    category: str | None = None,
    from_date: date | None = Query(default=None, alias="from"),
    to_date: date | None = Query(default=None, alias="to"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return maintenance_service.list_maintenance_records(
        db,
        current_user,
        vehicle_id,
        category,
        from_date,
        to_date,
    )


@router.post(
    "/vehicles/{vehicle_id}/maintenance",
    response_model=MaintenanceRead,
    status_code=status.HTTP_201_CREATED,
)
def create_maintenance_record(
    vehicle_id: UUID,
    payload: MaintenanceCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return maintenance_service.create_maintenance_record(db, current_user, vehicle_id, payload)


@router.get("/maintenance/{maintenance_id}", response_model=MaintenanceRead)
def get_maintenance_record(
    maintenance_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return maintenance_service.get_maintenance_record_for_user(db, current_user, maintenance_id)


@router.patch("/maintenance/{maintenance_id}", response_model=MaintenanceRead)
def update_maintenance_record(
    maintenance_id: UUID,
    payload: MaintenanceUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return maintenance_service.update_maintenance_record(db, current_user, maintenance_id, payload)


@router.delete("/maintenance/{maintenance_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_maintenance_record(
    maintenance_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    maintenance_service.delete_maintenance_record(db, current_user, maintenance_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/uploads/cloudinary-signature", response_model=CloudinarySignatureRead)
def create_cloudinary_signature(
    payload: CloudinarySignatureRequest,
    current_user: User = Depends(get_current_user),
):
    return upload_service.sign_cloudinary_upload(payload.folder)
