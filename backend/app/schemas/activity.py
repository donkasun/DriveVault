from datetime import date as date_type, datetime
from typing import Annotated, Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class ActivityItemRead(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    type: Literal["fuel", "maintenance", "document"]
    id: UUID
    vehicle_id: Annotated[UUID, Field(serialization_alias="vehicleId")]
    vehicle_label: Annotated[str, Field(serialization_alias="vehicleLabel")]
    date: date_type
    amount_cents: Annotated[int | None, Field(default=None, serialization_alias="amountCents")]
    label: str
    currency: str = "LKR"
    created_at: Annotated[datetime, Field(serialization_alias="createdAt")]

    liters: float | None = None
    is_full_tank: Annotated[bool | None, Field(default=None, serialization_alias="isFullTank")]
    odometer: int | None = None
    notes: str | None = None
    source: str | None = None
    category: str | None = None
    workshop: str | None = None

    # Document-specific (None for fuel/maintenance)
    title: str | None = None
    doc_type: Annotated[str | None, Field(default=None, serialization_alias="docType")]
    storage_url: Annotated[str | None, Field(default=None, serialization_alias="storageUrl")]
    storage_public_id: Annotated[
        str | None, Field(default=None, serialization_alias="storagePublicId")
    ]
    mime_type: Annotated[str | None, Field(default=None, serialization_alias="mimeType")]
    file_size_bytes: Annotated[int | None, Field(default=None, serialization_alias="fileSizeBytes")]
    issue_date: Annotated[date_type | None, Field(default=None, serialization_alias="issueDate")]
    expiry_date: Annotated[date_type | None, Field(default=None, serialization_alias="expiryDate")]
