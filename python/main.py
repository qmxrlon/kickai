from dotenv import load_dotenv

load_dotenv()  # must run before any app imports that read os.environ

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routers import health, predictions, scraper, training


@asynccontextmanager
async def lifespan(application: FastAPI):
    # Startup: pre-load ML models
    from app.services.ml_engine import MLEngine
    application.state.ml_engine = MLEngine()
    yield
    # Shutdown: nothing to clean up


app = FastAPI(
    title="KickAI Prediction Engine",
    description="ML-based sports prediction API for KickAI platform",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs" if settings.environment != "production" else None,
    redoc_url=None,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://rails:3000", "http://localhost:3000"],
    allow_methods=["GET", "POST"],
    allow_headers=["X-Api-Key", "Content-Type"],
)

app.include_router(health.router)
app.include_router(predictions.router, prefix="/predictions")
app.include_router(training.router,    prefix="/training")
app.include_router(scraper.router,     prefix="/scraper")
