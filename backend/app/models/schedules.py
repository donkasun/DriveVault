"""maintenance_schedules — recurring service intervals (Task A3c, docs/02-database-schema.md)."""

from sqlalchemy import Boolean, Column, Date, ForeignKey, Index, Integer, Text, TIMESTAMP, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.db import Base


class MaintenanceSchedule(Base):
        __tablename__ = "maintenance_schedules"

    id: Mapped[UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=func.gen_random_uuid()
        )
    vehicle_id: Mapped[UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("vehicles.id", ondelete="CASCADE"), nullable=False
        )
    service_type: Mapped[str] = mapped_column(Text, nullable=False)
    interval_months: Mapped[int | None] = mapped_column(Integer, nullable=True)
    interval_km: Mapped[int | None] = mapped_column(Integer, nullable=True)
    last_service_date: Mapped[object | None] = mapped_column(Date, nullable=True)  # type: ignore[assignment]
    last_service_odometer: Mapped[int | None] = mapped_column(Integer, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at = mapped_column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)
    updated_at = mapped_column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)

    vehicle = relationship("Vehicle", back_populates="schedules")
    reminders = relationship("Reminder", back_populates="schedule")

        __table_args__ = (Index("ix_schedules_vehicle_id", "vehicle_id"),)
