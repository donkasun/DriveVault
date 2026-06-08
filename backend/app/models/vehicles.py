"""vehicles - vehicles a user owns (Task A3a, docs/02-database-schema.md)."""

from sqlalchemy import BigInteger, CheckConstraint, Column, Date, ForeignKey, Index, Integer, String, Text, TIMESTAMP, func
from sqlalchemy.dialects.postgresql import CHAR, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.db import Base


class Vehicle(Base):
    __tablename__ = "vehicles"

    id: Mapped[UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=func.gen_random_uuid()
    )
    user_id: Mapped[UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    make: Mapped[str] = mapped_column(Text, nullable=False)
    model: Mapped[str] = mapped_column(Text, nullable=False)
    year: Mapped[int | None] = mapped_column(Integer, nullable=True)
    registration_number: Mapped[str | None] = mapped_column(Text, nullable=True)
    vin: Mapped[str | None] = mapped_column(Text, nullable=True)
    purchase_date: Mapped[object | None] = mapped_column(Date, nullable=True)  # type: ignore[assignment]
    purchase_price_cents: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
    currency: Mapped[str] = mapped_column(CHAR(3), default="USD", nullable=False)
    current_mileage: Mapped[int | None] = mapped_column(Integer, nullable=True)
    photo_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    photo_public_id: Mapped[str | None] = mapped_column(Text, nullable=True)
    vehicle_type: Mapped[str | None] = mapped_column(Text, nullable=True)

    user = relationship("User", back_populates="vehicles")
    fuel_logs = relationship("FuelLog", back_populates="vehicle")
    maintenance_records = relationship("MaintenanceRecord", back_populates="vehicle")
    documents = relationship("Document", back_populates="vehicle")
    schedules = relationship("MaintenanceSchedule", back_populates="vehicle")
    reminders = relationship("Reminder", back_populates="vehicle")

    __table_args__ = (
        CheckConstraint("year >= 1900 AND year <= 2100", name="ck_vehicles_year_range"),
        Index("ix_vehicles_user_id", "user_id"),
    )
