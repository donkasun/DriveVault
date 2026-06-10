"""Dashboard aggregate data model (Task B6)."""

import uuid

from sqlalchemy import BigInteger, TIMESTAMP, Date, ForeignKey, Index, Integer, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.db import Base


class DashboardData(Base):
      __tablename__ = "dashboard_data"

      id: Mapped[uuid.UUID] = mapped_column(
          UUID(as_uuid=True), primary_key=True, server_default=func.gen_random_uuid()
       )
      user_id: Mapped[uuid.UUID] = mapped_column(
          UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
       )
      vehicle_count: Mapped[int | None] = mapped_column(Integer, nullable=True)
      monthly_fuel_spend_cents: Mapped[int | None] = mapped_column(
          BigInteger, nullable=True
       )
      total_ownership_cost_cents: Mapped[int | None] = mapped_column(
          BigInteger, nullable=True
       )
      fuel_cents: Mapped[int | None] = mapped_column(BigInteger, nullable=True)
      maintenance_cents: Mapped[int | None] = mapped_column(
          BigInteger, nullable=True
       )
      purchase_cents: Mapped[int | None] = mapped_column(
          BigInteger, nullable=True
       )
      created_at: Mapped[object] = mapped_column(
          TIMESTAMP(timezone=True), server_default=func.now(), nullable=False
       )
      updated_at: Mapped[object] = mapped_column(
          TIMESTAMP(timezone=True), server_default=func.now(), nullable=False
       )

      __table_args__ = (
         Index("ix_dashboard_user_id", "user_id"),
      )
