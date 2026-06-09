"""SQLAlchemy ORM models — imported so Alembic can see all tables (docs/02-database-schema.md).

Every model is imported here to register it with Base.metadata for migration generation.
Phase 1–2 models are used immediately; Phase 3+ models are registered as placeholders
so the FKs and indexes match the final design without requiring future migrations.
"""

# Phase 1 (MVP)
from app.models.users import User
from app.models.vehicles import Vehicle
from app.models.fuel_logs import FuelLog
from app.models.maintenance_records import MaintenanceRecord
from app.models.documents import Document

# Phase 2 (Smart Ownership) — designed up front, used in later phases
from app.models.schedules import MaintenanceSchedule
from app.models.reminders import Reminder

__all__ = [
    "User",
    "Vehicle",
    "FuelLog",
    "MaintenanceRecord",
    "Document",
    "MaintenanceSchedule",
    "Reminder",
]
