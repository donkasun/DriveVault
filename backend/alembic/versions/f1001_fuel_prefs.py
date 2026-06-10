"""F1: fuel variant + user/vehicle preferences (docs/07-fuel-prefs-tasks.md).

Revision ID: f1001
Revises: b6001
Create Date: 2026-06-10

Adds:
  - users.currency (char(3), default 'USD'), users.distance_unit (text, default 'km')
  - vehicles.fuel_type, vehicles.default_fuel_variant, vehicles.distance_unit (all nullable)
  - fuel_logs.fuel_variant (nullable)

Distance unit is display-only; odometer/mileage stays stored in kilometres.
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "f1001"
down_revision: Union[str, None] = "b6001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # users: account-wide preferences (NOT NULL with server defaults so existing rows backfill)
    op.add_column(
        "users",
        sa.Column("currency", sa.CHAR(length=3), server_default="USD", nullable=False),
    )
    op.add_column(
        "users",
        sa.Column("distance_unit", sa.Text(), server_default="km", nullable=False),
    )

    # vehicles: fuel type (fixed per vehicle) + usual variant + per-vehicle unit override
    op.add_column("vehicles", sa.Column("fuel_type", sa.Text(), nullable=True))
    op.add_column("vehicles", sa.Column("default_fuel_variant", sa.Text(), nullable=True))
    op.add_column("vehicles", sa.Column("distance_unit", sa.Text(), nullable=True))

    # fuel_logs: variant for this fill-up
    op.add_column("fuel_logs", sa.Column("fuel_variant", sa.Text(), nullable=True))


def downgrade() -> None:
    op.drop_column("fuel_logs", "fuel_variant")
    op.drop_column("vehicles", "distance_unit")
    op.drop_column("vehicles", "default_fuel_variant")
    op.drop_column("vehicles", "fuel_type")
    op.drop_column("users", "distance_unit")
    op.drop_column("users", "currency")
