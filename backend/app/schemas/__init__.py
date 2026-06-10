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
from app.schemas.maintenance import MaintenanceBase, MaintenanceCreate, MaintenanceRead, MaintenanceUpdate
from app.schemas.uploads import CloudinarySignatureRead, CloudinarySignatureRequest
from app.schemas.users import UserRead, UserUpdate
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
    "MaintenanceBase",
    "MaintenanceCreate",
    "MaintenanceRead",
    "MaintenanceUpdate",
    "CloudinarySignatureRead",
    "CloudinarySignatureRequest",
    "UserRead",
    "UserUpdate",
    "VehicleBase",
    "VehicleCreate",
    "VehicleRead",
    "VehicleUpdate",
]
