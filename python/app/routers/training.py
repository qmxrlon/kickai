import asyncio

from fastapi import APIRouter, HTTPException, BackgroundTasks, Depends

from app.auth import verify_api_key
from app.services.ml_engine import MLEngine
from app.services.data_fetcher import DataFetcher

router = APIRouter(tags=["training"])

_training_status = {"running": False, "last_result": None, "error": None}


@router.post("/start")
async def start_training(
    background_tasks: BackgroundTasks,
    _: None = Depends(verify_api_key),
):
    if _training_status["running"]:
        raise HTTPException(status_code=409, detail="Training already in progress.")

    background_tasks.add_task(_run_training)
    return {"status": "started", "message": "Training started in background. Poll /training/status for results."}


@router.get("/status")
async def training_status(_: None = Depends(verify_api_key)):
    return _training_status


@router.get("/evaluate")
async def evaluate(_: None = Depends(verify_api_key)):
    if _training_status["last_result"] is None:
        raise HTTPException(status_code=404, detail="No training results available yet.")
    return _training_status["last_result"]


async def _run_training():
    _training_status["running"] = True
    _training_status["error"] = None
    try:
        loop = asyncio.get_event_loop()
        result = await loop.run_in_executor(None, _train_sync)
        _training_status["last_result"] = result
    except Exception as exc:
        _training_status["error"] = str(exc)
    finally:
        _training_status["running"] = False


def _train_sync():
    fetcher = DataFetcher()
    df = fetcher.load_historical_matches()

    if df.empty:
        raise ValueError("No historical match data in database. Fetch matches first.")

    engine = MLEngine()
    result = engine.train(df)
    return result
