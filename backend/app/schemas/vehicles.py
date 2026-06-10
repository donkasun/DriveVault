"""Pydantic schemas for vehicle endpoints (Task B1)."""

from datetime import date, datetime
from typing import Annotated
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator

FUEL_TYPES = {"petrol", "diesel", "electric", "hybrid", "other"}


class VehicleBase(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    make: str | None = None
    model: str | None = None
    year: int | None = None
    registration_number: str | None = Field(default=None, alias="registrationNumber")
    vin: str | None = None
    purchase_date: date | None = Field(default=None, alias="purchaseDate")
    purchase_price_cents: int | None = Field(default=None, alias="purchasePriceCents")
    currency: str = "USD"
    current_mileage: int | None = Field(default=None, alias="currentMileage")
    vehicle_type: str | None = Field(default=None, alias="vehicleType")
    fuel_type: str | None = Field(default=None, alias="fuelType")
    default_fuel_variant: str | None = Field(default=None, alias="defaultFuelVariant")
    distance_unit: str | None = Field(default=None, alias="distanceUnit")
    photo_url: str | None = Field(default=None, alias="photoUrl")
    photo_public_id: str | None = Field(default=None, alias="photoPublicId")

    @field_validator("fuel_type")
    @classmethod
    def validate_fuel_type(cls, v: str | None) -> str | None:
        if v is not None and v not in FUEL_TYPES:
            raise ValueError(f"fuelType must be one of {sorted(FUEL_TYPES)}")
        return v

    @field_validator("distance_unit")
    @classmethod
    def validate_distance_unit(cls, v: str | None) -> str | None:
        if v is not None and v not in {"km", "mi"}:
            raise ValueError('distanceUnit must be "km", "mi", or null')
        return v


class VehicleCreate(VehicleBase):
    make: str
    model: str


class VehicleUpdate(VehicleBase):
    pass


class VehicleRead(BaseModel):
    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

    id: UUID
    make: str
    model: str
    year: int | None = None
    registration_number: Annotated[
        str | None, Field(default=None, serialization_alias="registrationNumber")
    ]
    vin: str | None = None
    purchase_date: Annotated[date | None, Field(default=None, serialization_alias="purchaseDate")]
    purchase_price_cents: Annotated[
        int | None, Field(default=None, serialization_alias="purchasePriceCents")
    ]
    currency: str
    current_mileage: Annotated[
        int | None, Field(default=None, serialization_alias="currentMileage")
    ]
    vehicle_type: Annotated[str | None, Field(default=None, serialization_alias="vehicleType")]
    fuel_type: Annotated[str | None, Field(default=None, serialization_alias="fuelType")]
    default_fuel_variant: Annotated[
        str | None, Field(default=None, serialization_alias="defaultFuelVariant")
    ]
    distance_unit: Annotated[str | None, Field(default=None, serialization_alias="distanceUnit")]
    photo_url: Annotated[str | None, Field(default=None, serialization_alias="photoUrl")]
    photo_public_id: Annotated[str | None, Field(default=None, serialization_alias="photoPublicId")]
    created_at: Annotated[datetime, Field(serialization_alias="createdAt")]
    updated_at: Annotated[datetime, Field(serialization_alias="updatedAt")]
