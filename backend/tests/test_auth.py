"""Task A4 — Firebase token auth dependency."""

from unittest.mock import patch

import pytest
from fastapi import Depends
from fastapi.testclient import TestClient

from app.core.db import get_db
from app.deps import get_current_user
from app.main import create_app


@pytest.fixture
def auth_client(db_session):
    app = create_app()

    @app.get("/api/v1/_protected-test")
    def protected_test_route(current_user=Depends(get_current_user)):
        return {"ok": True, "userId": str(current_user.id)}

    def _override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = _override_get_db
    with TestClient(app) as client:
        yield client
    app.dependency_overrides.clear()


def test_a4_protected_route_returns_401_without_token(auth_client):
    response = auth_client.get("/api/v1/_protected-test")
    assert response.status_code == 401
    assert response.json()["detail"] == "Missing authorization token"


@patch("app.deps.auth.verify_id_token")
def test_a4_protected_route_returns_200_with_valid_token(mock_verify, auth_client):
    mock_verify.return_value = {"uid": "firebase-test-uid", "email": "auth@example.com"}

    response = auth_client.get(
        "/api/v1/_protected-test",
        headers={"Authorization": "Bearer valid-token"},
    )

    assert response.status_code == 200
    assert response.json()["ok"] is True
    mock_verify.assert_called_once_with("valid-token")
