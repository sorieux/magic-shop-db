import psycopg2.errors
import pytest


# ---------------------------------------------------------------------------
# Schema
# ---------------------------------------------------------------------------


class TestTables:
    EXPECTED_TABLES = [
        "tbl_customers",
        "tbl_products",
        "tbl_orders",
        "tbl_order_details",
    ]

    def test_all_tables_exist(self, db_conn):
        with db_conn.cursor() as cur:
            cur.execute(
                """
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
                """
            )
            tables = {row[0] for row in cur.fetchall()}

        for table in self.EXPECTED_TABLES:
            assert table in tables, f"Table {table!r} is missing"


class TestIndexes:
    EXPECTED_INDEXES = [
        "idx_orders_customer_id",
        "idx_order_details_order_id",
        "idx_order_details_product_id",
        "idx_orders_order_date",
        "idx_orders_order_status",
    ]

    def test_all_indexes_exist(self, db_conn):
        with db_conn.cursor() as cur:
            cur.execute(
                "SELECT indexname FROM pg_indexes WHERE schemaname = 'public'"
            )
            indexes = {row[0] for row in cur.fetchall()}

        for idx in self.EXPECTED_INDEXES:
            assert idx in indexes, f"Index {idx!r} is missing"


# ---------------------------------------------------------------------------
# Seed data
# ---------------------------------------------------------------------------


class TestSeedData:
    @pytest.mark.parametrize(
        "table, min_rows",
        [
            ("tbl_customers", 160),
            ("tbl_products", 70),
            ("tbl_orders", 4_500),
            ("tbl_order_details", 12_000),
        ],
    )
    def test_row_counts(self, db_conn, table, min_rows):
        with db_conn.cursor() as cur:
            cur.execute(f"SELECT COUNT(*) FROM {table}")  # noqa: S608
            count = cur.fetchone()[0]
        assert count >= min_rows, f"{table} has {count} rows, expected >= {min_rows}"


# ---------------------------------------------------------------------------
# Constraints
# ---------------------------------------------------------------------------


class TestConstraints:
    def test_gender_rejects_unknown_value(self, db_conn):
        with db_conn.cursor() as cur:
            cur.execute("SAVEPOINT sp")
            with pytest.raises(psycopg2.errors.CheckViolation):
                cur.execute(
                    "INSERT INTO tbl_customers (name, gender) VALUES ('X', 'Unknown')"
                )
            cur.execute("ROLLBACK TO SAVEPOINT sp")

    @pytest.mark.parametrize("gender", ["Male", "Female", "Other"])
    def test_gender_accepts_valid_values(self, db_conn, gender):
        with db_conn.cursor() as cur:
            cur.execute(
                "INSERT INTO tbl_customers (name, gender) VALUES (%s, %s)",
                (f"Test {gender}", gender),
            )

    def test_unit_price_rejects_negative(self, db_conn):
        with db_conn.cursor() as cur:
            cur.execute("SAVEPOINT sp")
            with pytest.raises(psycopg2.errors.CheckViolation):
                cur.execute(
                    "INSERT INTO tbl_products (product_name, category, unit_price)"
                    " VALUES ('X', 'Y', -0.01)"
                )
            cur.execute("ROLLBACK TO SAVEPOINT sp")

    def test_quantity_rejects_zero(self, db_conn):
        with db_conn.cursor() as cur:
            cur.execute("SELECT order_id FROM tbl_orders LIMIT 1")
            order_id = cur.fetchone()[0]
            cur.execute("SELECT product_id FROM tbl_products LIMIT 1")
            product_id = cur.fetchone()[0]

            cur.execute("SAVEPOINT sp")
            with pytest.raises(psycopg2.errors.CheckViolation):
                cur.execute(
                    "INSERT INTO tbl_order_details (order_id, product_id, quantity)"
                    " VALUES (%s, %s, 0)",
                    (order_id, product_id),
                )
            cur.execute("ROLLBACK TO SAVEPOINT sp")

    def test_order_status_rejects_invalid_value(self, db_conn):
        with db_conn.cursor() as cur:
            cur.execute("SELECT customer_id FROM tbl_customers LIMIT 1")
            customer_id = cur.fetchone()[0]

            cur.execute("SAVEPOINT sp")
            with pytest.raises(psycopg2.errors.CheckViolation):
                cur.execute(
                    "INSERT INTO tbl_orders (customer_id, order_date, order_status)"
                    " VALUES (%s, '2021-01-01', 'shipped')",
                    (customer_id,),
                )
            cur.execute("ROLLBACK TO SAVEPOINT sp")

    @pytest.mark.parametrize("status", ["pending", "completed", "canceled"])
    def test_order_status_accepts_valid_values(self, db_conn, status):
        with db_conn.cursor() as cur:
            cur.execute("SELECT customer_id FROM tbl_customers LIMIT 1")
            customer_id = cur.fetchone()[0]
            cur.execute(
                "INSERT INTO tbl_orders (customer_id, order_date, order_status)"
                " VALUES (%s, '2021-01-01', %s)",
                (customer_id, status),
            )


# ---------------------------------------------------------------------------
# Referential integrity
# ---------------------------------------------------------------------------


class TestReferentialIntegrity:
    def test_cascade_delete_customer_removes_orders(self, db_conn):
        with db_conn.cursor() as cur:
            cur.execute(
                "INSERT INTO tbl_customers (name, gender)"
                " VALUES ('Temp', 'Other') RETURNING customer_id"
            )
            customer_id = cur.fetchone()[0]

            cur.execute(
                "INSERT INTO tbl_orders (customer_id, order_date, order_status)"
                " VALUES (%s, '2021-06-01', 'pending') RETURNING order_id",
                (customer_id,),
            )
            order_id = cur.fetchone()[0]

            cur.execute(
                "DELETE FROM tbl_customers WHERE customer_id = %s", (customer_id,)
            )

            cur.execute(
                "SELECT COUNT(*) FROM tbl_orders WHERE order_id = %s", (order_id,)
            )
            assert cur.fetchone()[0] == 0

    def test_cascade_delete_order_removes_order_details(self, db_conn):
        with db_conn.cursor() as cur:
            cur.execute(
                "INSERT INTO tbl_customers (name, gender)"
                " VALUES ('Temp', 'Other') RETURNING customer_id"
            )
            customer_id = cur.fetchone()[0]

            cur.execute(
                "INSERT INTO tbl_orders (customer_id, order_date, order_status)"
                " VALUES (%s, '2021-06-01', 'pending') RETURNING order_id",
                (customer_id,),
            )
            order_id = cur.fetchone()[0]

            cur.execute("SELECT product_id FROM tbl_products LIMIT 1")
            product_id = cur.fetchone()[0]

            cur.execute(
                "INSERT INTO tbl_order_details (order_id, product_id, quantity)"
                " VALUES (%s, %s, 2) RETURNING order_detail_id",
                (order_id, product_id),
            )
            detail_id = cur.fetchone()[0]

            cur.execute("DELETE FROM tbl_orders WHERE order_id = %s", (order_id,))

            cur.execute(
                "SELECT COUNT(*) FROM tbl_order_details WHERE order_detail_id = %s",
                (detail_id,),
            )
            assert cur.fetchone()[0] == 0


# ---------------------------------------------------------------------------
# Views
# ---------------------------------------------------------------------------


class TestViews:
    EXPECTED_VIEWS = [
        "vw_order_summary",
        "vw_sales_by_product",
        "vw_sales_by_category",
        "vw_customer_stats",
        "vw_monthly_revenue",
    ]

    def test_all_views_exist(self, db_conn):
        with db_conn.cursor() as cur:
            cur.execute(
                "SELECT table_name FROM information_schema.views"
                " WHERE table_schema = 'public'"
            )
            views = {row[0] for row in cur.fetchall()}

        for view in self.EXPECTED_VIEWS:
            assert view in views, f"View {view!r} is missing"

    @pytest.mark.parametrize(
        "view",
        [
            "vw_order_summary",
            "vw_sales_by_product",
            "vw_sales_by_category",
            "vw_customer_stats",
            "vw_monthly_revenue",
        ],
    )
    def test_view_returns_data(self, db_conn, view):
        with db_conn.cursor() as cur:
            cur.execute(f"SELECT COUNT(*) FROM {view}")  # noqa: S608
            assert cur.fetchone()[0] > 0, f"{view} returned no rows"

    def test_vw_order_summary_columns(self, db_conn):
        with db_conn.cursor() as cur:
            cur.execute("SELECT * FROM vw_order_summary LIMIT 1")
            col_names = {desc[0] for desc in cur.description}
        expected = {
            "order_id",
            "customer_name",
            "gender",
            "order_date",
            "order_status",
            "item_count",
            "total_amount",
        }
        assert expected <= col_names

    def test_vw_customer_stats_total_spent_non_negative(self, db_conn):
        with db_conn.cursor() as cur:
            cur.execute("SELECT MIN(total_spent) FROM vw_customer_stats")
            assert cur.fetchone()[0] >= 0

    def test_vw_monthly_revenue_positive(self, db_conn):
        with db_conn.cursor() as cur:
            cur.execute("SELECT MIN(revenue) FROM vw_monthly_revenue")
            assert cur.fetchone()[0] > 0

    def test_vw_monthly_revenue_columns(self, db_conn):
        with db_conn.cursor() as cur:
            cur.execute("SELECT * FROM vw_monthly_revenue LIMIT 1")
            col_names = {desc[0] for desc in cur.description}
        assert {"revenue_month", "order_count", "revenue"} <= col_names
