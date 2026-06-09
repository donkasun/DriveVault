"""Pytest fixtures for database-backed tests."""

from __future__ import annotations

import os
from collections.abc import Generator

import pytest
from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import get_settings

ALEMBIC_INI = os.path.join(os.path.dirname(__file__), "..", "alembic.ini")
TEST_DB_NAME = "drivevault_test"


def _admin_url() -> str:
    settings = get_settings()
    base = settings.database_url.rsplit("/", 1)[0]
    return f"{base}/postgres"


def _test_database_url() -> str:
    settings = get_settings()
    base = settings.database_url.rsplit("/", 1)[0]
    return f"{base}/{TEST_DB_NAME}"


def _ensure_test_database() -> None:
    admin_engine = create_engine(_admin_url(), isolation_level="AUTOCOMMIT")
    with admin_engine.connect() as conn:
        exists = conn.execute(
            text("SELECT 1 FROM pg_database WHERE datname = :name"),
            {"name": TEST_DB_NAME},
        ).scalar()
        if not exists:
            try:
                conn.execute(text(f'CREATE DATABASE "{TEST_DB_NAME}"'))
            except Exception:
                # Another pytest worker may have created it concurrently.
                exists = conn.execute(
                    text("SELECT 1 FROM pg_database WHERE datname = :name"),
                    {"name": TEST_DB_NAME},
                ).scalar()
                if not exists:
                    raise
    admin_engine.dispose()


@pytest.fixture(scope="session")
def migrated_engine() -> Generator[Engine, None, None]:
    """Fresh test database migrated to head."""
    get_settings.cache_clear()
    _ensure_test_database()

    test_url = _test_database_url()
    os.environ["DATABASE_URL"] = test_url
    get_settings.cache_clear()

    engine = create_engine(test_url, pool_pre_ping=True, future=True)

    with engine.connect() as conn:
        conn.execute(text("DROP SCHEMA public CASCADE"))
        conn.execute(text("CREATE SCHEMA public"))
        conn.commit()

    alembic_cfg = Config(ALEMBIC_INI)
    alembic_cfg.set_main_option("sqlalchemy.url", test_url)
    command.upgrade(alembic_cfg, "head")

    yield engine
    engine.dispose()


@pytest.fixture
def db_session(migrated_engine: Engine) -> Generator[Session, None, None]:
    connection = migrated_engine.connect()
    transaction = connection.begin()
    # Bug 4 fix: join_transaction_mode="create_savepoint" ensures that db.commit()
    # calls inside the code-under-test only commit to a savepoint, not the outer
    # connection transaction.  The outer transaction.rollback() then undoes all
    # changes made during the test, providing proper test isolation.
    session = sessionmaker(
        bind=connection,
        autoflush=False,
        autocommit=False,
        future=True,
        join_transaction_mode="create_savepoint",
    )()
    try:
        yield session
    finally:
        session.close()
        transaction.rollback()
        connection.close()
