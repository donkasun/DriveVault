"""Task A5 — GET/PATCH /api/v1/me endpoints."""

from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient

from sqlalchemy import select

from app.core.db import get_db
from app.main import create_app
from app.models.users import User


@pytest.fixture
def me_client(db_session):
    app = create_app()

    def _override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = _override_get_db
    with TestClient(app) as client:
        yield client
    app.dependency_overrides.clear()


@patch("app.deps.auth.verify_id_token")
def test_a5_get_me_creates_user_on_first_call(mock_verify, me_client, db_session):
    mock_verify.return_value = {
        "uid": "firebase-me-1",
        "email": "me1@example.com",
        "email_verified": True,
    }

    response = me_client.get(
        "/api/v1/me",
        headers={"Authorization": "Bearer token-1"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["firebaseUid"] == "firebase-me-1"
    assert body["email"] == "me1@example.com"
    assert body["displayName"] is None
    assert "createdAt" in body

    user = db_session.scalar(select(User).where(User.firebase_uid == "firebase-me-1"))
    assert user is not None
    assert user.email == "me1@example.com"


@patch("app.deps.auth.verify_id_token")
def test_a5_get_me_returns_existing_user(mock_verify, me_client, db_session):
    existing = User(
        firebase_uid="firebase-me-2",
        email="me2@example.com",
        display_name="Existing User",
    )
    db_session.add(existing)
    db_session.commit()

    mock_verify.return_value = {
        "uid": "firebase-me-2",
        "email": "me2@example.com",
        "email_verified": True,
    }

    response = me_client.get(
        "/api/v1/me",
        headers={"Authorization": "Bearer token-2"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["id"] == str(existing.id)
    assert body["displayName"] == "Existing User"


@patch("app.deps.auth.verify_id_token")
def test_a5_patch_me_updates_profile(mock_verify, me_client, db_session):
    user = User(firebase_uid="firebase-me-3", email="me3@example.com")
    db_session.add(user)
    db_session.commit()

    mock_verify.return_value = {
        "uid": "firebase-me-3",
        "email": "me3@example.com",
        "email_verified": True,
    }

    response = me_client.patch(
        "/api/v1/me",
        headers={"Authorization": "Bearer token-3"},
        json={"displayName": "Kasun", "photoUrl": "https://example.com/photo.jpg"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["displayName"] == "Kasun"
    assert body["photoUrl"] == "https://example.com/photo.jpg"

    db_session.refresh(user)
    assert user.display_name == "Kasun"
    assert user.photo_url == "https://example.com/photo.jpg"


@patch("app.deps.auth.verify_id_token")
def test_a5_unverified_email_stores_empty_string(mock_verify, me_client, db_session):
    """email_verified absent/False → email stored as empty string."""
    mock_verify.return_value = {"uid": "firebase-me-unverified", "email": "test@example.com"}

    response = me_client.get(
        "/api/v1/me",
        headers={"Authorization": "Bearer token-unverified"},
    )

    assert response.status_code == 200
    user = db_session.scalar(select(User).where(User.firebase_uid == "firebase-me-unverified"))
    assert user is not None
    assert user.email == ""


@patch("app.deps.auth.verify_id_token")
def test_a5_get_me_handles_concurrent_insert(mock_verify, me_client, db_session):
    """IntegrityError on first commit (race condition) → rollback + re-query succeeds."""
    # Pre-insert the user so the re-query after rollback finds it.
    user = User(firebase_uid="firebase-race", email="race@example.com")
    db_session.add(user)
    db_session.flush()

    mock_verify.return_value = {
        "uid": "firebase-race",
        "email": "race@example.com",
        "email_verified": True,
    }

    import unittest.mock as mock
    from sqlalchemy.exc import IntegrityError as SAIntegrityError

    original_commit = db_session.commit
    call_count = 0

    def commit_once_then_raise(*args, **kwargs):
        nonlocal call_count
        call_count += 1
        if call_count == 1:
            raise SAIntegrityError("duplicate key", {}, None)
        return original_commit(*args, **kwargs)

    with mock.patch.object(db_session, "commit", side_effect=commit_once_then_raise):
        response = me_client.get(
            "/api/v1/me",
            headers={"Authorization": "Bearer race-token"},
        )

    assert response.status_code == 200
    body = response.json()
    assert body["firebaseUid"] == "firebase-race"
    assert body["email"] == "race@example.com"


# ── F2 tests ────────────────────────────────────────────────────────────────


@patch("app.deps.auth.verify_id_token")
def test_f2_get_me_includes_currency_and_distance_unit(mock_verify, me_client, db_session):
    """GET /me response includes currency and distanceUnit fields."""
    mock_verify.return_value = {
        "uid": "firebase-f2-get",
        "email": "f2get@example.com",
        "email_verified": True,
    }

    response = me_client.get(
        "/api/v1/me",
        headers={"Authorization": "Bearer f2-get-token"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["currency"] == "LKR"
    assert body["distanceUnit"] == "km"


@patch("app.deps.auth.verify_id_token")
def test_f2_patch_me_updates_currency_and_distance_unit(mock_verify, me_client, db_session):
    """PATCH /me with valid currency and distanceUnit updates both fields."""
    user = User(firebase_uid="firebase-f2-patch", email="f2patch@example.com")
    db_session.add(user)
    db_session.commit()

    mock_verify.return_value = {
        "uid": "firebase-f2-patch",
        "email": "f2patch@example.com",
        "email_verified": True,
    }

    response = me_client.patch(
        "/api/v1/me",
        headers={"Authorization": "Bearer f2-patch-token"},
        json={"currency": "EUR", "distanceUnit": "mi"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["currency"] == "LKR"
    assert body["distanceUnit"] == "mi"

    db_session.refresh(user)
    assert user.currency == "LKR"
    assert user.distance_unit == "mi"


@patch("app.deps.auth.verify_id_token")
def test_f2_patch_me_invalid_distance_unit_returns_422(mock_verify, me_client, db_session):
    """PATCH /me with an invalid distanceUnit value returns 422."""
    user = User(firebase_uid="firebase-f2-invalid", email="f2invalid@example.com")
    db_session.add(user)
    db_session.commit()

    mock_verify.return_value = {
        "uid": "firebase-f2-invalid",
        "email": "f2invalid@example.com",
        "email_verified": True,
    }

    response = me_client.patch(
        "/api/v1/me",
        headers={"Authorization": "Bearer f2-invalid-token"},
        json={"distanceUnit": "miles"},
    )

    assert response.status_code == 422


@patch("app.deps.auth.verify_id_token")
def test_f2_patch_me_invalid_currency_returns_422(mock_verify, me_client, db_session):
    """PATCH /me with a non-3-letter currency code returns 422."""
    user = User(firebase_uid="firebase-f2-badcurr", email="f2badcurr@example.com")
    db_session.add(user)
    db_session.commit()

    mock_verify.return_value = {
        "uid": "firebase-f2-badcurr",
        "email": "f2badcurr@example.com",
        "email_verified": True,
    }

    response = me_client.patch(
        "/api/v1/me",
        headers={"Authorization": "Bearer f2-badcurr-token"},
        json={"currency": "EURO"},
    )

    assert response.status_code == 422


# ── Currency lock (LKR) tests ─────────────────────────────────────────────────


@patch("app.deps.auth.verify_id_token")
def test_patch_me_coerces_currency_to_lkr(mock_verify, me_client, db_session):
    """PATCH /me with any currency value is always coerced to LKR."""
    user = User(firebase_uid="firebase-lkr-coerce", email="lkrcoerce@example.com")
    db_session.add(user)
    db_session.commit()

    mock_verify.return_value = {
        "uid": "firebase-lkr-coerce",
        "email": "lkrcoerce@example.com",
        "email_verified": True,
    }

    response = me_client.patch(
        "/api/v1/me",
        headers={"Authorization": "Bearer lkr-coerce-token"},
        json={"currency": "EUR"},
    )

    assert response.status_code == 200
    assert response.json()["currency"] == "LKR"
