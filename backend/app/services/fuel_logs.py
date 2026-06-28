"""Fuel log business logic and fuel economy stats (Tasks B2/B3)."""

from collections import defaultdict
from datetime import UTC, date, datetime
from decimal import Decimal
from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.constants import LOCKED_CURRENCY
from app.models.fuel_logs import FuelLog
from app.models.users import User
from app.models.vehicles import Vehicle
from app.schemas.fuel_logs import FuelLogCreate, FuelLogUpdate, FuelStatsRead, MonthlySpend
from app.services.vehicles import get_vehicle_for_user


def list_fuel_logs(
    db: Session,
    user: User,
    vehicle_id: UUID,
    from_date: date | None = None,
    to_date: date | None = None,
) -> list[FuelLog]:
    get_vehicle_for_user(db, user, vehicle_id)
    query = select(FuelLog).where(FuelLog.vehicle_id == vehicle_id)
    if from_date is not None:
        query = query.where(FuelLog.date >= from_date)
    if to_date is not None:
        query = query.where(FuelLog.date <= to_date)
    query = query.order_by(FuelLog.date.desc(), FuelLog.created_at.desc())
    return list(db.scalars(query))


def _sync_current_mileage(db: Session, vehicle: Vehicle) -> None:
    """Set vehicle.current_mileage to MAX(odometer) of its fuel logs, or None if empty."""
    max_odometer = db.scalar(
        select(func.max(FuelLog.odometer)).where(FuelLog.vehicle_id == vehicle.id)
    )
    vehicle.current_mileage = max_odometer
    db.add(vehicle)


def create_fuel_log(db: Session, user: User, vehicle_id: UUID, payload: FuelLogCreate) -> FuelLog:
    vehicle = get_vehicle_for_user(db, user, vehicle_id)
    existing_max = db.scalar(
        select(func.max(FuelLog.odometer)).where(FuelLog.vehicle_id == vehicle_id)
    )
    if existing_max is not None and payload.odometer <= existing_max:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Odometer must be greater than the latest reading ({existing_max} km)",
        )
    data = payload.model_dump(exclude={"id"})
    data["currency"] = LOCKED_CURRENCY
    fuel_log = FuelLog(vehicle_id=vehicle_id, **data)
    if payload.id is not None:
        fuel_log.id = payload.id
    db.add(fuel_log)
    db.flush()
    _sync_current_mileage(db, vehicle)
    db.commit()
    db.refresh(fuel_log)
    return fuel_log


def get_fuel_log_for_user(db: Session, user: User, fuel_log_id: UUID) -> FuelLog:
    fuel_log = db.scalar(
        select(FuelLog)
        .join(Vehicle, FuelLog.vehicle_id == Vehicle.id)
        .where(FuelLog.id == fuel_log_id, Vehicle.user_id == user.id)
    )
    if fuel_log is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Fuel log not found",
        )
    return fuel_log


def update_fuel_log(db: Session, user: User, fuel_log_id: UUID, payload: FuelLogUpdate) -> FuelLog:
    fuel_log = get_fuel_log_for_user(db, user, fuel_log_id)
    data = payload.model_dump(exclude_unset=True)
    for field, value in data.items():
        setattr(fuel_log, field, value)

    fuel_log.updated_at = datetime.now(UTC)
    db.add(fuel_log)
    db.commit()
    db.refresh(fuel_log)
    return fuel_log


def delete_fuel_log(db: Session, user: User, fuel_log_id: UUID) -> None:
    fuel_log = get_fuel_log_for_user(db, user, fuel_log_id)
    vehicle = get_vehicle_for_user(db, user, fuel_log.vehicle_id)
    db.delete(fuel_log)
    db.flush()
    _sync_current_mileage(db, vehicle)
    db.commit()


def compute_fuel_stats(db: Session, user: User, vehicle_id: UUID) -> FuelStatsRead:
    get_vehicle_for_user(db, user, vehicle_id)
    logs = list(
        db.scalars(
            select(FuelLog).where(FuelLog.vehicle_id == vehicle_id).order_by(FuelLog.date.asc())
        )
    )

    total_liters = sum(Decimal(log.liters) for log in logs)
    total_spent_cents = sum(log.price_cents for log in logs)

    monthly_totals: dict[str, int] = defaultdict(int)
    for log in logs:
        monthly_totals[log.date.strftime("%Y-%m")] += log.price_cents

    # Interval method: a measurement interval can only OPEN and CLOSE at a
    # full-tank fill, where the tank level is a known reference. Partial fills
    # accumulate into the interval that closes at the next full tank. Partial
    # fills before the first full tank (no valid opening anchor) and after the
    # last full tank (interval never closes) are both excluded from the average.
    pending_liters = Decimal("0")
    pending_distance = 0
    pending_spent_cents = 0
    closed_liters = Decimal("0")
    closed_distance = 0
    closed_spent_cents = 0
    interval_open = False

    for previous, current in zip(logs, logs[1:]):
        if not interval_open:
            # Only a full-tank log can anchor the start of an interval.
            if not previous.is_full_tank:
                continue
            interval_open = True
        distance = current.odometer - previous.odometer
        if distance <= 0:
            continue
        pending_liters += Decimal(current.liters)
        pending_distance += distance
        pending_spent_cents += current.price_cents
        if current.is_full_tank:
            closed_liters += pending_liters
            closed_distance += pending_distance
            closed_spent_cents += pending_spent_cents
            pending_liters = Decimal("0")
            pending_distance = 0
            pending_spent_cents = 0

    avg_consumption = None
    avg_cost_per_km_cents = None
    if closed_distance > 0:
        avg_consumption = round(float((closed_liters / Decimal(closed_distance)) * Decimal(100)), 1)
        avg_cost_per_km_cents = round(closed_spent_cents / closed_distance)

    monthly_spend = [
        MonthlySpend(month=month, spent_cents=spent_cents)
        for month, spent_cents in sorted(monthly_totals.items(), reverse=True)
    ]

    return FuelStatsRead(
        avg_consumption_l_per_100_km=avg_consumption,
        avg_cost_per_km_cents=avg_cost_per_km_cents,
        total_liters=float(total_liters),
        total_spent_cents=total_spent_cents,
        monthly_spend=monthly_spend,
    )
