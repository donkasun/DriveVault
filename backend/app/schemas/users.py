"""Pydantic schemas for the current-user endpoints (Task A5, docs/03-api-contract.md)."""

from datetime import datetime
from typing import Annotated
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class UserRead(BaseModel):
    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

    id: UUID
    firebase_uid: Annotated[str, Field(serialization_alias="firebaseUid")]
    email: str
    display_name: Annotated[str | None, Field(default=None, serialization_alias="displayName")]
    photo_url: Annotated[str | None, Field(default=None, serialization_alias="photoUrl")]
    created_at: Annotated[datetime, Field(serialization_alias="createdAt")]


class UserUpdate(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    display_name: str | None = Field(default=None, alias="displayName")
    photo_url: str | None = Field(default=None, alias="photoUrl")
