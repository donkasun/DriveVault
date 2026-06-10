"""Pydantic schemas for DriveVault API."""

from app.schemas.documents import (
    CostBreakdown,
    DashboardRead,
    DocumentBase,
    DocumentCreate,
    DocumentRead,
    DocumentUpdate,
    UpcomingRenewal,
)
from app.schemas.fuel_logs import FuelLogBase, FuelLogCreate, FuelLogRead, FuelLogUpdate, FuelStatsRead, MonthlySpend
from app.schemas.maintenance import MaintenanceRecordBase, MaintenanceRecordCreate, MaintenanceRecordRead, MaintenanceRecordUpdate
from app.schemas.uploads import CloudinarySignature, UploadProgress
from app.schemas.users import UserCreate, UserRead, UserUpdate
from app.schemas.vehicles import VehicleBase, VehicleCreate, VehicleRead, VehicleUpdate

__all__ = [
    "CostBreakdown",
    "DashboardRead",
    "DocumentBase",
    "DocumentCreate",
    "DocumentRead",
    "DocumentUpdate",
    "UpcomingRenewal",
    "FuelLogBase",
    "FuelLogCreate",
    "FuelLogRead",
    "FuelLogUpdate",
    "FuelStatsRead",
    "MonthlySpend",
    "MaintenanceRecordBase",
    "MaintenanceRecordCreate",
    "MaintenanceRecordRead",
    "MaintenanceRecordUpdate",
    "CloudinarySignature",
    "UploadProgress",
    "UserCreate",
    "UserRead",
    "UserUpdate",
    "VehicleBase",
    "VehicleCreate",
    "VehicleRead",
    "VehicleUpdate",
]
