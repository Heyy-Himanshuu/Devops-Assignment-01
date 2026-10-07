"""create expenses table"""

import sqlalchemy as sa
from alembic import op

revision = "0001_create_expenses"
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    op.create_table(
        "expenses",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("title", sa.String(length=200), nullable=False),
        sa.Column("amount", sa.Numeric(12, 2), nullable=False),
        sa.Column("category", sa.String(length=30), nullable=False, server_default="OTHER"),
        sa.Column("payment_method", sa.String(length=20), nullable=False, server_default="UPI"),
        sa.Column("spent_on", sa.Date(), nullable=False),
        sa.Column("notes", sa.Text(), nullable=False, server_default=""),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
    op.create_index("ix_expenses_spent_on", "expenses", ["spent_on"])


def downgrade():
    op.drop_index("ix_expenses_spent_on", table_name="expenses")
    op.drop_table("expenses")
