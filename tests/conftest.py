import os

import psycopg2
import pytest


@pytest.fixture(scope="session")
def db_conn():
    conn = psycopg2.connect(
        host=os.getenv("DB_HOST", "localhost"),
        port=int(os.getenv("DB_PORT", "5432")),
        user=os.getenv("DB_USER", "harry"),
        password=os.getenv("DB_PASSWORD", "potter"),
        dbname=os.getenv("DB_NAME", "magic-shop"),
    )
    yield conn
    conn.close()


@pytest.fixture(autouse=True)
def rollback_after_test(db_conn):
    """Roll back after every test to keep the database clean."""
    yield
    db_conn.rollback()
