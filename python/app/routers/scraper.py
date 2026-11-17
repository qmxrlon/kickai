import asyncio
from datetime import UTC, datetime

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException

from app.auth import verify_api_key
from app.scrapers.football_data_scraper import FootballDataScraper

router = APIRouter(tags=["scraper"])

_scraper_status = {"running": False, "last_run": None, "matches_synced": 0}


@router.post("/fetch-matches")
async def fetch_matches(
    background_tasks: BackgroundTasks,
    competition_id: str | None = None,
    _: None = Depends(verify_api_key),
):
    """Trigger match data fetch from Football-Data.org."""
    if _scraper_status["running"]:
        raise HTTPException(status_code=409, detail="Scraper already running.")

    # Mark as running before scheduling, so a second request can't slip in
    _scraper_status["running"] = True
    background_tasks.add_task(_run_scraper, competition_id)
    return {"status": "started"}


@router.get("/status")
async def scraper_status(_: None = Depends(verify_api_key)):
    return _scraper_status


async def _run_scraper(competition_id: str | None):
    try:
        count = await asyncio.to_thread(_scrape_sync, competition_id)
        _scraper_status["matches_synced"] = count
        _scraper_status["last_run"] = datetime.now(UTC).isoformat()
    finally:
        _scraper_status["running"] = False


def _scrape_sync(competition_id: str | None) -> int:
    scraper = FootballDataScraper()
    return scraper.sync_all(competition_id=competition_id)
