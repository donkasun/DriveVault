"""All SQLAlchemy models for DriveVault."""

from app.models.dashboard import DashboardData
from app.models.documents import Document
from app.models.fuel_logs import FuelLog
from app.models.maintenance_records import MaintenanceRecord
from app.models.reminders import Reminder
from app.models.schedules import MaintenanceSchedule
from app.models.users import User
from app.models.vehicles import Vehicle

__all__ = [
     "DashboardData",
     "Document",
     "FuelLog",
     "MaintenanceRecord",
     "MaintenanceSchedule",
     "Reminder",
     "User",
     "Vehicle",
]
