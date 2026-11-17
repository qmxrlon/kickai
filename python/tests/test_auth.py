import pytest
from fastapi import Depends, FastAPI
from fastapi.testclient import TestClient

from app import auth
from app.config import settings


@pytest.fixture
def client():
    app = FastAPI()

    @app.get("/protected", dependencies=[Depends(auth.verify_api_key)])
    def protected():
        return {"ok": True}

    return TestClient(app)


def test_valid_key_is_accepted(client, monkeypatch):
    monkeypatch.setattr(settings, "api_secret_key", "s3cret")
    assert client.get("/protected", headers={"X-Api-Key": "s3cret"}).status_code == 200


def test_wrong_key_is_rejected(client, monkeypatch):
    monkeypatch.setattr(settings, "api_secret_key", "s3cret")
    assert client.get("/protected", headers={"X-Api-Key": "nope"}).status_code == 403


def test_missing_header_is_rejected(client, monkeypatch):
    monkeypatch.setattr(settings, "api_secret_key", "s3cret")
    assert client.get("/protected").status_code in (401, 403)


def test_unconfigured_secret_fails_closed_in_production(client, monkeypatch):
    monkeypatch.setattr(settings, "api_secret_key", "")
    monkeypatch.setattr(settings, "environment", "production")
    assert client.get("/protected", headers={"X-Api-Key": "anything"}).status_code == 503


def test_unconfigured_secret_allowed_in_development(client, monkeypatch):
    monkeypatch.setattr(settings, "api_secret_key", "")
    monkeypatch.setattr(settings, "environment", "development")
    assert client.get("/protected", headers={"X-Api-Key": "anything"}).status_code == 200
