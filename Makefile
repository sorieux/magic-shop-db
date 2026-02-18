.PHONY: up down reset wait test lint psql help

DB_HOST   ?= localhost
DB_PORT   ?= 5432
DB_USER   ?= harry
DB_PASSWORD ?= potter
DB_NAME   ?= magic-shop

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-12s\033[0m %s\n", $$1, $$2}'

up: ## Start the database container in the background
	docker compose up -d

down: ## Stop the database container
	docker compose down

reset: ## Wipe all data and restart from scratch
	docker compose down -v
	docker compose up -d

wait: ## Wait until the database is ready to accept connections
	@echo "Waiting for database..."
	@timeout 60 bash -c \
		'until docker compose exec -T db pg_isready -U $(DB_USER) -d $(DB_NAME) -q; do sleep 2; done'
	@echo "Database is ready."

test: up wait ## Run the integration test suite
	pip install -q -r requirements-test.txt
	DB_HOST=$(DB_HOST) DB_PORT=$(DB_PORT) DB_USER=$(DB_USER) \
	DB_PASSWORD=$(DB_PASSWORD) DB_NAME=$(DB_NAME) \
	pytest tests/ -v

lint: ## Lint the SQL schema file
	sqlfluff lint db/init/01_schema.sql

psql: ## Open a psql session inside the running container
	docker compose exec db psql -U $(DB_USER) -d $(DB_NAME)
