"""Tests for vehicle list/read including derived docsStatus field."""

from datetime import date, timedelta
from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient

from app.core.db import get_db
from app.main import create_app
from app.models.documents import Document
from app.models.users import User
from app.models.vehicles import Vehicle


@pytest.fixture
def vehicle_client(db_session):
    app = create_app()

    def _override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = _override_get_db
    with TestClient(app) as client:
        yield client
    app.dependency_overrides.clear()


@pytest.fixture
def owner(db_session):
    user = User(firebase_uid="veh-docs-owner", email="veh_docs@example.com")
    db_session.add(user)
    db_session.commit()
    return user


def _auth_headers() -> dict:
    return {"Authorization": "Bearer veh-docs-token"}


def _mock_owner(mock_verify):
    mock_verify.return_value = {
        "uid": "veh-docs-owner",
        "email": "veh_docs@example.com",
        "email_verified": True,
    }


def _create_vehicle(db_session, user: User, make: str = "Toyota") -> Vehicle:
    vehicle = Vehicle(user_id=user.id, make=make, model="Corolla", year=2021)
    db_session.add(vehicle)
    db_session.commit()
    db_session.refresh(vehicle)
    return vehicle


def _create_doc(db_session, vehicle: Vehicle, expiry_date: date | None = None) -> Document:
    doc = Document(
        vehicle_id=vehicle.id,
        doc_type="insurance",
        title="Insurance Policy",
        storage_url="https://example.com/doc.pdf",
        expiry_date=expiry_date,
    )
    db_session.add(doc)
    db_session.commit()
    db_session.refresh(doc)
    return doc


@patch("app.deps.auth.verify_id_token")
def test_docs_status_none_no_expiry_docs(mock_verify, vehicle_client, db_session, owner):
    """Vehicle with no documents (or docs without expiry_date) → state='none'."""
    _mock_owner(mock_verify)
    vehicle = _create_vehicle(db_session, owner)

    # A doc with no expiry_date — should not count
    _create_doc(db_session, vehicle, expiry_date=None)

    response = vehicle_client.get("/api/v1/vehicles", headers=_auth_headers())
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    docs_status = data[0]["docsStatus"]
    assert docs_status["state"] == "none", f"Expected 'none', got {docs_status['state']}"
    assert docs_status["needsActionCount"] == 0


@patch("app.deps.auth.verify_id_token")
def test_docs_status_valid_all_ok(mock_verify, vehicle_client, db_session, owner):
    """Vehicle with docs all expiring >30 days away → state='valid'."""
    _mock_owner(mock_verify)
    vehicle = _create_vehicle(db_session, owner, make="Honda")
    today = date.today()

    _create_doc(db_session, vehicle, expiry_date=today + timedelta(days=60))
    _create_doc(db_session, vehicle, expiry_date=today + timedelta(days=45))

    response = vehicle_client.get("/api/v1/vehicles", headers=_auth_headers())
    assert response.status_code == 200
    docs_status = response.json()[0]["docsStatus"]
    assert docs_status["state"] == "valid", f"Expected 'valid', got {docs_status['state']}"
    assert docs_status["needsActionCount"] == 0


@patch("app.deps.auth.verify_id_token")
def test_docs_status_needs_action_soon(mock_verify, vehicle_client, db_session, owner):
    """Vehicle with a 'soon' (≤30d) doc → state='needs_action', count correct."""
    _mock_owner(mock_verify)
    vehicle = _create_vehicle(db_session, owner, make="Nissan")
    today = date.today()

    _create_doc(db_session, vehicle, expiry_date=today + timedelta(days=10))  # soon
    _create_doc(db_session, vehicle, expiry_date=today + timedelta(days=60))  # ok

    response = vehicle_client.get("/api/v1/vehicles", headers=_auth_headers())
    assert response.status_code == 200
    docs_status = response.json()[0]["docsStatus"]
    assert docs_status["state"] == "needs_action"
    assert docs_status["needsActionCount"] == 1


@patch("app.deps.auth.verify_id_token")
def test_docs_status_needs_action_overdue(mock_verify, vehicle_client, db_session, owner):
    """Vehicle with an overdue doc → state='needs_action', count correct."""
    _mock_owner(mock_verify)
    vehicle = _create_vehicle(db_session, owner, make="Suzuki")
    today = date.today()

    _create_doc(db_session, vehicle, expiry_date=today - timedelta(days=5))  # overdue
    _create_doc(db_session, vehicle, expiry_date=today - timedelta(days=1))  # overdue
    _create_doc(db_session, vehicle, expiry_date=today + timedelta(days=60))  # ok

    response = vehicle_client.get("/api/v1/vehicles", headers=_auth_headers())
    assert response.status_code == 200
    docs_status = response.json()[0]["docsStatus"]
    assert docs_status["state"] == "needs_action"
    assert docs_status["needsActionCount"] == 2


@patch("app.deps.auth.verify_id_token")
def test_docs_status_on_single_vehicle_read(mock_verify, vehicle_client, db_session, owner):
    """GET /vehicles/{id} also includes docsStatus."""
    _mock_owner(mock_verify)
    vehicle = _create_vehicle(db_session, owner, make="Mazda")
    today = date.today()
    _create_doc(db_session, vehicle, expiry_date=today + timedelta(days=20))  # soon

    response = vehicle_client.get(f"/api/v1/vehicles/{vehicle.id}", headers=_auth_headers())
    assert response.status_code == 200
    docs_status = response.json()["docsStatus"]
    assert docs_status["state"] == "needs_action"
    assert docs_status["needsActionCount"] == 1


@patch("app.deps.auth.verify_id_token")
def test_docs_status_multiple_vehicles_no_n_plus_1(mock_verify, vehicle_client, db_session, owner):
    """Listing multiple vehicles returns correct docsStatus for each without N+1."""
    _mock_owner(mock_verify)
    today = date.today()

    v1 = _create_vehicle(db_session, owner, make="Toyota")
    v2 = _create_vehicle(db_session, owner, make="Honda")
    v3 = _create_vehicle(db_session, owner, make="BMW")

    _create_doc(db_session, v1, expiry_date=today + timedelta(days=10))  # soon → needs_action
    _create_doc(db_session, v2, expiry_date=today + timedelta(days=60))  # ok → valid
    # v3 has no expiry docs → none

    response = vehicle_client.get("/api/v1/vehicles", headers=_auth_headers())
    assert response.status_code == 200
    vehicles_data = response.json()
    assert len(vehicles_data) == 3

    by_make = {v["make"]: v["docsStatus"] for v in vehicles_data}

    assert by_make["Toyota"]["state"] == "needs_action"
    assert by_make["Toyota"]["needsActionCount"] == 1

    assert by_make["Honda"]["state"] == "valid"
    assert by_make["Honda"]["needsActionCount"] == 0

    assert by_make["BMW"]["state"] == "none"
    assert by_make["BMW"]["needsActionCount"] == 0
