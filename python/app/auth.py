import secrets

from fastapi import HTTPException, Security
from fastapi.security import APIKeyHeader

from app.config import settings

_api_key_header = APIKeyHeader(name="X-Api-Key", auto_error=True)


async def verify_api_key(api_key: str = Security(_api_key_header)) -> None:
    """Reject requests without the shared secret configured for Rails ↔ Python.

    Fails closed: if no secret is configured, only a local development
    environment is allowed through.
    """
    expected = settings.api_secret_key
    if not expected:
        if settings.environment == "development":
            return
        raise HTTPException(status_code=503, detail="API secret is not configured")
    # Constant-time comparison prevents timing attacks on the secret
    if not secrets.compare_digest(api_key.encode(), expected.encode()):
        raise HTTPException(status_code=403, detail="Invalid API key")
