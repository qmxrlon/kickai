"""
Standalone training script.
Run inside the Python container:
    docker compose exec python python ml/train.py
"""
import logging
import sys

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)


def main():
    from app.services.data_fetcher import DataFetcher
    from app.services.ml_engine import MLEngine

    logger.info("Loading historical match data from database…")
    fetcher = DataFetcher()
    df = fetcher.load_historical_matches()

    if df.empty:
        logger.error("No match data found. Fetch matches first: make fetch-data")
        sys.exit(1)

    logger.info("Training on %d matches…", len(df))
    engine = MLEngine()
    results = engine.train(df)

    logger.info("Training complete:")
    for k, v in results.items():
        logger.info("  %-30s %s", k, v)

    logger.info("Models saved. Restart the Python service to load the new models.")


if __name__ == "__main__":
    main()
