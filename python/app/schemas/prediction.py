from datetime import datetime

from pydantic import BaseModel


class PredictionRequest(BaseModel):
    match_id: int
    external_id: str | None = None
    home_team_id: str | None = None
    away_team_id: str | None = None
    home_team_name: str
    away_team_name: str
    league_id: str | None = None
    scheduled_at: datetime


class PredictionResponse(BaseModel):
    home_win_prob: float
    draw_prob: float
    away_win_prob: float
    btts_prob: float
    xg_home: float
    xg_away: float
    predicted_goals: float
    over_under_probs: dict
    confidence_score: float
    value_rating: int
    recommended_bet: str
    kelly_fraction: float
    ai_analysis: str
    model_version: str
    recommended_outcome: str | None = None
    max_probability: float | None = None
