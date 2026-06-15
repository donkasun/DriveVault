"""Vehicle business logic and ownership checks (Task B1)."""

from collections import defaultdict
from datetime import UTC, date, datetime
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.constants import LOCKED_CURRENCY
from app.models.documents import Document
from app.models.users import User
from app.models.vehicles import Vehicle
from app.schemas.vehicles import DocsStatus, VehicleCreate, VehicleRead, VehicleUpdate
from app.services.renewals import renewal_status


def _compute_docs_status(docs: list[Document], today: date) -> DocsStatus:
    """Compute docs_status for a single vehicle given its documents."""
    expiry_docs = [d for d in docs if d.expiry_date is not None]
    if not expiry_docs:
        return DocsStatus(state="none", needs_action_count=0)
    needs_action = sum(
        1 for d in expiry_docs if renewal_status(d.expiry_date, today) in ("soon", "overdue")
    )
    if needs_action > 0:
        return DocsStatus(state="needs_action", needs_action_count=needs_action)
    return DocsStatus(state="valid", needs_action_count=0)


def _attach_docs_status(vehicles: list[Vehicle], db: Session) -> list[VehicleRead]:
    """
    Build VehicleRead objects with docs_status, using a single documents query
    so there are no N+1 queries when listing many vehicles.
    """
    if not vehicles:
        return []

    vehicle_ids = [v.id for v in vehicles]
    today = date.today()

    # Single query: all documents with expiry_date set for these vehicles
    all_docs: list[Document] = list(
        db.scalars(
            select(Document).where(
                Document.vehicle_id.in_(vehicle_ids),
                Document.expiry_date.isnot(None),
            )
        )
    )
    docs_by_vehicle: dict[UUID, list[Document]] = defaultdict(list)
    for doc in all_docs:
        docs_by_vehicle[doc.vehicle_id].append(doc)

    result: list[VehicleRead] = []
    for vehicle in vehicles:
        read = VehicleRead.model_validate(vehicle)
        read.docs_status = _compute_docs_status(docs_by_vehicle[vehicle.id], today)
        result.append(read)
    return result


def list_vehicles(db: Session, user: User) -> list[VehicleRead]:
    vehicles = list(
        db.scalars(
            select(Vehicle).where(Vehicle.user_id == user.id).order_by(Vehicle.created_at.desc())
        )
    )
    return _attach_docs_status(vehicles, db)


def get_vehicle_for_user(db: Session, user: User, vehicle_id: UUID) -> Vehicle:
    """Ownership-checked fetch returning the ORM Vehicle.

    This is the shared building block used by write paths and by other services
    (fuel logs, maintenance, documents) that need to read or mutate the row.
    The API read path uses :func:`get_vehicle_read_for_user` instead.
    """
    vehicle = db.scalar(select(Vehicle).where(Vehicle.id == vehicle_id, Vehicle.user_id == user.id))
    if vehicle is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Vehicle not found",
        )
    return vehicle


def get_vehicle_read_for_user(db: Session, user: User, vehicle_id: UUID) -> VehicleRead:
    """API read: the owned Vehicle serialized as VehicleRead with docs_status."""
    vehicle = get_vehicle_for_user(db, user, vehicle_id)
    return _attach_docs_status([vehicle], db)[0]


def create_vehicle(db: Session, user: User, payload: VehicleCreate) -> VehicleRead:
    data = payload.model_dump()
    data["currency"] = LOCKED_CURRENCY
    vehicle = Vehicle(user_id=user.id, **data)
    db.add(vehicle)
    db.commit()
    db.refresh(vehicle)
    return _attach_docs_status([vehicle], db)[0]


def update_vehicle(
    db: Session, user: User, vehicle_id: UUID, payload: VehicleUpdate
) -> VehicleRead:
    vehicle = get_vehicle_for_user(db, user, vehicle_id)
    data = payload.model_dump(exclude_unset=True)
    for field, value in data.items():
        setattr(vehicle, field, value)

    vehicle.updated_at = datetime.now(UTC)
    db.add(vehicle)
    db.commit()
    db.refresh(vehicle)
    return _attach_docs_status([vehicle], db)[0]


def delete_vehicle(db: Session, user: User, vehicle_id: UUID) -> None:
    vehicle = get_vehicle_for_user(db, user, vehicle_id)
    db.delete(vehicle)
    db.commit()
