"""B6: Dashboard aggregate endpoint data model.

Revision ID: b6001
Revises: a3a001_users_vehicles
Create Date: 2026-06-10

This migration adds the dashboard_data table to support the aggregated
dashboard endpoint that summarizes all vehicles owned by a user.
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "b6001"
down_revision: Union[str, None] = "a3c001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
      # Create dashboard_data table for aggregated statistics
    op.create_table(
         "dashboard_data",
        sa.Column("id", sa.UUID(), server_default=sa.text("gen_random_uuid()"), nullable=False),
        sa.Column("user_id", sa.UUID(), nullable=False),
        sa.Column("vehicle_count", sa.Integer(), nullable=True),
        sa.Column("monthly_fuel_spend_cents", sa.BigInteger(), nullable=True),
        sa.Column("total_ownership_cost_cents", sa.BigInteger(), nullable=True),
        sa.Column("fuel_cents", sa.BigInteger(), nullable=True),
        sa.Column("maintenance_cents", sa.BigInteger(), nullable=True),
        sa.Column("purchase_cents", sa.BigInteger(), nullable=True),
        sa.Column("created_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
     )

    op.create_index("ix_dashboard_user_id", "dashboard_data", ["user_id"])


def downgrade() -> None:
      # Drop the dashboard_data table
    op.drop_table("dashboard_data")
