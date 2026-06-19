"""Add user_documents table, fcm_token to users, extend reminders.

Revision ID: g1001
Revises: f4001
Create Date: 2026-06-19
"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID

revision = "g1001"
down_revision = "f4001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 1. fcm_token on users
    op.add_column("users", sa.Column("fcm_token", sa.Text(), nullable=True))

    # 2. user_documents table
    op.create_table(
        "user_documents",
        sa.Column("id", UUID(as_uuid=True), primary_key=True, server_default=sa.text("gen_random_uuid()")),
        sa.Column("user_id", UUID(as_uuid=True), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("doc_type", sa.Text(), nullable=False),
        sa.Column("doc_number", sa.Text(), nullable=True),
        sa.Column("issue_date", sa.Date(), nullable=True),
        sa.Column("expiry_date", sa.Date(), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.TIMESTAMP(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.CheckConstraint("doc_type IN ('license','permit','international_license')", name="ck_user_documents_doc_type"),
    )
    op.create_index("ix_user_documents_user_id", "user_documents", ["user_id"])
    op.create_index("ix_user_documents_expiry_date", "user_documents", ["expiry_date"])

    # 3. Extend reminders: make vehicle_id nullable, add user_document_id FK
    op.alter_column("reminders", "vehicle_id", nullable=True)
    op.add_column(
        "reminders",
        sa.Column(
            "user_document_id",
            UUID(as_uuid=True),
            sa.ForeignKey("user_documents.id", ondelete="CASCADE"),
            nullable=True,
        ),
    )


def downgrade() -> None:
    op.drop_column("reminders", "user_document_id")
    op.alter_column("reminders", "vehicle_id", nullable=False)
    op.drop_index("ix_user_documents_expiry_date", table_name="user_documents")
    op.drop_index("ix_user_documents_user_id", table_name="user_documents")
    op.drop_table("user_documents")
    op.drop_column("users", "fcm_token")
