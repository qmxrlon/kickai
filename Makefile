.DEFAULT_GOAL := help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## First-time setup: build images, run migrations, seed DB
	@./setup.sh

up: ## Start all services
	docker compose up -d

down: ## Stop all services
	docker compose down

logs: ## Tail logs (all services)
	docker compose logs -f

rails-logs: ## Tail Rails logs only
	docker compose logs -f rails

python-logs: ## Tail Python API logs only
	docker compose logs -f python

sidekiq-logs: ## Tail Sidekiq logs only
	docker compose logs -f sidekiq

console: ## Open Rails console
	docker compose exec rails bundle exec rails console

shell: ## Open a bash shell in Rails container
	docker compose exec rails bash

python-shell: ## Open a Python shell
	docker compose exec python python

db-migrate: ## Run pending migrations
	docker compose exec rails bundle exec rails db:migrate

db-seed: ## Seed the database
	docker compose exec rails bundle exec rails db:seed

db-reset: ## ⚠ Drop, recreate, migrate and seed DB
	@echo "WARNING: This will delete all data. Press Ctrl+C to abort."
	@sleep 3
	docker compose exec rails bundle exec rails db:drop db:create db:migrate db:seed

train: ## Train ML models (uses data already in DB)
	docker compose exec python python ml/train.py

fetch-data: ## Manually trigger match data fetch
	docker compose exec rails bundle exec rails runner "FetchMatchesJob.perform_now"

generate-predictions: ## Manually generate predictions for upcoming matches
	docker compose exec rails bundle exec rails runner "GeneratePredictionsJob.perform_now"

build: ## Rebuild Docker images
	docker compose build

rebuild: ## Force rebuild Docker images (no cache)
	docker compose build --no-cache

ps: ## Show running containers
	docker compose ps

restart: ## Restart all services
	docker compose restart

restart-rails: ## Restart Rails only
	docker compose restart rails

stripe-listen: ## Start Stripe webhook listener (dev only — needs Stripe CLI)
	stripe listen --forward-to localhost:3000/pay/webhooks/stripe
