# KickAI — Sports Prediction Platform

![CI](https://github.com/qmxrlon/kickai/actions/workflows/ci.yml/badge.svg)

Self-hosted AI-powered sports analysis software. Users install it on their own server and subscribe to access ML-based match predictions.

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│    Nginx    │────▶│   Rails 8    │────▶│  Python FastAPI  │
│  (reverse   │     │ (Hotwire UI  │     │  (ML Engine)     │
│   proxy)    │     │  + Devise    │     │  XGBoost models  │
└─────────────┘     │  + Pay gem)  │     └─────────────────┘
                    └──────┬───────┘              │
                           │                      │
                    ┌──────▼───────┐     ┌────────▼────────┐
                    │  PostgreSQL  │     │     Redis        │
                    │  (data + DB) │     │  (Sidekiq queue) │
                    └─────────────┘     └─────────────────┘
                           │
                    ┌──────▼───────┐
                    │   Sidekiq    │
                    │ (background  │
                    │   jobs)      │
                    └─────────────┘
```

## Features

| Feature | Free | Basic | Premium |
|---|:---:|:---:|:---:|
| Match list & schedule | ✓ | ✓ | ✓ |
| 1X2 win probabilities | — | ✓ | ✓ |
| Over/Under predictions | — | ✓ | ✓ |
| BTTS analysis | — | ✓ | ✓ |
| Expected Goals (xG) | — | — | ✓ |
| Kelly stake calculator | — | — | ✓ |
| AI match analysis (DE) | — | — | ✓ |

## Quick Start

### Prerequisites
- Docker + Docker Compose v2
- 4 GB RAM minimum

### 1. Clone & configure

```bash
git clone <your-repo-url> kickai
cd kickai
./setup.sh
```

The setup script will:
1. Create `.env` from `.env.example`
2. Prompt you to fill in secrets
3. Build Docker images
4. Run database migrations & seed data

### 2. Fill in `.env`

```bash
# Generate secrets:
openssl rand -hex 64   # → SECRET_KEY_BASE
openssl rand -hex 16   # → RAILS_MASTER_KEY
openssl rand -hex 32   # → PYTHON_API_SECRET

# Get API key from https://www.football-data.org/
FOOTBALL_DATA_API_KEY=your_key_here
```

### 3. Start

```bash
docker compose up -d
```

Visit **http://localhost**

### 4. Fetch data & train models

```bash
make fetch-data        # Pulls match data from Football-Data.org
make train             # Trains ML models (needs ~500+ matches)
make generate-predictions  # Generates predictions for upcoming matches
```

## Subscription Plans

Configure Stripe prices in your Stripe dashboard and set:
```env
STRIPE_PRICE_BASIC=price_xxx
STRIPE_PRICE_PREMIUM=price_xxx
```

## Common Commands

```bash
make up             # Start all services
make down           # Stop all services
make logs           # Tail all logs
make console        # Rails console
make db-migrate     # Run migrations
make train          # Train ML models
make fetch-data     # Sync match data
```

## ML Model Details

The prediction engine uses **XGBoost** models trained on historical match data:

- **Outcome model** (1X2): Multi-class classifier on team form, H2H, goals per game, home advantage
- **BTTS model**: Binary classifier on team scoring/clean-sheet rates
- **Goals model**: Regressor for total expected goals (used for over/under thresholds via Poisson CDF)
- **xG models**: Separate regressors for home/away expected goals

Feature set: last-5 and last-10 game form, goals for/against averages, H2H record, days rest, league context.

Features for a match are computed only from matches played *before* it. Models are evaluated on a **chronological split** (oldest 80 % train, newest 20 % test), and the scaler is fitted on the training part only, so reported metrics are not inflated by future data.

Models are saved in a Docker volume (`ml_models`) and auto-loaded on service start.

## Development & tests

```bash
# Python ML engine
cd python
pip install -r requirements.txt pytest ruff
ruff check . && pytest

# Rails app (needs PostgreSQL)
cd rails
bundle install
bin/rails db:create db:schema:load RAILS_ENV=test
bundle exec rspec
```

GitHub Actions runs both suites on every push and pull request.

## Project structure

```
nginx/     reverse proxy config
rails/     web app: UI, auth (Devise), subscriptions (Pay/Stripe), admin, Sidekiq jobs
python/    FastAPI ML engine: scraper, feature engineering, XGBoost models
  app/scrapers/   Football-Data.org client with free-tier rate limiting
  app/services/   feature engineering, training, prediction, analysis text
  tests/          pytest suite
```

## Legal Notice (Germany)

This software does not accept bets, process wagers, or provide gambling services.  
It is purely analytical software providing statistical information.  
Users are responsible for compliance with local laws regarding sports betting information services.

---
Built with Rails 8, Python FastAPI, XGBoost, PostgreSQL, Redis, Sidekiq, Docker.
