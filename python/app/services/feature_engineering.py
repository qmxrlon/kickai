"""
Feature Engineering
===================
Builds feature vectors from historical match data stored in PostgreSQL.

Feature set (per match):
  Home team:   form (W/D/L last 5 & 10), goals scored/conceded avg, home record, xG avg
  Away team:   same metrics for away games
  H2H:         last 5 H2H results, goal diff
  Match meta:  days since last game (home/away), league position (if available)
  Elo ratings: home and away Elo (computed from full history)
"""

import logging
from datetime import datetime

import numpy as np
import pandas as pd
from sqlalchemy import text

from app.database import SessionLocal

logger = logging.getLogger(__name__)

FORM_WINDOW_SHORT = 5
FORM_WINDOW_LONG  = 10


class FeatureEngineer:
    def __init__(self):
        self._match_cache: pd.DataFrame | None = None

    # ── Training data preparation ────────────────────────────────────────────

    def prepare_training_data(self, df: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame]:
        """
        Given a DataFrame of historical finished matches, build (X, labels).

        df columns expected:
          match_id, scheduled_at, home_team_id, away_team_id, league_id,
          home_score, away_score, [xg_home, xg_away]
        """
        df = df.copy().sort_values("scheduled_at").reset_index(drop=True)
        feature_rows = []
        label_rows   = []

        for idx, row in df.iterrows():
            if idx < 20:
                continue  # need history

            history = df.iloc[:idx]
            feats = self._compute_features(row, history)
            if feats is None:
                continue

            outcome = self._encode_outcome(row["home_score"], row["away_score"])
            btts    = int(row["home_score"] > 0 and row["away_score"] > 0)
            total   = row["home_score"] + row["away_score"]

            feature_rows.append(feats)
            label_row = {"outcome": outcome, "btts": btts, "total_goals": total}
            if "xg_home" in row and pd.notna(row.get("xg_home")):
                label_row["xg_home"] = row["xg_home"]
                label_row["xg_away"] = row["xg_away"]
            label_rows.append(label_row)

        X      = pd.DataFrame(feature_rows)
        labels = pd.DataFrame(label_rows)
        logger.info("Feature matrix: %d rows × %d cols", len(X), len(X.columns))
        return X, labels

    def build_features_for_match(
        self,
        home_team_id: str | None,
        away_team_id: str | None,
        league_id: str | None,
        scheduled_at: datetime,
    ) -> np.ndarray:
        """Build a single feature vector for an upcoming match."""
        df = self._load_all_matches()

        history = df[df["scheduled_at"] < scheduled_at]

        # Create a mock row
        mock = pd.Series({
            "home_team_id": home_team_id,
            "away_team_id": away_team_id,
            "league_id":    league_id,
            "scheduled_at": scheduled_at,
        })

        feats = self._compute_features(mock, history)
        if feats is None:
            logger.warning("Insufficient history for teams %s vs %s — using fallback zeros", home_team_id, away_team_id)
            feats = {k: 0.0 for k in self._feature_names()}

        return np.array(list(feats.values()), dtype=np.float32)

    # ── Internal ─────────────────────────────────────────────────────────────

    def _compute_features(self, row: pd.Series, history: pd.DataFrame) -> dict | None:
        home_id = str(row["home_team_id"])
        away_id = str(row["away_team_id"])

        home_hist = self._team_matches(history, home_id)
        away_hist = self._team_matches(history, away_id)

        if len(home_hist) < 5 or len(away_hist) < 5:
            return None

        feats = {}

        # Home team stats
        feats.update(self._team_features(home_hist, home_id, prefix="home_"))
        # Away team stats
        feats.update(self._team_features(away_hist, away_id, prefix="away_"))

        # H2H
        h2h = self._h2h_matches(history, home_id, away_id)
        feats.update(self._h2h_features(h2h, home_id))

        # Days rest
        feats["home_days_rest"] = self._days_rest(home_hist, row["scheduled_at"])
        feats["away_days_rest"] = self._days_rest(away_hist, row["scheduled_at"])

        return feats

    def _team_features(self, matches: pd.DataFrame, team_id: str, prefix: str) -> dict:
        recent_5  = matches.tail(FORM_WINDOW_SHORT)
        recent_10 = matches.tail(FORM_WINDOW_LONG)

        def outcomes(df):
            wins, draws, losses = 0, 0, 0
            goals_for, goals_against = [], []
            for _, m in df.iterrows():
                is_home = str(m["home_team_id"]) == team_id
                gf = m["home_score"] if is_home else m["away_score"]
                ga = m["away_score"] if is_home else m["home_score"]
                goals_for.append(gf)
                goals_against.append(ga)
                if gf > ga:   wins   += 1
                elif gf == ga: draws  += 1
                else:          losses += 1
            return wins, draws, losses, goals_for, goals_against

        w5, d5, l5, gf5, ga5   = outcomes(recent_5)
        w10, d10, l10, gf10, ga10 = outcomes(recent_10)
        n5, n10 = max(len(recent_5), 1), max(len(recent_10), 1)

        return {
            f"{prefix}win_rate_5":    w5 / n5,
            f"{prefix}draw_rate_5":   d5 / n5,
            f"{prefix}loss_rate_5":   l5 / n5,
            f"{prefix}goals_for_avg_5":    np.mean(gf5) if gf5 else 0.0,
            f"{prefix}goals_against_avg_5": np.mean(ga5) if ga5 else 0.0,
            f"{prefix}win_rate_10":   w10 / n10,
            f"{prefix}goals_for_avg_10":   np.mean(gf10) if gf10 else 0.0,
            f"{prefix}goals_against_avg_10": np.mean(ga10) if ga10 else 0.0,
            f"{prefix}form_pts":      (w5 * 3 + d5) / (n5 * 3),   # normalised form
        }

    def _h2h_features(self, h2h: pd.DataFrame, home_id: str) -> dict:
        if h2h.empty:
            return {"h2h_home_wins": 0.0, "h2h_draws": 0.0, "h2h_away_wins": 0.0, "h2h_goal_diff": 0.0}

        home_wins, draws, away_wins = 0, 0, 0
        goal_diff = 0
        for _, m in h2h.iterrows():
            if str(m["home_team_id"]) == home_id:
                gd = m["home_score"] - m["away_score"]
            else:
                gd = m["away_score"] - m["home_score"]
            goal_diff += gd
            if gd > 0:   home_wins += 1
            elif gd == 0: draws    += 1
            else:         away_wins += 1
        n = max(len(h2h), 1)
        return {
            "h2h_home_wins": home_wins / n,
            "h2h_draws":     draws     / n,
            "h2h_away_wins": away_wins / n,
            "h2h_goal_diff": goal_diff / n,
        }

    @staticmethod
    def _team_matches(history: pd.DataFrame, team_id: str) -> pd.DataFrame:
        mask = (history["home_team_id"].astype(str) == team_id) | \
               (history["away_team_id"].astype(str) == team_id)
        return history[mask].sort_values("scheduled_at")

    @staticmethod
    def _h2h_matches(history: pd.DataFrame, home_id: str, away_id: str) -> pd.DataFrame:
        mask = (
            ((history["home_team_id"].astype(str) == home_id) & (history["away_team_id"].astype(str) == away_id)) |
            ((history["home_team_id"].astype(str) == away_id) & (history["away_team_id"].astype(str) == home_id))
        )
        return history[mask].tail(5)

    @staticmethod
    def _days_rest(matches: pd.DataFrame, match_date: datetime) -> float:
        if matches.empty:
            return 7.0
        last = matches.iloc[-1]["scheduled_at"]
        delta = (match_date - pd.Timestamp(last)).days
        return float(np.clip(delta, 0, 30))

    @staticmethod
    def _encode_outcome(home_score: int, away_score: int) -> int:
        if home_score > away_score:  return 0  # home win
        if home_score == away_score: return 1  # draw
        return 2                                # away win

    def _load_all_matches(self) -> pd.DataFrame:
        if self._match_cache is not None:
            return self._match_cache
        self._match_cache = _fetch_matches_from_db()
        return self._match_cache

    @staticmethod
    def _feature_names() -> list[str]:
        prefixes = ["home_", "away_"]
        names = []
        for p in prefixes:
            names += [
                f"{p}win_rate_5", f"{p}draw_rate_5", f"{p}loss_rate_5",
                f"{p}goals_for_avg_5", f"{p}goals_against_avg_5",
                f"{p}win_rate_10", f"{p}goals_for_avg_10", f"{p}goals_against_avg_10",
                f"{p}form_pts",
            ]
        names += ["h2h_home_wins", "h2h_draws", "h2h_away_wins", "h2h_goal_diff",
                  "home_days_rest", "away_days_rest"]
        return names


def _fetch_matches_from_db() -> pd.DataFrame:
    """Load finished matches from PostgreSQL into a DataFrame."""
    query = text("""
        SELECT
            m.id           AS match_id,
            m.scheduled_at,
            m.home_team_id,
            m.away_team_id,
            m.league_id,
            m.home_score,
            m.away_score,
            ms.stats->>'xg_home' AS xg_home,
            ms.stats->>'xg_away' AS xg_away
        FROM matches m
        LEFT JOIN match_statistics ms ON ms.match_id = m.id
        WHERE m.status = 2   -- finished
          AND m.home_score IS NOT NULL
        ORDER BY m.scheduled_at ASC
    """)
    with SessionLocal() as db:
        rows = db.execute(query).mappings().all()

    if not rows:
        return pd.DataFrame()

    df = pd.DataFrame(rows)
    df["scheduled_at"] = pd.to_datetime(df["scheduled_at"], utc=True)
    df["home_score"]   = df["home_score"].astype(int)
    df["away_score"]   = df["away_score"].astype(int)
    df["xg_home"]      = pd.to_numeric(df.get("xg_home"), errors="coerce")
    df["xg_away"]      = pd.to_numeric(df.get("xg_away"), errors="coerce")
    return df
