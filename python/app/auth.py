from fastapi import HTTPException, Security
from fastapi.security import APIKeyHeader

from app.config import settings

_api_key_header = APIKeyHeader(name="X-Api-Key", auto_error=True)


async def verify_api_key(api_key: str = Security(_api_key_header)) -> None:
    if not settings.api_secret_key:
        return  # No key configured — allow all (dev mode)
    if api_key != settings.api_secret_key:
        raise HTTPException(status_code=403, detail="Invalid API key")
