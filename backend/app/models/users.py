"""users - mirrors a Firebase Auth account (Task A3a, docs/02-database-schema.md).

Created lazily on first authenticated request.
"""

import uuid

from sqlalchemy import Index, Text, TIMESTAMP, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.db import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, server_default=func.gen_random_uuid()
    )
    firebase_uid: Mapped[str] = mapped_column(Text, unique=True, nullable=False)
    email: Mapped[str] = mapped_column(Text, nullable=False)
    display_name: Mapped[str | None] = mapped_column(Text, nullable=True)
    photo_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[object] = mapped_column(  # type: ignore[assignment]
        TIMESTAMP(timezone=True), server_default=func.now(), nullable=False
    )
    updated_at: Mapped[object] = mapped_column(  # type: ignore[assignment]
        TIMESTAMP(timezone=True), server_default=func.now(), nullable=False
    )

    vehicles = relationship("Vehicle", back_populates="user")

    __table_args__ = (Index("ix_users_email", "email"),)
