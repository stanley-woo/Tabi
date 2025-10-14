"""add email verification field

Revision ID: 4322f59c5016
Revises: 
Create Date: 2025-10-13 15:50:53.235133

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision: str = '4322f59c5016'
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Add is_email_verified column to user table
    op.add_column('user', sa.Column('is_email_verified', sa.Boolean(), nullable=False, server_default='false'))


def downgrade() -> None:
    """Downgrade schema."""
    # Remove is_email_verified column from user table
    op.drop_column('user', 'is_email_verified')
