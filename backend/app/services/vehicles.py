"""Vehicle business logic and ownership checks (Task B1)."""

from datetime import UTC, datetime
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.constants import LOCKED_CURRENCY
from app.models.users import User
from app.models.vehicles import Vehicle
from app.schemas.vehicles import VehicleCreate, VehicleUpdate


def list_vehicles(db: Session, user: User) -> list[Vehicle]:
    return list(
        db.scalars(
            select(Vehicle).where(Vehicle.user_id == user.id).order_by(Vehicle.created_at.desc())
        )
    )


def get_vehicle_for_user(db: Session, user: User, vehicle_id: UUID) -> Vehicle:
    vehicle = db.scalar(select(Vehicle).where(Vehicle.id == vehicle_id, Vehicle.user_id == user.id))
    if vehicle is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Vehicle not found",
        )
    return vehicle


def create_vehicle(db: Session, user: User, payload: VehicleCreate) -> Vehicle:
    data = payload.model_dump()
    data["currency"] = LOCKED_CURRENCY
    vehicle = Vehicle(user_id=user.id, **data)
    db.add(vehicle)
    db.commit()
    db.refresh(vehicle)
    return vehicle


def update_vehicle(db: Session, user: User, vehicle_id: UUID, payload: VehicleUpdate) -> Vehicle:
    vehicle = get_vehicle_for_user(db, user, vehicle_id)
    data = payload.model_dump(exclude_unset=True)
    for field, value in data.items():
        setattr(vehicle, field, value)

    vehicle.updated_at = datetime.now(UTC)
    db.add(vehicle)
    db.commit()
    db.refresh(vehicle)
    return vehicle


def delete_vehicle(db: Session, user: User, vehicle_id: UUID) -> None:
    vehicle = get_vehicle_for_user(db, user, vehicle_id)
    db.delete(vehicle)
    db.commit()
