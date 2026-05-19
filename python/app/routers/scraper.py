from fastapi import APIRouter, HTTPException, Depends, BackgroundTasks

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

    background_tasks.add_task(_run_scraper, competition_id)
    return {"status": "started"}


@router.get("/status")
async def scraper_status(_: None = Depends(verify_api_key)):
    return _scraper_status


async def _run_scraper(competition_id: str | None):
    import asyncio
    from datetime import datetime

    _scraper_status["running"] = True
    try:
        loop = asyncio.get_event_loop()
        count = await loop.run_in_executor(None, _scrape_sync, competition_id)
        _scraper_status["matches_synced"] = count
        _scraper_status["last_run"] = datetime.utcnow().isoformat()
    finally:
        _scraper_status["running"] = False


def _scrape_sync(competition_id: str | None) -> int:
    scraper = FootballDataScraper()
    return scraper.sync_all(competition_id=competition_id)
