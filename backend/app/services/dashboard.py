"""Dashboard aggregate endpoint service (Task B6)."""

from datetime import date, timedelta
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.documents import Document
from app.models.fuel_logs import FuelLog
from app.models.maintenance_records import MaintenanceRecord
from app.models.user_documents import DOC_TYPE_LABELS, UserDocument
from app.models.users import User
from app.models.vehicles import Vehicle
from app.services.renewals import days_until, renewal_status


def _vehicle_label(vehicle: Vehicle) -> str:
    """Return a human-readable label for a vehicle: make+model+year or registration_number."""
    if vehicle.make and vehicle.model:
        label = f"{vehicle.make} {vehicle.model}"
        if vehicle.year:
            label = f"{vehicle.year} {label}"
        return label
    if vehicle.registration_number:
        return vehicle.registration_number
    return str(vehicle.id)


def get_dashboard_data(
    db: Session,
    current_user: User,
) -> dict:
    """
    Get aggregated dashboard data for the current user across all their vehicles.

    Returns:
        Dictionary with:
        - vehicle_count: Total number of vehicles owned by the user
        - monthly_fuel_spend_cents: Sum of fuel prices for the current calendar month
        - total_ownership_cost_cents: Sum of all costs (fuel + maintenance + purchase)
        - cost_breakdown: Breakdown by category
        - upcoming_renewals: Overdue docs + docs expiring within 90 days, sorted by expiry_date
        - recent_activity: Last 10 events across fuel, maintenance, and documents
    """
    # ── vehicles ──────────────────────────────────────────────────────────────
    vehicles_result = db.execute(select(Vehicle).where(Vehicle.user_id == current_user.id))
    vehicles = list(vehicles_result.scalars())
    vehicle_count = len(vehicles)

    if vehicle_count == 0:
        return {
            "vehicle_count": 0,
            "monthly_fuel_spend_cents": 0,
            "total_ownership_cost_cents": 0,
            "cost_breakdown": {
                "fuel_cents": 0,
                "maintenance_cents": 0,
                "purchase_cents": 0,
            },
            "upcoming_renewals": [],
            "recent_activity": [],
        }

    vehicle_ids: list[UUID] = [v.id for v in vehicles]
    # Build a label map once to avoid N+1 on activity rows
    label_map: dict[UUID, str] = {v.id: _vehicle_label(v) for v in vehicles}

    today = date.today()

    # ── fuel costs ────────────────────────────────────────────────────────────
    month_start = date(today.year, today.month, 1)
    if today.month == 12:
        next_month_start = date(today.year + 1, 1, 1)
    else:
        next_month_start = date(today.year, today.month + 1, 1)

    all_fuel_logs: list[FuelLog] = list(
        db.scalars(select(FuelLog).where(FuelLog.vehicle_id.in_(vehicle_ids)))
    )
    monthly_fuel_spend_cents = sum(
        log.price_cents for log in all_fuel_logs if month_start <= log.date < next_month_start
    )
    total_fuel_cents = sum(log.price_cents for log in all_fuel_logs)

    # ── maintenance costs ─────────────────────────────────────────────────────
    all_maintenance: list[MaintenanceRecord] = list(
        db.scalars(select(MaintenanceRecord).where(MaintenanceRecord.vehicle_id.in_(vehicle_ids)))
    )
    total_maintenance_cents = sum(r.cost_cents for r in all_maintenance)

    # ── purchase costs ────────────────────────────────────────────────────────
    purchase_costs_result = db.execute(
        select(Vehicle.purchase_price_cents).where(Vehicle.id.in_(vehicle_ids))
    )
    total_purchase_cents = sum(row.purchase_price_cents or 0 for row in purchase_costs_result)

    # ── upcoming renewals (vehicle docs + personal credentials, overdue + within 90 days) ──
    ninety_days_later = today + timedelta(days=90)

    docs_for_renewals: list[Document] = list(
        db.scalars(
            select(Document).where(
                Document.vehicle_id.in_(vehicle_ids),
                Document.expiry_date.isnot(None),
                Document.expiry_date <= ninety_days_later,
            )
        )
    )

    creds_for_renewals: list[UserDocument] = list(
        db.scalars(
            select(UserDocument).where(
                UserDocument.user_id == current_user.id,
                UserDocument.expiry_date.isnot(None),
                UserDocument.expiry_date <= ninety_days_later,
            )
        )
    )

    upcoming_renewals: list[dict] = []

    for doc in docs_for_renewals:
        upcoming_renewals.append({
            "vehicle_id": doc.vehicle_id,
            "title": doc.title,
            "expiry_date": doc.expiry_date,
            "doc_type": doc.doc_type,
            "vehicle_label": label_map[doc.vehicle_id],
            "days_remaining": days_until(doc.expiry_date, today),
            "status": renewal_status(doc.expiry_date, today),
        })

    for cred in creds_for_renewals:
        upcoming_renewals.append({
            "vehicle_id": None,
            "title": DOC_TYPE_LABELS.get(cred.doc_type, cred.doc_type),
            "expiry_date": cred.expiry_date,
            "doc_type": cred.doc_type,
            "vehicle_label": None,
            "days_remaining": days_until(cred.expiry_date, today),
            "status": renewal_status(cred.expiry_date, today),
        })

    upcoming_renewals.sort(key=lambda d: d["expiry_date"])

    # ── recent activity (merged, date-descending, limit 10) ──────────────────
    activity_items: list[dict] = []

    for log in all_fuel_logs:
        activity_items.append(
            {
                "type": "fuel",
                "vehicle_id": log.vehicle_id,
                "vehicle_label": label_map[log.vehicle_id],
                "date": log.date,
                "amount_cents": log.price_cents,
                "label": "Fuel",
                "liters": float(log.liters),
                "is_full_tank": log.is_full_tank,
            }
        )

    for rec in all_maintenance:
        activity_items.append(
            {
                "type": "maintenance",
                "vehicle_id": rec.vehicle_id,
                "vehicle_label": label_map[rec.vehicle_id],
                "date": rec.date,
                "amount_cents": rec.cost_cents,
                "label": rec.service_type,
            }
        )

    all_docs: list[Document] = list(
        db.scalars(select(Document).where(Document.vehicle_id.in_(vehicle_ids)))
    )
    for doc in all_docs:
        # Use issue_date if available, else created_at date
        doc_date = doc.issue_date if doc.issue_date is not None else doc.created_at.date()
        activity_items.append(
            {
                "type": "document",
                "vehicle_id": doc.vehicle_id,
                "vehicle_label": label_map[doc.vehicle_id],
                "date": doc_date,
                "amount_cents": None,
                "label": doc.title,
            }
        )

    # Sort descending by date, take top 10
    activity_items.sort(key=lambda x: x["date"], reverse=True)
    recent_activity = activity_items[:10]

    total_ownership_cost_cents = total_fuel_cents + total_maintenance_cents + total_purchase_cents

    return {
        "vehicle_count": vehicle_count,
        "monthly_fuel_spend_cents": monthly_fuel_spend_cents,
        "total_ownership_cost_cents": total_ownership_cost_cents,
        "cost_breakdown": {
            "fuel_cents": total_fuel_cents,
            "maintenance_cents": total_maintenance_cents,
            "purchase_cents": total_purchase_cents,
        },
        "upcoming_renewals": upcoming_renewals,
        "recent_activity": recent_activity,
    }
