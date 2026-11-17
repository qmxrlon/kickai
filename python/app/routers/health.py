from fastapi import APIRouter

from app.database import check_connection

router = APIRouter(tags=["health"])


@router.get("/health")
async def health():
    db_ok = check_connection()
    return {
        "status": "ok" if db_ok else "degraded",
        "database": "ok" if db_ok else "unreachable",
        "service": "kickai-python"
    }
