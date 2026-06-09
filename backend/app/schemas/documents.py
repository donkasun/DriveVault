"""Pydantic schemas for document endpoints (Task B5)."""

from datetime import date, datetime
from typing import Annotated
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


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
    storage_public_id: Annotated[str | None, Field(default=None, serialization_alias="storagePublicId")]
    mime_type: Annotated[str | None, Field(default=None, serialization_alias="mimeType")]
    file_size_bytes: Annotated[int | None, Field(default=None, serialization_alias="fileSizeBytes")]
    issue_date: Annotated[date | None, Field(default=None, serialization_alias="issueDate")]
    expiry_date: Annotated[date | None, Field(default=None, serialization_alias="expiryDate")]
    created_at: Annotated[datetime, Field(serialization_alias="createdAt")]
    updated_at: Annotated[datetime, Field(serialization_alias="updatedAt")]
