# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- CI/CD pipeline with GitHub Actions: SQL linting (sqlfluff) then integration tests (pytest)
- Integration test suite (`tests/`) covering schema, seed data counts, constraints,
  referential integrity (cascade deletes), and all views
- 5 pre-built SQL views: `vw_order_summary`, `vw_sales_by_product`,
  `vw_sales_by_category`, `vw_customer_stats`, `vw_monthly_revenue`
- Indexes on all foreign keys and on `order_date` / `order_status`
- `Makefile` with `up`, `down`, `reset`, `wait`, `test`, `lint`, `psql` targets
- `.env.example` for local credential setup
- `.gitignore` for Python artefacts and `.env`
- `.sqlfluff` configuration file (postgres dialect, explicit aliases, consistent casing)
- `pyproject.toml` with pytest configuration and `[dependency-groups]` (test, lint)
- `uv.lock` for fully reproducible installs via `uv`
- `restart: unless-stopped` and `healthcheck` in `docker-compose.yml`

### Changed
- Split `db/init/init.sql` into `01_schema.sql` (DDL + views) and `02_seed.sql` (COPY)
- `tbl_customers.gender` type reduced from `VARCHAR(50)` to `VARCHAR(10)`
- `tbl_customers.gender` now enforced to `'Male'`, `'Female'`, `'Other'` via CHECK constraint
- Table aliases in views use explicit `AS` keyword
- README updated with seed data volume table, views documentation with example queries,
  CI badge, and a dedicated Testing section

## [1.0.0] - 2023-10-01

### Added
- Initial project setup with Docker and PostgreSQL 16
- 4 tables: `tbl_customers`, `tbl_products`, `tbl_orders`, `tbl_order_details`
- Seed data: 164 customers, 71 products, ~5 000 orders, ~12 400 order details
- CHECK constraints on `unit_price`, `quantity`, and `order_status`
- Foreign key relationships with `ON DELETE CASCADE`
