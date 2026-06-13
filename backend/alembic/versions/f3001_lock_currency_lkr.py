"""Lock currency to LKR: defaults USD->LKR + backfill existing rows.

Revision ID: f3001
Revises: f2001
Create Date: 2026-06-13
"""

from typing import Sequence, Union

from alembic import op

revision: str = "f3001"
down_revision: Union[str, None] = "f2001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

_TABLES = ("users", "vehicles", "fuel_logs", "maintenance_records")


def upgrade() -> None:
    for table in _TABLES:
        op.alter_column(table, "currency", server_default="LKR")
        op.execute(f"UPDATE {table} SET currency = 'LKR'")


def downgrade() -> None:
    for table in _TABLES:
        op.alter_column(table, "currency", server_default="USD")
