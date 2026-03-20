.PHONY: setup up down logs shell iex test drop check-env

# Colors for output
YELLOW := \033[0;33m
RED := \033[0;31m
GREEN := \033[0;32m
NC := \033[0m # No Color

help:
	@echo "$(YELLOW)Estratos — Docker Development Commands$(NC)"
	@echo ""
	@echo "$(GREEN)setup$(NC)       — Build images, install deps, create DB"
	@echo "$(GREEN)up$(NC)          — Start all services (docker compose up -d)"
	@echo "$(GREEN)down$(NC)        — Stop all services (docker compose down)"
	@echo "$(GREEN)logs$(NC)        — Tail logs (docker compose logs -f)"
	@echo "$(GREEN)shell$(NC)       — Open bash shell in app container"
	@echo "$(GREEN)iex$(NC)         — Open IEx console in app container"
	@echo "$(GREEN)test$(NC)        — Run tests in app container"
	@echo "$(GREEN)drop$(NC)        — Stop services and remove volumes"
	@echo "$(GREEN)check-env$(NC)   — Verify .env exists and is gitignored"

check-env:
	@if [ ! -f .env ]; then \
		echo "$(RED)✗ .env file not found$(NC)"; \
		exit 1; \
	fi
	@if ! grep -q "^.env$$" .gitignore; then \
		echo "$(RED)✗ .env not in .gitignore$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)✓ .env exists and is gitignored$(NC)"

setup: check-env
	@echo "$(YELLOW)Building Docker images...$(NC)"
	docker compose build
	@echo "$(YELLOW)Installing dependencies...$(NC)"
	docker compose run --rm app mix deps.get
	@echo "$(YELLOW)Creating database...$(NC)"
	docker compose run --rm app mix ecto.create
	@echo "$(YELLOW)Running migrations...$(NC)"
	docker compose run --rm app mix ecto.migrate
	@echo "$(GREEN)✓ Setup complete$(NC)"

up: check-env
	@echo "$(YELLOW)Starting services...$(NC)"
	docker compose up -d
	@echo "$(GREEN)✓ Services started$(NC)"
	@echo "   App:      http://localhost:4000"
	@echo "   Database: localhost:5432"

down:
	@echo "$(YELLOW)Stopping services...$(NC)"
	docker compose down
	@echo "$(GREEN)✓ Services stopped$(NC)"

logs:
	docker compose logs -f

shell:
	docker compose exec app bash

iex:
	docker compose exec app iex -S mix phx.server

test: check-env
	@echo "$(YELLOW)Running tests...$(NC)"
	docker compose run --rm app mix test

drop:
	@echo "$(RED)Dropping containers and volumes...$(NC)"
	docker compose down -v
	@echo "$(GREEN)✓ Cleaned up$(NC)"
