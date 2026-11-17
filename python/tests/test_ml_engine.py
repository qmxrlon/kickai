from datetime import datetime, timedelta

import numpy as np
import pandas as pd
import pytest

from app.services.feature_engineering import FeatureEngineer
from app.services.ml_engine import MLEngine, chronological_split_index


def synthetic_matches(n_matches: int = 360, n_teams: int = 8, seed: int = 7) -> pd.DataFrame:
    """Round-robin style fixtures where stronger teams score more often."""
    rng = np.random.default_rng(seed)
    strength = np.linspace(0.6, 2.0, n_teams)
    start = datetime(2024, 1, 1)
    rows = []
    for i in range(n_matches):
        home, away = rng.choice(n_teams, size=2, replace=False)
        rows.append({
            "match_id": i,
            "scheduled_at": start + timedelta(days=i // 4),
            "home_team_id": f"t{home}",
            "away_team_id": f"t{away}",
            "league_id": "L1",
            "home_score": int(rng.poisson(strength[home] * 1.1)),
            "away_score": int(rng.poisson(strength[away] * 0.9)),
        })
    return pd.DataFrame(rows)


class TestChronologicalSplit:
    def test_eighty_twenty(self):
        assert chronological_split_index(100) == 80

    def test_always_leaves_both_sides_non_empty(self):
        assert chronological_split_index(2) == 1
        assert chronological_split_index(3) in (1, 2)

    def test_rejects_too_few_samples(self):
        with pytest.raises(ValueError):
            chronological_split_index(1)


def test_features_only_use_past_matches():
    df = synthetic_matches(120)
    X, labels = FeatureEngineer().prepare_training_data(df)
    assert len(X) == len(labels) > 0
    assert set(FeatureEngineer._feature_names()) == set(X.columns)
    assert labels["outcome"].isin([0, 1, 2]).all()


def test_train_and_predict_end_to_end():
    engine = MLEngine()
    results = engine.train(synthetic_matches())

    assert engine.is_trained
    total = results["training_samples"] + results["test_samples"]
    assert results["test_samples"] == total - chronological_split_index(total)
    assert 0.0 <= results["outcome_accuracy"] <= 1.0

    features = np.zeros(results["feature_count"], dtype=np.float32)
    prediction = engine.predict(features)
    probs = prediction["home_win_prob"] + prediction["draw_prob"] + prediction["away_win_prob"]
    assert probs == pytest.approx(1.0, abs=1e-3)
    assert 0.0 <= prediction["over_25_prob"] <= 1.0
    assert prediction["recommended_outcome"] in {"home", "draw", "away"}
