"""Dashboard aggregate endpoint service (Task B6)."""

from datetime import date, timedelta
from typing import List

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.documents import Document
from app.models.users import User
from app.models.vehicles import Vehicle


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
        - upcoming_renewals: Documents expiring within 90 days
    """
    # Get all vehicles owned by the user
    vehicles_result = db.execute(
        select(Vehicle).where(Vehicle.user_id == current_user.id)
    )
    vehicles = list(vehicles_result.scalars())
    vehicle_count = len(vehicles)

    if vehicle_count == 0:
        # Return empty dashboard data if no vehicles
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
        }

    # Calculate fuel costs for the current month
    today = date.today()
    month_start = date(today.year, today.month, 1)
    if today.month == 12:
        next_month_start = date(today.year + 1, 1, 1)
    else:
        next_month_start = date(today.year, today.month + 1, 1)

    from app.models.fuel_logs import FuelLog
    fuel_logs_result = db.execute(
        select(FuelLog)
        .join(Vehicle, FuelLog.vehicle_id == Vehicle.id)
        .where(
            FuelLog.vehicle_id.in_([v.id for v in vehicles]),
            FuelLog.date >= month_start,
            FuelLog.date < next_month_start,
        )
    )
    fuel_logs = list(fuel_logs_result.scalars())

    monthly_fuel_spend_cents = sum(log.price_cents for log in fuel_logs)
    
    # Calculate total fuel cost (all time)
    all_fuel_logs_result = db.execute(
        select(FuelLog).join(Vehicle, FuelLog.vehicle_id == Vehicle.id)
        .where(FuelLog.vehicle_id.in_([v.id for v in vehicles]))
    )
    all_fuel_logs = list(all_fuel_logs_result.scalars())
    total_fuel_cents = sum(log.price_cents for log in all_fuel_logs)

    # Calculate maintenance costs
    from app.models.maintenance_records import MaintenanceRecord
    maintenance_result = db.execute(
        select(MaintenanceRecord)
        .join(Vehicle, MaintenanceRecord.vehicle_id == Vehicle.id)
        .where(MaintenanceRecord.vehicle_id.in_([v.id for v in vehicles]))
    )
    maintenance_records = list(maintenance_result.scalars())
    total_maintenance_cents = sum(record.cost_cents for record in maintenance_records)

    # Calculate purchase costs (treat NULL as 0)
    purchase_costs_result = db.execute(
        select(Vehicle.purchase_price_cents).where(
            Vehicle.id.in_([v.id for v in vehicles])
        )
    )
    purchase_prices = [row.purchase_price_cents or 0 for row in purchase_costs_result]
    total_purchase_cents = sum(purchase_prices)

    # Calculate upcoming renewals (documents expiring within 90 days from today)
    ninety_days_later = today + timedelta(days=90)
    
    documents_result = db.execute(
        select(Document)
        .join(Vehicle, Document.vehicle_id == Vehicle.id)
        .where(
            Document.vehicle_id.in_([v.id for v in vehicles]),
            Document.expiry_date.isnot(None),
            Document.expiry_date >= today,
            Document.expiry_date <= ninety_days_later,
        )
    )
    documents = list(documents_result.scalars())

    upcoming_renewals = []
    for doc in documents:
        upcoming_renewals.append({
            "vehicle_id": doc.vehicle_id,
            "title": doc.title,
            "expiry_date": doc.expiry_date.strftime("%Y-%m-%d"),
        })

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
    }
