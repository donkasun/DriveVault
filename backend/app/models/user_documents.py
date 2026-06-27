"""user_documents — driving credentials per user (license, permit, international_license)."""

import uuid

DOC_TYPE_LABELS: dict[str, str] = {
    "license": "Driver's License",
    "permit": "Driving Permit",
    "international_license": "International Driving License",
}

from sqlalchemy import CheckConstraint, Date, ForeignKey, Index, Text, TIMESTAMP, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.db import Base


class UserDocument(Base):
    __tablename__ = "user_documents"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, server_default=func.gen_random_uuid()
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    doc_type: Mapped[str] = mapped_column(Text, nullable=False)
    doc_number: Mapped[str | None] = mapped_column(Text, nullable=True)
    issue_date: Mapped[object | None] = mapped_column(Date, nullable=True)  # type: ignore[assignment]
    expiry_date: Mapped[object | None] = mapped_column(Date, nullable=True)  # type: ignore[assignment]
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[object] = mapped_column(  # type: ignore[assignment]
        TIMESTAMP(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[object] = mapped_column(  # type: ignore[assignment]
        TIMESTAMP(timezone=True), server_default=func.now(), nullable=False
    )

    user = relationship("User", back_populates="user_documents")

    __table_args__ = (
        CheckConstraint(
            "doc_type IN ('license','permit','international_license')",
            name="ck_user_documents_doc_type",
        ),
        Index("ix_user_documents_user_id", "user_id"),
        Index("ix_user_documents_expiry_date", "expiry_date"),
    )
