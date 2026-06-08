"""documents — metadata for files stored in Cloudinary (Task A3b, docs/02-database-schema.md)."""

from sqlalchemy import BigInteger, Column, Date, ForeignKey, Index, Text, TIMESTAMP, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.db import Base


class Document(Base):
      __tablename__ = "documents"

    id: Mapped[UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=func.gen_random_uuid()
      )
    vehicle_id: Mapped[UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("vehicles.id", ondelete="CASCADE"), nullable=False
      )
    doc_type: Mapped[str] = mapped_column(Text, nullable=False)
    title: Mapped[str] = mapped_column(Text, nullable=False)
    storage_url: Mapped[str] = mapped_column(Text, nullable=False)
    storage_public_id: Mapped[str | None] = mapped_column(Text, nullable=True)
    mime_type: Mapped[str | None] = mapped_column(Text, nullable=True)
    file_size_bytes: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    issue_date: Mapped[object | None] = mapped_column(Date, nullable=True)   # type: ignore[assignment]
    expiry_date: Mapped[object | None] = mapped_column(Date, nullable=True)   # type: ignore[assignment]
    created_at = mapped_column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)
    updated_at = mapped_column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)

    vehicle = relationship("Vehicle", back_populates="documents")
    embeddings = relationship("DocumentEmbedding", back_populates="document")

     __table_args__ = (
        Index("ix_documents_vehicle_id", "vehicle_id"),
        Index("ix_documents_doc_type", "doc_type"),
        Index("ix_documents_expiry_date", "expiry_date"),
      )
