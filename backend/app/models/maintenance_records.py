"""maintenance_records — individual service entries (Task A3b, docs/02-database-schema.md).

Note: ai_extraction_id is a plain nullable UUID for Phase 1-2; the FK to
ai_extractions will be added in Phase 3 when that table is created.
"""

import uuid

from sqlalchemy import BigInteger, Date, ForeignKey, Index, Integer, Text, TIMESTAMP, func
from sqlalchemy.dialects.postgresql import CHAR, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.db import Base


class MaintenanceRecord(Base):
    __tablename__ = "maintenance_records"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, server_default=func.gen_random_uuid()
    )
    vehicle_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("vehicles.id", ondelete="CASCADE"), nullable=False
    )
    date: Mapped[object] = mapped_column(Date, nullable=False)  # type: ignore[assignment]
    odometer: Mapped[int | None] = mapped_column(Integer, nullable=True)
    service_type: Mapped[str] = mapped_column(Text, nullable=False)
    category: Mapped[str | None] = mapped_column(Text, nullable=True)
    cost_cents: Mapped[int] = mapped_column(BigInteger, server_default="0", nullable=False)
    currency: Mapped[str] = mapped_column(CHAR(3), server_default="USD", nullable=False)
    workshop: Mapped[str | None] = mapped_column(Text, nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    source: Mapped[str] = mapped_column(Text, server_default="manual", nullable=False)
    ai_extraction_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True), nullable=True)
    created_at: Mapped[object] = mapped_column(  # type: ignore[assignment]
        TIMESTAMP(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[object] = mapped_column(  # type: ignore[assignment]
        TIMESTAMP(timezone=True), server_default=func.now(), nullable=False
    )

    vehicle = relationship("Vehicle", back_populates="maintenance_records")

    __table_args__ = (
        Index("ix_maintenance_vehicle_id", "vehicle_id"),
        Index("ix_maintenance_vehicle_date", "vehicle_id", "date"),
        Index("ix_maintenance_category", "category"),
    )
