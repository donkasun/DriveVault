from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

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
                price_cents=log.price_cents,
                liters=log.liters,
                is_full_tank=log.is_full_tank,
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
                currency=record.currency or "LKR",
                cost_cents=record.cost_cents,
                service_type=record.service_type,
                category=record.category,
            )
        )

    items.sort(key=lambda i: i.date, reverse=True)
    return items[:limit]
