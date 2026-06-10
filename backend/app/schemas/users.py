"""Pydantic schemas for the current-user endpoints (Task A5, docs/03-api-contract.md)."""

import re
from datetime import datetime
from typing import Annotated
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_validator


class UserRead(BaseModel):
    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

    id: UUID
    firebase_uid: Annotated[str, Field(serialization_alias="firebaseUid")]
    email: str
    display_name: Annotated[str | None, Field(default=None, serialization_alias="displayName")]
    photo_url: Annotated[str | None, Field(default=None, serialization_alias="photoUrl")]
    currency: str = "USD"
    distance_unit: Annotated[str, Field(serialization_alias="distanceUnit")] = "km"
    created_at: Annotated[datetime, Field(serialization_alias="createdAt")]


class UserUpdate(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    display_name: str | None = Field(default=None, alias="displayName")
    photo_url: str | None = Field(default=None, alias="photoUrl")
    currency: str | None = Field(default=None)
    distance_unit: str | None = Field(default=None, alias="distanceUnit")

    @field_validator("currency")
    @classmethod
    def validate_currency(cls, v: str | None) -> str | None:
        if v is not None and not re.fullmatch(r"[A-Za-z]{3}", v):
            raise ValueError("currency must be a 3-letter code")
        return v

    @field_validator("distance_unit")
    @classmethod
    def validate_distance_unit(cls, v: str | None) -> str | None:
        if v is not None and v not in {"km", "mi"}:
            raise ValueError('distanceUnit must be "km" or "mi"')
        return v
