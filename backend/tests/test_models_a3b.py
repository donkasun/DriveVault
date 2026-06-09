"""Task A3b — fuel_logs, maintenance_records, documents models + migration."""

from datetime import date
from decimal import Decimal

from sqlalchemy import inspect, select

from app.models.documents import Document
from app.models.fuel_logs import FuelLog
from app.models.maintenance_records import MaintenanceRecord
from app.models.users import User
from app.models.vehicles import Vehicle


def test_a3b_migration_creates_child_tables(migrated_engine):
    tables = inspect(migrated_engine).get_table_names()
    assert "fuel_logs" in tables
    assert "maintenance_records" in tables
    assert "documents" in tables


def test_a3b_insert_fuel_maintenance_and_document(db_session):
    user = User(firebase_uid="uid-a3b", email="a3b@example.com")
    db_session.add(user)
    db_session.flush()

    vehicle = Vehicle(user_id=user.id, make="Honda", model="Civic")
    db_session.add(vehicle)
    db_session.flush()

    fuel_log = FuelLog(
        vehicle_id=vehicle.id,
        date=date(2026, 6, 1),
        liters=Decimal("45.500"),
        price_cents=7800,
        odometer=48200,
    )
    maintenance = MaintenanceRecord(
        vehicle_id=vehicle.id,
        date=date(2026, 5, 15),
        service_type="Oil Change",
        category="maintenance",
        cost_cents=8500,
    )
    document = Document(
        vehicle_id=vehicle.id,
        doc_type="insurance",
        title="Comprehensive Policy",
        storage_url="https://res.cloudinary.com/demo/image/upload/v1/policy.pdf",
    )
    db_session.add_all([fuel_log, maintenance, document])
    db_session.commit()

    loaded_fuel = db_session.scalar(select(FuelLog).where(FuelLog.vehicle_id == vehicle.id))
    loaded_maint = db_session.scalar(
        select(MaintenanceRecord).where(MaintenanceRecord.vehicle_id == vehicle.id)
    )
    loaded_doc = db_session.scalar(select(Document).where(Document.vehicle_id == vehicle.id))

    assert loaded_fuel is not None
    assert float(loaded_fuel.liters) == 45.5
    assert loaded_fuel.price_cents == 7800
    assert loaded_maint is not None
    assert loaded_maint.service_type == "Oil Change"
    assert loaded_doc is not None
    assert loaded_doc.doc_type == "insurance"
