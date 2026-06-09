"""A3c: maintenance_schedules and reminders tables.

Revision ID: a3c001
Revises: a3b001
Create Date: 2026-06-09
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "a3c001"
down_revision: Union[str, None] = "a3b001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "maintenance_schedules",
        sa.Column("id", sa.UUID(), server_default=sa.text("gen_random_uuid()"), nullable=False),
        sa.Column("vehicle_id", sa.UUID(), nullable=False),
        sa.Column("service_type", sa.Text(), nullable=False),
        sa.Column("interval_months", sa.Integer(), nullable=True),
        sa.Column("interval_km", sa.Integer(), nullable=True),
        sa.Column("last_service_date", sa.Date(), nullable=True),
        sa.Column("last_service_odometer", sa.Integer(), nullable=True),
        sa.Column("is_active", sa.Boolean(), server_default="true", nullable=False),
        sa.Column(
            "created_at",
            sa.TIMESTAMP(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.TIMESTAMP(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["vehicle_id"], ["vehicles.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(
        "ix_schedules_vehicle_id", "maintenance_schedules", ["vehicle_id"], unique=False
    )

    op.create_table(
        "reminders",
        sa.Column("id", sa.UUID(), server_default=sa.text("gen_random_uuid()"), nullable=False),
        sa.Column("vehicle_id", sa.UUID(), nullable=False),
        sa.Column("schedule_id", sa.UUID(), nullable=True),
        sa.Column("document_id", sa.UUID(), nullable=True),
        sa.Column("reminder_type", sa.Text(), nullable=False),
        sa.Column("title", sa.Text(), nullable=False),
        sa.Column("due_date", sa.Date(), nullable=True),
        sa.Column("due_odometer", sa.Integer(), nullable=True),
        sa.Column("status", sa.Text(), server_default="pending", nullable=False),
        sa.Column(
            "created_at",
            sa.TIMESTAMP(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.TIMESTAMP(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["document_id"], ["documents.id"]),
        sa.ForeignKeyConstraint(["schedule_id"], ["maintenance_schedules.id"]),
        sa.ForeignKeyConstraint(["vehicle_id"], ["vehicles.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_reminders_vehicle_id", "reminders", ["vehicle_id"], unique=False)
    op.create_index("ix_reminders_status", "reminders", ["status"], unique=False)
    op.create_index("ix_reminders_due_date", "reminders", ["due_date"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_reminders_due_date", table_name="reminders")
    op.drop_index("ix_reminders_status", table_name="reminders")
    op.drop_index("ix_reminders_vehicle_id", table_name="reminders")
    op.drop_table("reminders")
    op.drop_index("ix_schedules_vehicle_id", table_name="maintenance_schedules")
    op.drop_table("maintenance_schedules")
