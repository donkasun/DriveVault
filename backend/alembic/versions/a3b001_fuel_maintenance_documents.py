"""A3b: fuel_logs, maintenance_records, documents tables.

Revision ID: a3b001
Revises: a3a001
Create Date: 2026-06-09
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

revision: str = "a3b001"
down_revision: Union[str, None] = "a3a001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "fuel_logs",
        sa.Column("id", sa.UUID(), server_default=sa.text("gen_random_uuid()"), nullable=False),
        sa.Column("vehicle_id", sa.UUID(), nullable=False),
        sa.Column("date", sa.Date(), nullable=False),
        sa.Column("liters", sa.Numeric(precision=8, scale=3), nullable=False),
        sa.Column("price_cents", sa.BigInteger(), nullable=False),
        sa.Column("currency", sa.CHAR(length=3), server_default="USD", nullable=False),
        sa.Column("odometer", sa.Integer(), nullable=False),
        sa.Column("is_full_tank", sa.Boolean(), server_default="true", nullable=False),
        sa.Column("notes", sa.Text(), nullable=True),
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
        sa.CheckConstraint("liters > 0", name="ck_fuel_logs_liters_positive"),
        sa.ForeignKeyConstraint(["vehicle_id"], ["vehicles.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_fuel_logs_vehicle_id", "fuel_logs", ["vehicle_id"], unique=False)
    op.create_index("ix_fuel_logs_vehicle_date", "fuel_logs", ["vehicle_id", "date"], unique=False)

    op.create_table(
        "maintenance_records",
        sa.Column("id", sa.UUID(), server_default=sa.text("gen_random_uuid()"), nullable=False),
        sa.Column("vehicle_id", sa.UUID(), nullable=False),
        sa.Column("date", sa.Date(), nullable=False),
        sa.Column("odometer", sa.Integer(), nullable=True),
        sa.Column("service_type", sa.Text(), nullable=False),
        sa.Column("category", sa.Text(), nullable=True),
        sa.Column("cost_cents", sa.BigInteger(), server_default="0", nullable=False),
        sa.Column("currency", sa.CHAR(length=3), server_default="USD", nullable=False),
        sa.Column("workshop", sa.Text(), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("source", sa.Text(), server_default="manual", nullable=False),
        sa.Column("ai_extraction_id", sa.UUID(), nullable=True),
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
        "ix_maintenance_vehicle_id", "maintenance_records", ["vehicle_id"], unique=False
    )
    op.create_index(
        "ix_maintenance_vehicle_date",
        "maintenance_records",
        ["vehicle_id", "date"],
        unique=False,
    )
    op.create_index(
        "ix_maintenance_category", "maintenance_records", ["category"], unique=False
    )

    op.create_table(
        "documents",
        sa.Column("id", sa.UUID(), server_default=sa.text("gen_random_uuid()"), nullable=False),
        sa.Column("vehicle_id", sa.UUID(), nullable=False),
        sa.Column("doc_type", sa.Text(), nullable=False),
        sa.Column("title", sa.Text(), nullable=False),
        sa.Column("storage_url", sa.Text(), nullable=False),
        sa.Column("storage_public_id", sa.Text(), nullable=True),
        sa.Column("mime_type", sa.Text(), nullable=True),
        sa.Column("file_size_bytes", sa.BigInteger(), nullable=True),
        sa.Column("issue_date", sa.Date(), nullable=True),
        sa.Column("expiry_date", sa.Date(), nullable=True),
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
    op.create_index("ix_documents_vehicle_id", "documents", ["vehicle_id"], unique=False)
    op.create_index("ix_documents_doc_type", "documents", ["doc_type"], unique=False)
    op.create_index("ix_documents_expiry_date", "documents", ["expiry_date"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_documents_expiry_date", table_name="documents")
    op.drop_index("ix_documents_doc_type", table_name="documents")
    op.drop_index("ix_documents_vehicle_id", table_name="documents")
    op.drop_table("documents")
    op.drop_index("ix_maintenance_category", table_name="maintenance_records")
    op.drop_index("ix_maintenance_vehicle_date", table_name="maintenance_records")
    op.drop_index("ix_maintenance_vehicle_id", table_name="maintenance_records")
    op.drop_table("maintenance_records")
    op.drop_index("ix_fuel_logs_vehicle_date", table_name="fuel_logs")
    op.drop_index("ix_fuel_logs_vehicle_id", table_name="fuel_logs")
    op.drop_table("fuel_logs")
