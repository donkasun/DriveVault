"""Maintenance record business logic and ownership checks (Task B4)."""

from datetime import UTC, date, datetime
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.constants import LOCKED_CURRENCY
from app.models.maintenance_records import MaintenanceRecord
from app.models.users import User
from app.models.vehicles import Vehicle
from app.schemas.maintenance import MaintenanceCreate, MaintenanceUpdate


def get_vehicle_for_user(db: Session, user: User, vehicle_id: UUID) -> Vehicle:
    vehicle = db.scalar(select(Vehicle).where(Vehicle.id == vehicle_id, Vehicle.user_id == user.id))
    if vehicle is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Vehicle not found",
        )
    return vehicle


def list_maintenance_records(
    db: Session,
    user: User,
    vehicle_id: UUID,
    category: str | None = None,
    from_date: date | None = None,
    to_date: date | None = None,
) -> list[MaintenanceRecord]:
    get_vehicle_for_user(db, user, vehicle_id)
    query = select(MaintenanceRecord).where(MaintenanceRecord.vehicle_id == vehicle_id)
    if category is not None:
        query = query.where(MaintenanceRecord.category == category)
    if from_date is not None:
        query = query.where(MaintenanceRecord.date >= from_date)
    if to_date is not None:
        query = query.where(MaintenanceRecord.date <= to_date)
    query = query.order_by(MaintenanceRecord.date.desc(), MaintenanceRecord.created_at.desc())
    return list(db.scalars(query))


def create_maintenance_record(
    db: Session,
    user: User,
    vehicle_id: UUID,
    payload: MaintenanceCreate,
) -> MaintenanceRecord:
    get_vehicle_for_user(db, user, vehicle_id)
    data = payload.model_dump(exclude={"id"})
    data["currency"] = LOCKED_CURRENCY
    record = MaintenanceRecord(vehicle_id=vehicle_id, source="manual", **data)
    if payload.id is not None:
        record.id = payload.id
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


def get_maintenance_record_for_user(
    db: Session,
    user: User,
    maintenance_id: UUID,
) -> MaintenanceRecord:
    record = db.scalar(
        select(MaintenanceRecord)
        .join(Vehicle, MaintenanceRecord.vehicle_id == Vehicle.id)
        .where(MaintenanceRecord.id == maintenance_id, Vehicle.user_id == user.id)
    )
    if record is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Maintenance record not found",
        )
    return record


def update_maintenance_record(
    db: Session,
    user: User,
    maintenance_id: UUID,
    payload: MaintenanceUpdate,
) -> MaintenanceRecord:
    record = get_maintenance_record_for_user(db, user, maintenance_id)
    data = payload.model_dump(exclude_unset=True)
    for field, value in data.items():
        setattr(record, field, value)

    record.updated_at = datetime.now(UTC)
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


def delete_maintenance_record(db: Session, user: User, maintenance_id: UUID) -> None:
    record = get_maintenance_record_for_user(db, user, maintenance_id)
    db.delete(record)
    db.commit()
