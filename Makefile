.PHONY: help setup start stop restart logs status backup gc clean

# Default target
help:
	@echo "Docker Registry Management Commands:"
	@echo ""
	@echo "Setup & Configuration:"
	@echo "  make setup             - Run initial setup (creates .env and auth)"
	@echo "  make generate-secrets  - Generate GitHub secrets for CI/CD"
	@echo ""
	@echo "Service Management:"
	@echo "  make start      - Start the registry services"
	@echo "  make stop       - Stop the registry services"
	@echo "  make restart    - Restart the registry services"
	@echo "  make ps         - Show running containers"
	@echo "  make status     - Show detailed status"
	@echo ""
	@echo "Logging & Monitoring:"
	@echo "  make logs          - View logs (all services)"
	@echo "  make logs-registry - View registry logs only"
	@echo "  make logs-caddy    - View caddy logs only"
	@echo ""
	@echo "Maintenance:"
	@echo "  make backup     - Create a backup of registry data"
	@echo "  make gc         - Run garbage collection"
	@echo "  make pull       - Pull latest Docker images"
	@echo "  make update     - Update and restart services"
	@echo "  make clean      - Stop and remove all containers"
	@echo "  make validate   - Validate compose configuration"
	@echo ""

setup:
	@./setup.sh

generate-secrets:
	@./scripts/generate-secrets.sh

start:
	@echo "Starting Docker Registry..."
	@docker compose up -d
	@echo "Services started. Use 'make logs' to view logs."

stop:
	@echo "Stopping Docker Registry..."
	@docker compose down

restart:
	@echo "Restarting Docker Registry..."
	@docker compose restart
	@echo "Services restarted."

logs:
	@docker compose logs -f --tail=100

logs-registry:
	@docker compose logs -f --tail=100 registry

logs-caddy:
	@docker compose logs -f --tail=100 caddy

status:
	@./scripts/status.sh

backup:
	@./scripts/backup.sh

gc:
	@./scripts/gc.sh

clean:
	@echo "Stopping and removing containers..."
	@docker compose down -v
	@echo "Cleanup complete."

pull:
	@echo "Pulling latest images..."
	@docker compose pull

update: pull
	@echo "Updating services..."
	@docker compose up -d
	@echo "Update complete."

ps:
	@docker compose ps

validate:
	@echo "Validating configuration..."
	@docker compose config --quiet && echo "✓ Configuration is valid" || echo "✗ Configuration has errors"
