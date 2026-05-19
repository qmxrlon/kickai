#!/usr/bin/env bash
set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}▶${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC}  $*"; }
err()  { echo -e "${RED}✗${NC}  $*"; exit 1; }

echo -e "${BOLD}"
echo "  ██╗  ██╗██╗ ██████╗██╗  ██╗ █████╗ ██╗"
echo "  ██║ ██╔╝██║██╔════╝██║ ██╔╝██╔══██╗██║"
echo "  █████╔╝ ██║██║     █████╔╝ ███████║██║"
echo "  ██╔═██╗ ██║██║     ██╔═██╗ ██╔══██║██║"
echo "  ██║  ██╗██║╚██████╗██║  ██╗██║  ██║██║"
echo "  ╚═╝  ╚═╝╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝"
echo -e "${NC}"
echo "Sports Prediction Platform — Setup"
echo "==================================="
echo ""

# ── Prerequisites ────────────────────────────────────────────────────────────
command -v docker  >/dev/null 2>&1 || err "Docker is not installed. See https://docs.docker.com/get-docker/"
docker compose version >/dev/null 2>&1 || err "Docker Compose v2 is required. Update Docker Desktop or install the plugin."

log "Prerequisites OK"

# ── .env ─────────────────────────────────────────────────────────────────────
if [ ! -f .env ]; then
  cp .env.example .env
  warn ".env created from .env.example"
  warn "Please fill in your secrets in .env, then re-run this script."
  exit 0
fi

# Check mandatory secrets
source .env
[[ -z "${POSTGRES_PASSWORD:-}" ]] && err "POSTGRES_PASSWORD must be set in .env"
[[ -z "${SECRET_KEY_BASE:-}"   ]] && err "SECRET_KEY_BASE must be set in .env  (generate: openssl rand -hex 64)"
[[ -z "${RAILS_MASTER_KEY:-}"  ]] && err "RAILS_MASTER_KEY must be set in .env (generate: openssl rand -hex 16)"
[[ -z "${PYTHON_API_SECRET:-}" ]] && err "PYTHON_API_SECRET must be set in .env (generate: openssl rand -hex 32)"

log "Environment validated"

# ── Build images ─────────────────────────────────────────────────────────────
log "Building Docker images (this may take a few minutes on first run)…"
docker compose build

# ── Start DB + Redis ─────────────────────────────────────────────────────────
log "Starting database and Redis…"
docker compose up -d db redis

log "Waiting for database to be ready…"
until docker compose exec db pg_isready -U "${POSTGRES_USER:-kickai}" -q; do
  sleep 2
done

# ── Database setup ───────────────────────────────────────────────────────────
log "Creating database and running migrations…"
docker compose run --rm rails bundle exec rails db:create db:migrate

log "Seeding database (sports, leagues, subscription plans)…"
docker compose run --rm rails bundle exec rails db:seed

# ── Start all services ───────────────────────────────────────────────────────
log "Starting all services…"
docker compose up -d

echo ""
echo -e "${GREEN}${BOLD}✅  KickAI is running!${NC}"
echo ""
echo "  Web interface  →  http://localhost:${HTTP_PORT:-80}"
echo "  Rails API      →  http://localhost:3000  (internal)"
echo "  Python API     →  http://localhost:8000  (internal)"
echo ""
echo "  To fetch initial match data:  make fetch-data"
echo "  To train ML models:           make train"
echo "  To view logs:                 make logs"
echo ""
