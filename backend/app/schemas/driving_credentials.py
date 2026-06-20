"""Pydantic schemas for driving credentials endpoints."""

from datetime import UTC, date, datetime
from typing import Annotated, Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, field_serializer

from app.services.renewals import days_until, renewal_status


class CredentialBase(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    doc_type: Literal["license", "permit", "international_license"] | None = Field(default=None, alias="docType")
    doc_number: str | None = Field(default=None, alias="docNumber")
    issue_date: date | None = Field(default=None, alias="issueDate")
    expiry_date: date | None = Field(default=None, alias="expiryDate")
    notes: str | None = None


class CredentialCreate(CredentialBase):
    doc_type: Literal["license", "permit", "international_license"] = Field(alias="docType")


class CredentialUpdate(CredentialBase):
    pass


class CredentialRead(BaseModel):
    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

    id: UUID
    doc_type: Annotated[str, Field(serialization_alias="docType")]
    doc_number: Annotated[str | None, Field(default=None, serialization_alias="docNumber")]
    issue_date: Annotated[date | None, Field(default=None, serialization_alias="issueDate")]
    expiry_date: Annotated[date | None, Field(default=None, serialization_alias="expiryDate")]
    notes: str | None = None
    status: str | None = None          # computed — None when no expiryDate
    days_until_expiry: Annotated[int | None, Field(default=None, serialization_alias="daysUntilExpiry")]
    created_at: Annotated[datetime, Field(serialization_alias="createdAt")]
    updated_at: Annotated[datetime, Field(serialization_alias="updatedAt")]

    @field_serializer("issue_date", "expiry_date")
    def serialize_date(self, v: date | None) -> str | None:
        return v.strftime("%Y-%m-%d") if v else None

    @classmethod
    def from_model(cls, obj: object) -> "CredentialRead":
        from app.models.user_documents import UserDocument
        doc: UserDocument = obj  # type: ignore[assignment]
        today = datetime.now(UTC).date()
        computed_status = renewal_status(doc.expiry_date, today) if doc.expiry_date else None
        computed_days = days_until(doc.expiry_date, today) if doc.expiry_date else None
        return cls(
            id=doc.id,
            doc_type=doc.doc_type,
            doc_number=doc.doc_number,
            issue_date=doc.issue_date,
            expiry_date=doc.expiry_date,
            notes=doc.notes,
            status=computed_status,
            days_until_expiry=computed_days,
            created_at=doc.created_at,
            updated_at=doc.updated_at,
        )
