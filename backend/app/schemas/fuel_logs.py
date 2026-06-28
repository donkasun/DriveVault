"""Pydantic schemas for fuel log endpoints and stats (Tasks B2/B3)."""

from datetime import date as date_type
from datetime import datetime
from decimal import Decimal
from typing import Annotated
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class FuelLogBase(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    date: date_type | None = None
    liters: Decimal | None = Field(default=None, gt=0)
    price_cents: int | None = Field(default=None, alias="priceCents")
    currency: str | None = None
    odometer: int | None = None
    is_full_tank: bool = Field(default=True, alias="isFullTank")
    notes: str | None = None


class FuelLogCreate(FuelLogBase):
    id: UUID | None = Field(default=None, description="Client-supplied UUID; generated server-side if omitted")
    date: date_type
    liters: Decimal = Field(gt=0)
    price_cents: int = Field(alias="priceCents")
    odometer: int


class FuelLogUpdate(FuelLogBase):
    pass


class FuelLogRead(BaseModel):
    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

    id: UUID
    vehicle_id: Annotated[UUID, Field(serialization_alias="vehicleId")]
    date: date_type
    liters: Decimal
    price_cents: Annotated[int, Field(serialization_alias="priceCents")]
    currency: str
    odometer: int
    is_full_tank: Annotated[bool, Field(serialization_alias="isFullTank")]
    notes: str | None = None
    created_at: Annotated[datetime, Field(serialization_alias="createdAt")]
    updated_at: Annotated[datetime, Field(serialization_alias="updatedAt")]


class MonthlySpend(BaseModel):
    month: str
    spent_cents: Annotated[int, Field(serialization_alias="spentCents")]


class FuelStatsRead(BaseModel):
    avg_consumption_l_per_100_km: Annotated[
        float | None, Field(serialization_alias="avgConsumptionLPer100Km")
    ]
    avg_cost_per_km_cents: Annotated[int | None, Field(serialization_alias="avgCostPerKmCents")]
    total_liters: Annotated[float, Field(serialization_alias="totalLiters")]
    total_spent_cents: Annotated[int, Field(serialization_alias="totalSpentCents")]
    monthly_spend: Annotated[list[MonthlySpend], Field(serialization_alias="monthlySpend")]
