"""
Data Fetcher
============
Loads historical match data from the database for ML training.
"""

import logging

import pandas as pd

from app.services.feature_engineering import _fetch_matches_from_db

logger = logging.getLogger(__name__)


class DataFetcher:
    def load_historical_matches(self) -> pd.DataFrame:
        """Return a DataFrame of all finished matches suitable for training."""
        df = _fetch_matches_from_db()
        if df.empty:
            logger.warning("No historical matches found in database.")
            return df

        logger.info("Loaded %d historical matches for training.", len(df))
        return df
