from fastapi import APIRouter, Depends, HTTPException, Request

from app.auth import verify_api_key
from app.schemas.prediction import PredictionRequest, PredictionResponse
from app.services.analysis_generator import AnalysisGenerator
from app.services.feature_engineering import FeatureEngineer
from app.services.kelly_calculator import kelly_fraction
from app.services.ml_engine import MLEngine

router = APIRouter(tags=["predictions"])


def get_ml_engine(request: Request) -> MLEngine:
    return request.app.state.ml_engine


@router.post("/generate", response_model=PredictionResponse)
async def generate_prediction(
    body: PredictionRequest,
    _: None = Depends(verify_api_key),
    ml: MLEngine = Depends(get_ml_engine),
):
    """
    Generate a full prediction for a single match.
    Called by the Rails Sidekiq job.
    """
    if not ml.is_trained:
        raise HTTPException(
            status_code=503,
            detail="ML models not yet trained. Run POST /training/start first."
        )

    try:
        engineer = FeatureEngineer()
        features = engineer.build_features_for_match(
            home_team_id=body.home_team_id,
            away_team_id=body.away_team_id,
            league_id=body.league_id,
            scheduled_at=body.scheduled_at,
        )

        result = ml.predict(features)

        # Kelly fraction for top recommended outcome
        top_prob = result["max_probability"]
        result["kelly_fraction"] = kelly_fraction(top_prob)

        # Value rating (1-5) based on confidence
        cs = result["confidence_score"]
        result["value_rating"] = min(5, max(1, int(cs / 20)))

        # Recommended bet label
        outcome_map = {"home": f"Heimsieg ({body.home_team_name})",
                       "draw": "Unentschieden",
                       "away": f"Auswärtssieg ({body.away_team_name})"}
        result["recommended_bet"] = outcome_map.get(result["recommended_outcome"], "–")

        # Over/Under probs dict for Rails
        result["over_under_probs"] = {
            "over_15_prob": result.pop("over_15_prob", None),
            "over_25_prob": result.pop("over_25_prob", None),
            "over_35_prob": result.pop("over_35_prob", None),
        }

        # AI analysis text
        generator = AnalysisGenerator()
        result["ai_analysis"] = generator.generate(body, result)
        result["model_version"] = ml.model_version

        return PredictionResponse(**result)

    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc


@router.get("/{match_id}")
async def get_prediction_status(
    match_id: int,
    _: None = Depends(verify_api_key),
):
    """Check if prediction data exists for a match (proxy to DB)."""
    return {"match_id": match_id, "status": "use Rails API for stored predictions"}
