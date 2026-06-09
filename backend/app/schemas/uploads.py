"""Pydantic schemas for upload-signing endpoints (Task B4b)."""

from typing import Annotated

from pydantic import BaseModel, Field


class CloudinarySignatureRequest(BaseModel):
    folder: str


class CloudinarySignatureRead(BaseModel):
    signature: str
    timestamp: int
    api_key: Annotated[str, Field(serialization_alias="apiKey")]
    cloud_name: Annotated[str, Field(serialization_alias="cloudName")]
    folder: str
