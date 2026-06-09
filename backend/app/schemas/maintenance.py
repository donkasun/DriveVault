"""Pydantic schemas for maintenance endpoints (Task B4)."""

from datetime import date as date_type
from datetime import datetime
from typing import Annotated
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class MaintenanceBase(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    date: date_type | None = None
    odometer: int | None = None
    service_type: str | None = Field(default=None, alias="serviceType")
    category: str | None = None
    cost_cents: int = Field(default=0, alias="costCents")
    currency: str = "USD"
    workshop: str | None = None
    notes: str | None = None


class MaintenanceCreate(MaintenanceBase):
    date: date_type
    service_type: str = Field(alias="serviceType")


class MaintenanceUpdate(MaintenanceBase):
    pass


class MaintenanceRead(BaseModel):
    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

    id: UUID
    vehicle_id: Annotated[UUID, Field(serialization_alias="vehicleId")]
    date: date_type
    odometer: int | None = None
    service_type: Annotated[str, Field(serialization_alias="serviceType")]
    category: str | None = None
    cost_cents: Annotated[int, Field(serialization_alias="costCents")]
    currency: str
    workshop: str | None = None
    notes: str | None = None
    source: str
    ai_extraction_id: Annotated[UUID | None, Field(serialization_alias="aiExtractionId")]
    created_at: Annotated[datetime, Field(serialization_alias="createdAt")]
    updated_at: Annotated[datetime, Field(serialization_alias="updatedAt")]
