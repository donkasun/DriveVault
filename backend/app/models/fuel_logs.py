"""fuel_logs - individual fuel purchase entries (Task A3b, docs/02-database-schema.md)."""

from sqlalchemy import BigInteger, CheckConstraint, Column, Date, ForeignKey, Index, Integer, Numeric, Text, TIMESTAMP, func
from sqlalchemy.dialects.postgresql import CHAR, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.db import Base


class FuelLog(Base):
    __tablename__ = "fuel_logs"

    id: Mapped[UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=func.gen_random_uuid()
    )
    vehicle_id: Mapped[UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("vehicles.id", ondelete="CASCADE"), nullable=False
    )
    date: Mapped[object] = mapped_column(Date, nullable=False)  # type: ignore[assignment]
    liters: Mapped[float] = mapped_column(Numeric(8, 3), nullable=False)
    price_cents: Mapped[int] = mapped_column(BigInteger, nullable=False)
    currency: Mapped[str] = mapped_column(CHAR(3), default="USD", nullable=False)
    odometer: Mapped[int] = mapped_column(Integer, nullable=False)
    is_full_tank: Mapped[bool] = mapped_column(default=True, nullable=False)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[object] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)  # type: ignore[assignment]
    updated_at: Mapped[object] = mapped_column(TIMESTAMP(timezone=True), server_default=func.now(), nullable=False)  # type: ignore[assignment]

    vehicle = relationship("Vehicle", back_populates="fuel_logs")

    __table_args__ = (
        CheckConstraint("liters > 0", name="ck_fuel_logs_liters_positive"),
        Index("ix_fuel_logs_vehicle_id", "vehicle_id"),
        Index("ix_fuel_logs_vehicle_date", "vehicle_id", "date"),
    )
