from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.constants import LOCKED_CURRENCY
from app.models.documents import Document
from app.models.fuel_logs import FuelLog
from app.models.maintenance_records import MaintenanceRecord
from app.models.users import User
from app.models.vehicles import Vehicle
from app.schemas.activity import ActivityItemRead
from app.services.dashboard import _vehicle_label


def get_activity(
    db: Session,
    user: User,
    limit: int = 50,
) -> list[ActivityItemRead]:
    vehicles = list(db.scalars(select(Vehicle).where(Vehicle.user_id == user.id)))
    if not vehicles:
        return []

    vehicle_ids = [v.id for v in vehicles]
    label_map: dict[UUID, str] = {v.id: _vehicle_label(v) for v in vehicles}

    fuel_logs = list(
        db.scalars(
            select(FuelLog)
            .where(FuelLog.vehicle_id.in_(vehicle_ids))
            .order_by(FuelLog.date.desc())
            .limit(limit)
        )
    )

    maintenance_records = list(
        db.scalars(
            select(MaintenanceRecord)
            .where(MaintenanceRecord.vehicle_id.in_(vehicle_ids))
            .order_by(MaintenanceRecord.date.desc())
            .limit(limit)
        )
    )

    items: list[ActivityItemRead] = []

    for log in fuel_logs:
        items.append(
            ActivityItemRead(
                type="fuel",
                id=log.id,
                vehicle_id=log.vehicle_id,
                vehicle_label=label_map.get(log.vehicle_id, str(log.vehicle_id)),
                date=log.date,
                currency=log.currency,
                amount_cents=log.price_cents,
                label="Fuel",
                created_at=log.created_at,
                liters=float(log.liters),
                is_full_tank=log.is_full_tank,
                odometer=log.odometer,
                notes=log.notes,
            )
        )

    for record in maintenance_records:
        items.append(
            ActivityItemRead(
                type="maintenance",
                id=record.id,
                vehicle_id=record.vehicle_id,
                vehicle_label=label_map.get(record.vehicle_id, str(record.vehicle_id)),
                date=record.date,
                currency=record.currency or LOCKED_CURRENCY,
                amount_cents=record.cost_cents,
                label=record.service_type,
                created_at=record.created_at,
                odometer=record.odometer,
                notes=record.notes,
                category=record.category,
                workshop=record.workshop,
                source=record.source,
            )
        )

    all_docs: list[Document] = list(
        db.scalars(select(Document).where(Document.vehicle_id.in_(vehicle_ids)))
    )
    for doc in all_docs:
        doc_date = doc.issue_date if doc.issue_date is not None else doc.created_at.date()
        items.append(
            ActivityItemRead(
                type="document",
                id=doc.id,
                vehicle_id=doc.vehicle_id,
                vehicle_label=label_map.get(doc.vehicle_id, str(doc.vehicle_id)),
                date=doc_date,
                amount_cents=None,
                label=doc.title,
                currency=LOCKED_CURRENCY,
                created_at=doc.created_at,
                title=doc.title,
                doc_type=doc.doc_type,
                storage_url=doc.storage_url,
                storage_public_id=doc.storage_public_id,
                mime_type=doc.mime_type,
                file_size_bytes=doc.file_size_bytes,
                issue_date=doc.issue_date,
                expiry_date=doc.expiry_date,
            )
        )

    items.sort(key=lambda i: i.date, reverse=True)
    return items[:limit]
