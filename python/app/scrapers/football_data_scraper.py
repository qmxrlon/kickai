"""
Football-Data.org Scraper
=========================
Fetches match data directly from the API and stores it in PostgreSQL.
This is the Python-side complement to the Rails FootballDataClient.
"""

import logging
import time
from datetime import UTC, datetime, timedelta

import httpx
from sqlalchemy import text

from app.config import settings
from app.database import SessionLocal

logger = logging.getLogger(__name__)

BASE_URL = "https://api.football-data.org/v4"

# Free tier: 10 requests/minute
FREE_TIER_DELAY = 6  # seconds between requests


class FootballDataScraper:
    def __init__(self):
        self.api_key  = settings.football_data_api_key
        self.headers  = {"X-Auth-Token": self.api_key}

    def sync_all(self, competition_id: str | None = None) -> int:
        """Sync matches for all active leagues (or a specific competition)."""
        competitions = self._active_competition_ids(competition_id)
        total = 0
        for comp_id in competitions:
            try:
                count = self._sync_competition(comp_id)
                total += count
                time.sleep(FREE_TIER_DELAY)
            except Exception as exc:
                logger.error("Failed to sync competition %s: %s", comp_id, exc)
        logger.info("Synced %d matches total.", total)
        return total

    def _sync_competition(self, competition_id: str) -> int:
        date_from = (datetime.now(UTC) - timedelta(days=90)).strftime("%Y-%m-%d")
        date_to   = (datetime.now(UTC) + timedelta(days=14)).strftime("%Y-%m-%d")

        url = f"{BASE_URL}/competitions/{competition_id}/matches"
        params = {
            "status":   "SCHEDULED,IN_PLAY,FINISHED",
            "dateFrom": date_from,
            "dateTo":   date_to,
        }

        with httpx.Client(headers=self.headers, timeout=20) as client:
            resp = client.get(url, params=params)

        if resp.status_code == 429:
            logger.warning("Rate limited for %s — sleeping 60s", competition_id)
            time.sleep(60)
            return 0
        resp.raise_for_status()

        matches = resp.json().get("matches", [])
        league_db_id = self._get_league_id(competition_id)
        if not league_db_id:
            logger.warning("League not found in DB for competition %s", competition_id)
            return 0

        upserted = 0
        for m in matches:
            try:
                self._upsert_match(m, league_db_id)
                upserted += 1
            except Exception as exc:
                logger.debug("Could not upsert match %s: %s", m.get("id"), exc)

        logger.info("Competition %s: %d/%d matches synced.", competition_id, upserted, len(matches))
        return upserted

    def _upsert_match(self, m: dict, league_db_id: int):
        ext_id  = str(m["id"])
        home_id = self._ensure_team(m["homeTeam"], league_db_id)
        away_id = self._ensure_team(m["awayTeam"], league_db_id)

        score_full = m.get("score", {}).get("fullTime", {})
        home_score = score_full.get("home")
        away_score = score_full.get("away")
        status     = self._map_status(m.get("status", "SCHEDULED"))
        utc_date   = m.get("utcDate")

        with SessionLocal() as db:
            db.execute(text("""
                INSERT INTO matches
                  (external_id, league_id, home_team_id, away_team_id,
                   scheduled_at, status, home_score, away_score, created_at, updated_at)
                VALUES
                  (:ext_id, :league_id, :home_id, :away_id,
                   :scheduled_at, :status, :home_score, :away_score, NOW(), NOW())
                ON CONFLICT (external_id)
                DO UPDATE SET
                  status       = EXCLUDED.status,
                  home_score   = EXCLUDED.home_score,
                  away_score   = EXCLUDED.away_score,
                  updated_at   = NOW()
            """), {
                "ext_id":       ext_id,
                "league_id":    league_db_id,
                "home_id":      home_id,
                "away_id":      away_id,
                "scheduled_at": utc_date,
                "status":       status,
                "home_score":   home_score,
                "away_score":   away_score,
            })
            db.commit()

    def _ensure_team(self, team_data: dict, league_db_id: int) -> int:
        ext_id = str(team_data["id"])
        name   = team_data.get("name", "Unknown")
        with SessionLocal() as db:
            row = db.execute(text(
                "SELECT id FROM teams WHERE external_id = :ext_id LIMIT 1"
            ), {"ext_id": ext_id}).first()
            if row:
                return row[0]
            result = db.execute(text("""
                INSERT INTO teams (external_id, name, league_id, created_at, updated_at)
                VALUES (:ext_id, :name, :league_id, NOW(), NOW())
                RETURNING id
            """), {"ext_id": ext_id, "name": name, "league_id": league_db_id})
            db.commit()
            return result.scalar_one()

    def _get_league_id(self, competition_id: str) -> int | None:
        with SessionLocal() as db:
            row = db.execute(text(
                "SELECT id FROM leagues WHERE external_id = :ext_id LIMIT 1"
            ), {"ext_id": competition_id}).first()
        return row[0] if row else None

    def _active_competition_ids(self, specific: str | None) -> list[str]:
        if specific:
            return [specific]
        with SessionLocal() as db:
            rows = db.execute(text(
                "SELECT external_id FROM leagues WHERE active = true AND external_id IS NOT NULL"
            )).all()
        return [r[0] for r in rows]

    @staticmethod
    def _map_status(api_status: str) -> int:
        mapping = {
            "TIMED":      0,
            "SCHEDULED":  0,
            "IN_PLAY":    1,
            "PAUSED":     1,
            "FINISHED":   2,
            "POSTPONED":  3,
            "CANCELLED":  4,
            "ABANDONED":  4,
        }
        return mapping.get(api_status.upper(), 0)
