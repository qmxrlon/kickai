"""
KickAI ML Engine
================
Trains and runs XGBoost models for sports match outcome prediction.

Models:
  - outcome_model  : XGBClassifier → 1X2 (home win / draw / away win)
  - btts_model     : XGBClassifier → Both Teams To Score (yes/no)
  - goals_model    : XGBRegressor  → Predicted total goals (for over/under)
  - xg_home_model  : XGBRegressor  → Expected goals (home)
  - xg_away_model  : XGBRegressor  → Expected goals (away)
"""

import logging
import os
from typing import Any

import joblib
import numpy as np
import pandas as pd
import xgboost as xgb
from scipy.stats import poisson
from sklearn.metrics import accuracy_score, log_loss
from sklearn.preprocessing import StandardScaler

logger = logging.getLogger(__name__)

MODEL_DIR = os.environ.get("MODEL_DIR", "/app/ml/saved_models")
MODEL_VERSION = "1.2"


TEST_FRACTION = 0.2


def chronological_split_index(n_samples: int, test_fraction: float = TEST_FRACTION) -> int:
    """Index that separates the oldest (train) from the newest (test) samples."""
    if n_samples < 2:
        raise ValueError("Need at least two samples to build a train/test split.")
    split = int(n_samples * (1 - test_fraction))
    return min(max(split, 1), n_samples - 1)


class MLEngine:
    def __init__(self):
        self.outcome_model: xgb.XGBClassifier | None  = None
        self.btts_model:    xgb.XGBClassifier | None  = None
        self.goals_model:   xgb.XGBRegressor | None   = None
        self.xg_home_model: xgb.XGBRegressor | None   = None
        self.xg_away_model: xgb.XGBRegressor | None   = None
        self.scaler:        StandardScaler | None      = None
        self.model_version: str = MODEL_VERSION

        os.makedirs(MODEL_DIR, exist_ok=True)
        self._load_models()

    # ── Public API ────────────────────────────────────────────────────────────

    @property
    def is_trained(self) -> bool:
        return self.outcome_model is not None

    def train(self, df: pd.DataFrame) -> dict[str, Any]:
        """Train all models on a DataFrame of historical matches."""
        from app.services.feature_engineering import FeatureEngineer

        engineer = FeatureEngineer()
        X_df, labels = engineer.prepare_training_data(df)

        if X_df.empty:
            raise ValueError("Feature matrix is empty — not enough historical data.")

        X = X_df.values.astype(np.float32)

        # Matches are ordered by kick-off time. Split chronologically so the
        # models are always evaluated on matches *after* the ones they were
        # trained on — a random split would leak future information.
        split = chronological_split_index(len(X))
        self.scaler = StandardScaler().fit(X[:split])
        X_scaled = self.scaler.transform(X)
        X_tr, X_te = X_scaled[:split], X_scaled[split:]

        results: dict[str, Any] = {
            "training_samples": split,
            "test_samples":     len(X) - split,
            "feature_count":    X.shape[1],
            "model_version":    MODEL_VERSION,
        }

        # ── 1X2 outcome ───────────────────────────────────────────────────────
        y_outcome = labels["outcome"].to_numpy()
        y_tr, y_te = y_outcome[:split], y_outcome[split:]
        self.outcome_model = xgb.XGBClassifier(
            n_estimators=300, max_depth=5, learning_rate=0.04,
            subsample=0.8, colsample_bytree=0.8,
            eval_metric="mlogloss", random_state=42, n_jobs=-1,
        )
        self.outcome_model.fit(X_tr, y_tr, eval_set=[(X_te, y_te)], verbose=False)
        y_pred = self.outcome_model.predict(X_te)
        results["outcome_accuracy"] = round(accuracy_score(y_te, y_pred), 4)
        results["outcome_log_loss"] = round(
            log_loss(y_te, self.outcome_model.predict_proba(X_te), labels=[0, 1, 2]), 4
        )
        logger.info("Outcome model trained — accuracy: %.3f", results["outcome_accuracy"])

        # ── BTTS ──────────────────────────────────────────────────────────────
        y_btts = labels["btts"].to_numpy()
        self.btts_model = xgb.XGBClassifier(
            n_estimators=200, max_depth=4, learning_rate=0.05,
            eval_metric="logloss", random_state=42, n_jobs=-1,
        )
        self.btts_model.fit(X_tr, y_btts[:split], verbose=False)
        results["btts_accuracy"] = round(
            accuracy_score(y_btts[split:], self.btts_model.predict(X_te)), 4
        )

        # ── Total goals ───────────────────────────────────────────────────────
        y_goals = labels["total_goals"].to_numpy(dtype=np.float32)
        self.goals_model = xgb.XGBRegressor(
            n_estimators=200, max_depth=4, learning_rate=0.05,
            random_state=42, n_jobs=-1,
        )
        self.goals_model.fit(X_tr, y_goals[:split], verbose=False)
        results["goals_mae"] = round(
            float(np.mean(np.abs(self.goals_model.predict(X_te) - y_goals[split:]))), 4
        )

        # ── xG models (only where xG data exists) ─────────────────────────────
        if "xg_home" in labels and labels["xg_home"].notna().sum() > 100:
            for attr, key in [("xg_home_model", "xg_home"), ("xg_away_model", "xg_away")]:
                mask = labels[key].notna().to_numpy()
                train_mask = mask.copy()
                train_mask[split:] = False
                model = xgb.XGBRegressor(n_estimators=150, max_depth=4, learning_rate=0.05, n_jobs=-1)
                model.fit(X_scaled[train_mask], labels[key].to_numpy(dtype=np.float32)[train_mask], verbose=False)
                setattr(self, attr, model)

        self._save_models()
        return results

    def predict(self, features: np.ndarray) -> dict[str, Any]:
        """Run all models on a pre-built feature vector."""
        if not self.is_trained:
            raise RuntimeError("Models not trained. Call train() first or ensure saved models exist.")

        x = features.astype(np.float32).reshape(1, -1)
        if self.scaler is not None:
            x = self.scaler.transform(x)

        result: dict[str, Any] = {}

        # 1X2
        probs = self.outcome_model.predict_proba(x)[0]
        result["home_win_prob"] = round(float(probs[0]), 4)
        result["draw_prob"]     = round(float(probs[1]), 4)
        result["away_win_prob"] = round(float(probs[2]), 4)

        # Confidence (1 - normalised entropy)
        entropy = -sum(p * np.log(p + 1e-9) for p in probs)
        result["confidence_score"] = round((1.0 - entropy / np.log(3)) * 100, 1)

        # Recommended outcome
        outcomes = ["home", "draw", "away"]
        result["recommended_outcome"] = outcomes[int(np.argmax(probs))]
        result["max_probability"]     = round(float(max(probs)), 4)

        # BTTS
        btts_proba = self.btts_model.predict_proba(x)[0] if self.btts_model else [0.5, 0.5]
        result["btts_prob"] = round(float(btts_proba[1]), 4)

        # Total goals → over/under via Poisson
        if self.goals_model:
            mu = max(0.1, float(self.goals_model.predict(x)[0]))
        else:
            mu = 2.5
        result["predicted_goals"] = round(mu, 2)
        result["over_15_prob"]    = round(1.0 - poisson.cdf(1, mu), 4)
        result["over_25_prob"]    = round(1.0 - poisson.cdf(2, mu), 4)
        result["over_35_prob"]    = round(1.0 - poisson.cdf(3, mu), 4)

        # xG
        if self.xg_home_model and self.xg_away_model:
            result["xg_home"] = round(max(0.0, float(self.xg_home_model.predict(x)[0])), 2)
            result["xg_away"] = round(max(0.0, float(self.xg_away_model.predict(x)[0])), 2)
        else:
            result["xg_home"] = round(mu * result["home_win_prob"], 2)
            result["xg_away"] = round(mu * result["away_win_prob"], 2)

        return result

    # ── Persistence ───────────────────────────────────────────────────────────

    def _save_models(self):
        if self.outcome_model:
            self.outcome_model.save_model(f"{MODEL_DIR}/outcome_model.json")
        if self.btts_model:
            self.btts_model.save_model(f"{MODEL_DIR}/btts_model.json")
        if self.goals_model:
            self.goals_model.save_model(f"{MODEL_DIR}/goals_model.json")
        if self.xg_home_model:
            self.xg_home_model.save_model(f"{MODEL_DIR}/xg_home_model.json")
        if self.xg_away_model:
            self.xg_away_model.save_model(f"{MODEL_DIR}/xg_away_model.json")
        if self.scaler:
            joblib.dump(self.scaler, f"{MODEL_DIR}/scaler.joblib")
        logger.info("ML models saved to %s", MODEL_DIR)

    def _load_models(self):
        def _load_xgb(cls, path):
            if os.path.exists(path):
                m = cls()
                m.load_model(path)
                return m
            return None

        self.outcome_model  = _load_xgb(xgb.XGBClassifier,  f"{MODEL_DIR}/outcome_model.json")
        self.btts_model     = _load_xgb(xgb.XGBClassifier,  f"{MODEL_DIR}/btts_model.json")
        self.goals_model    = _load_xgb(xgb.XGBRegressor,   f"{MODEL_DIR}/goals_model.json")
        self.xg_home_model  = _load_xgb(xgb.XGBRegressor,   f"{MODEL_DIR}/xg_home_model.json")
        self.xg_away_model  = _load_xgb(xgb.XGBRegressor,   f"{MODEL_DIR}/xg_away_model.json")

        scaler_path = f"{MODEL_DIR}/scaler.joblib"
        if os.path.exists(scaler_path):
            self.scaler = joblib.load(scaler_path)

        if self.is_trained:
            logger.info("Loaded saved ML models from %s", MODEL_DIR)
        else:
            logger.info("No saved models found — train via POST /training/start")
