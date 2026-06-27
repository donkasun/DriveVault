"""Tests for /me/driving-credentials endpoints (Task: driving credentials)."""

from __future__ import annotations

import uuid

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.main import app
from app.models.user_documents import UserDocument
from app.models.users import User


def _make_user(db: Session) -> User:
    user = User(
        firebase_uid=f"uid-{uuid.uuid4()}",
        email="test@example.com",
        display_name="Test",
        renewal_reminders_enabled=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def _auth_override(user: User):
    """Return a dependency override that injects the given user."""
    from app.deps import get_current_user

    def _override():
        return user

    return {get_current_user: _override}


@pytest.fixture
def client(db_session: Session):
    user = _make_user(db_session)

    from app.core.db import get_db

    def _override_db():
        yield db_session

    app.dependency_overrides = {**_auth_override(user), get_db: _override_db}
    yield TestClient(app), user
    app.dependency_overrides = {}


def test_list_empty(client):
    tc, user = client
    resp = tc.get("/api/v1/me/driving-credentials")
    assert resp.status_code == 200
    assert resp.json() == []


def test_create_and_read(client):
    tc, user = client
    payload = {
        "docType": "license",
        "docNumber": "B1234567",
        "issueDate": "2020-01-01",
        "expiryDate": "2030-01-01",
    }
    resp = tc.post("/api/v1/me/driving-credentials", json=payload)
    assert resp.status_code == 201
    data = resp.json()
    assert data["docType"] == "license"
    assert data["docNumber"] == "B1234567"
    assert data["status"] == "ok"
    assert data["daysUntilExpiry"] > 365

    cid = data["id"]
    resp2 = tc.get("/api/v1/me/driving-credentials")
    assert resp2.status_code == 200
    ids = [c["id"] for c in resp2.json()]
    assert cid in ids


def test_create_without_expiry(client):
    tc, _ = client
    resp = tc.post("/api/v1/me/driving-credentials", json={"docType": "permit"})
    assert resp.status_code == 201
    data = resp.json()
    assert data["expiryDate"] is None
    assert data["daysUntilExpiry"] is None
    assert data["status"] is None


def test_patch(client):
    tc, _ = client
    resp = tc.post("/api/v1/me/driving-credentials", json={"docType": "license"})
    cid = resp.json()["id"]
    patch = tc.patch(f"/api/v1/me/driving-credentials/{cid}", json={"docNumber": "X999"})
    assert patch.status_code == 200
    assert patch.json()["docNumber"] == "X999"


def test_delete(client):
    tc, _ = client
    resp = tc.post("/api/v1/me/driving-credentials", json={"docType": "license"})
    cid = resp.json()["id"]
    del_resp = tc.delete(f"/api/v1/me/driving-credentials/{cid}")
    assert del_resp.status_code == 204
    list_resp = tc.get("/api/v1/me/driving-credentials")
    assert all(c["id"] != cid for c in list_resp.json())


def test_cross_user_404(db_session: Session):
    """A credential belonging to user B returns 404 when requested by user A."""
    from app.core.db import get_db
    from app.deps import get_current_user

    user_a = _make_user(db_session)
    user_b = _make_user(db_session)
    cred = UserDocument(user_id=user_b.id, doc_type="license")
    db_session.add(cred)
    db_session.commit()
    db_session.refresh(cred)

    def _override_db():
        yield db_session

    app.dependency_overrides = {
        get_current_user: lambda: user_a,
        get_db: _override_db,
    }
    tc = TestClient(app)
    resp = tc.patch(f"/api/v1/me/driving-credentials/{cred.id}", json={"docNumber": "X"})
    assert resp.status_code == 404
    app.dependency_overrides = {}
