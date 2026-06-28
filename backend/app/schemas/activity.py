from datetime import date as date_type
from decimal import Decimal
from typing import Annotated, Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class ActivityItemRead(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    type: Literal["fuel", "maintenance"]
    id: UUID
    vehicle_id: Annotated[UUID, Field(serialization_alias="vehicleId")]
    vehicle_label: Annotated[str, Field(serialization_alias="vehicleLabel")]
    date: date_type
    currency: str = "LKR"

    # Fuel-specific (None for maintenance)
    price_cents: Annotated[int | None, Field(default=None, serialization_alias="priceCents")]
    liters: Decimal | None = None
    is_full_tank: Annotated[bool | None, Field(default=None, serialization_alias="isFullTank")]

    # Maintenance-specific (None for fuel)
    cost_cents: Annotated[int | None, Field(default=None, serialization_alias="costCents")]
    service_type: Annotated[str | None, Field(default=None, serialization_alias="serviceType")]
    category: str | None = None
