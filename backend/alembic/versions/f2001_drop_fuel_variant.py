"""F2: drop fuel_variant columns from fuel_logs and vehicles.

Revision ID: f2001
Revises: f1001
Create Date: 2026-06-11

Removes:
  - vehicles.default_fuel_variant (nullable text)
  - fuel_logs.fuel_variant (nullable text)

These columns were added in f1001 but are no longer part of the domain model.
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "f2001"
down_revision: Union[str, None] = "f1001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.drop_column("fuel_logs", "fuel_variant")
    op.drop_column("vehicles", "default_fuel_variant")


def downgrade() -> None:
    op.add_column("vehicles", sa.Column("default_fuel_variant", sa.Text(), nullable=True))
    op.add_column("fuel_logs", sa.Column("fuel_variant", sa.Text(), nullable=True))
