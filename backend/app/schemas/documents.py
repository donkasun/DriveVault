"""Pydantic schemas for document endpoints (Task B5)."""

from datetime import date, datetime
from typing import Annotated
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_serializer


class DocumentBase(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    doc_type: str | None = Field(default=None, alias="docType")
    title: str | None = None
    storage_url: str | None = Field(default=None, alias="storageUrl")
    storage_public_id: str | None = Field(default=None, alias="storagePublicId")
    mime_type: str | None = Field(default=None, alias="mimeType")
    file_size_bytes: int | None = Field(default=None, alias="fileSizeBytes")
    issue_date: date | None = Field(default=None, alias="issueDate")
    expiry_date: date | None = Field(default=None, alias="expiryDate")


class DocumentCreate(DocumentBase):
    doc_type: str = Field(alias="docType")
    title: str
    storage_url: str = Field(alias="storageUrl")


class DocumentUpdate(DocumentBase):
    pass


class DocumentRead(BaseModel):
    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

    id: UUID
    vehicle_id: Annotated[UUID, Field(serialization_alias="vehicleId")]
    doc_type: Annotated[str, Field(serialization_alias="docType")]
    title: str
    storage_url: Annotated[str, Field(serialization_alias="storageUrl")]
    storage_public_id: Annotated[
        str | None, Field(default=None, serialization_alias="storagePublicId")
    ]
    mime_type: Annotated[str | None, Field(default=None, serialization_alias="mimeType")]
    file_size_bytes: Annotated[int | None, Field(default=None, serialization_alias="fileSizeBytes")]
    issue_date: Annotated[date | None, Field(default=None, serialization_alias="issueDate")]
    expiry_date: Annotated[date | None, Field(default=None, serialization_alias="expiryDate")]
    created_at: Annotated[datetime, Field(serialization_alias="createdAt")]
    updated_at: Annotated[datetime, Field(serialization_alias="updatedAt")]


class CostBreakdown(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    fuel_cents: int = Field(serialization_alias="fuelCents")
    maintenance_cents: int = Field(serialization_alias="maintenanceCents")
    purchase_cents: int = Field(serialization_alias="purchaseCents")


class UpcomingRenewal(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    vehicle_id: Annotated[UUID, Field(serialization_alias="vehicleId")]
    title: str
    expiry_date: Annotated[date, Field(serialization_alias="expiryDate")]
    doc_type: Annotated[str, Field(serialization_alias="docType")]
    vehicle_label: Annotated[str, Field(serialization_alias="vehicleLabel")]
    days_remaining: Annotated[int, Field(serialization_alias="daysRemaining")]
    status: str  # "ok" | "soon" | "overdue"

    @field_serializer("expiry_date")
    def serialize_expiry_date(self, v: date) -> str:
        return v.strftime("%Y-%m-%d")


class ActivityItem(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    type: str  # "fuel" | "maintenance" | "document"
    vehicle_id: Annotated[UUID, Field(serialization_alias="vehicleId")]
    vehicle_label: Annotated[str, Field(serialization_alias="vehicleLabel")]
    date: date
    amount_cents: Annotated[int | None, Field(default=None, serialization_alias="amountCents")]
    label: str
    # Fuel-only fields — None for non-fuel activity
    liters: float | None = None
    is_full_tank: Annotated[bool | None, Field(default=None, serialization_alias="isFullTank")]

    @field_serializer("date")
    def serialize_date(self, v: date) -> str:
        return v.strftime("%Y-%m-%d")


class DashboardRead(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    vehicle_count: int = Field(serialization_alias="vehicleCount")
    monthly_fuel_spend_cents: int = Field(serialization_alias="monthlyFuelSpendCents")
    total_ownership_cost_cents: int = Field(serialization_alias="totalOwnershipCostCents")
    cost_breakdown: Annotated[CostBreakdown, Field(serialization_alias="costBreakdown")]
    upcoming_renewals: Annotated[
        list[UpcomingRenewal], Field(default=[], serialization_alias="upcomingRenewals")
    ]
    recent_activity: Annotated[
        list[ActivityItem], Field(default=[], serialization_alias="recentActivity")
    ]
