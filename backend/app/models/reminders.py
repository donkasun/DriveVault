"""reminders — generated alerts for service due or document expiry (Task A3c, docs/02-database-schema.md)."""

from sqlalchemy import Column, Date, ForeignKey, Index, Integer, Text, TIMESTAMP, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.db import Base


class Reminder(Base):
        __tablename__ = "reminders"

    id: Mapped[UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=func.gen_random_uuid()
        )
    vehicle_id: Mapped[UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("vehicles.id", ondelete="CASCADE"), nullable=False
        )
    schedule_id: Mapped[UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("maintenance_schedules.id"), nullable=True
        )
    document_id: Mapped[UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("documents.id"), nullable=True
        )
    reminder_type: Mapped[str] = mapped_column(Text, nullable=False)
    title: Mapped[str] = mapped_column(Text, nullable=False)
    due_date: Mapped[object | None] = mapped_column(Date, nullable=True)   # type: ignore[assignment]
    due_odometer: Mapped[int | None] = mapped_column(Integer, nullable=True)
    status: Mapped[str] = mapped_column(Text, default="pending", nullable=False)
    created_at = mapped_column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)
    updated_at = mapped_column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)

    vehicle = relationship("Vehicle", back_populates="reminders")
    schedule = relationship("MaintenanceSchedule", back_populates="reminders")

        __table_args__ = (
        Index("ix_reminders_vehicle_id", "vehicle_id"),
        Index("ix_reminders_status", "status"),
        Index("ix_reminders_due_date", "due_date"),
        )
