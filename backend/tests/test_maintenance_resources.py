"""Tasks B4/B4b — maintenance CRUD and Cloudinary upload signatures."""

from datetime import date
from hashlib import sha1
from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select

from app.core.config import get_settings
from app.core.db import get_db
from app.main import create_app
from app.models.maintenance_records import MaintenanceRecord
from app.models.users import User
from app.models.vehicles import Vehicle


@pytest.fixture
def maintenance_client(db_session):
    app = create_app()

    def _override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = _override_get_db
    with TestClient(app) as client:
        yield client
    app.dependency_overrides.clear()


@pytest.fixture
def users(db_session):
    owner = User(firebase_uid="maint-owner", email="owner@example.com")
    other = User(firebase_uid="maint-other", email="other@example.com")
    db_session.add_all([owner, other])
    db_session.commit()
    return owner, other


def _auth_headers(token: str = "owner-token") -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _mock_owner(mock_verify):
    mock_verify.return_value = {
        "uid": "maint-owner",
        "email": "owner@example.com",
        "email_verified": True,
    }


def _create_vehicle(db_session, user: User, make: str = "Toyota") -> Vehicle:
    vehicle = Vehicle(user_id=user.id, make=make, model="Hilux", year=2020)
    db_session.add(vehicle)
    db_session.commit()
    db_session.refresh(vehicle)
    return vehicle


def _create_maintenance_record(
    db_session,
    vehicle: Vehicle,
    record_date: date,
    service_type: str = "Oil Change",
    category: str | None = "maintenance",
) -> MaintenanceRecord:
    record = MaintenanceRecord(
        vehicle_id=vehicle.id,
        date=record_date,
        odometer=48000,
        service_type=service_type,
        category=category,
        cost_cents=6500,
        workshop="City Auto",
        notes="5W-30 synthetic",
        source="manual",
    )
    db_session.add(record)
    db_session.commit()
    db_session.refresh(record)
    return record


@patch("app.deps.auth.verify_id_token")
def test_b4_maintenance_crud_category_filter_and_ownership(
    mock_verify,
    maintenance_client,
    db_session,
    users,
):
    owner, other = users
    vehicle = _create_vehicle(db_session, owner)
    other_vehicle = _create_vehicle(db_session, other, make="Honda")
    oil_change = _create_maintenance_record(
        db_session,
        vehicle,
        date(2026, 5, 20),
        "Oil Change",
        "maintenance",
    )
    _create_maintenance_record(db_session, vehicle, date(2026, 4, 15), "Tint", "upgrade")
    other_record = _create_maintenance_record(db_session, other_vehicle, date(2026, 5, 21))
    _mock_owner(mock_verify)

    list_response = maintenance_client.get(
        f"/api/v1/vehicles/{vehicle.id}/maintenance",
        headers=_auth_headers(),
        params={"category": "maintenance", "from": "2026-05-01", "to": "2026-05-31"},
    )
    assert list_response.status_code == 200
    assert [record["id"] for record in list_response.json()] == [str(oil_change.id)]

    create_response = maintenance_client.post(
        f"/api/v1/vehicles/{vehicle.id}/maintenance",
        headers=_auth_headers(),
        json={
            "date": "2026-06-01",
            "odometer": 49000,
            "serviceType": "Brake Pads",
            "category": "repair",
            "costCents": 42000,
            "currency": "USD",
            "workshop": "City Auto",
            "notes": "Front pads",
        },
    )
    assert create_response.status_code == 201
    created = create_response.json()
    assert created["vehicleId"] == str(vehicle.id)
    assert created["serviceType"] == "Brake Pads"
    assert created["costCents"] == 42000
    assert created["source"] == "manual"
    assert created["aiExtractionId"] is None

    get_response = maintenance_client.get(
        f"/api/v1/maintenance/{created['id']}",
        headers=_auth_headers(),
    )
    assert get_response.status_code == 200
    assert get_response.json()["category"] == "repair"

    patch_response = maintenance_client.patch(
        f"/api/v1/maintenance/{created['id']}",
        headers=_auth_headers(),
        json={"costCents": 43000, "notes": "Front ceramic pads"},
    )
    assert patch_response.status_code == 200
    assert patch_response.json()["costCents"] == 43000
    assert patch_response.json()["notes"] == "Front ceramic pads"

    cross_user_response = maintenance_client.get(
        f"/api/v1/maintenance/{other_record.id}",
        headers=_auth_headers(),
    )
    assert cross_user_response.status_code == 404

    delete_response = maintenance_client.delete(
        f"/api/v1/maintenance/{created['id']}",
        headers=_auth_headers(),
    )
    assert delete_response.status_code == 204
    assert (
        db_session.scalar(select(MaintenanceRecord).where(MaintenanceRecord.id == created["id"]))
        is None
    )


@patch("app.deps.auth.verify_id_token")
@patch("app.services.uploads.time")
def test_b4b_cloudinary_signature_matches_known_sha1(
    mock_time,
    mock_verify,
    maintenance_client,
    monkeypatch,
):
    monkeypatch.setenv("CLOUDINARY_CLOUD_NAME", "drivevault")
    monkeypatch.setenv("CLOUDINARY_API_KEY", "1234567890")
    monkeypatch.setenv("CLOUDINARY_API_SECRET", "top-secret")
    get_settings.cache_clear()
    mock_time.return_value = 1733692800
    _mock_owner(mock_verify)

    response = maintenance_client.post(
        "/api/v1/uploads/cloudinary-signature",
        headers=_auth_headers(),
        json={"folder": "vehicles/vehicle-123/documents"},
    )

    assert response.status_code == 200
    body = response.json()
    expected_signature = sha1(
        b"folder=vehicles/vehicle-123/documents&timestamp=1733692800top-secret"
    ).hexdigest()
    assert body == {
        "signature": expected_signature,
        "timestamp": 1733692800,
        "apiKey": "1234567890",
        "cloudName": "drivevault",
        "folder": "vehicles/vehicle-123/documents",
    }
    assert "top-secret" not in str(body)

    get_settings.cache_clear()


# ── F4 test (currency-from-preference for maintenance) ────────────────────────


@patch("app.deps.auth.verify_id_token")
def test_f4_maintenance_currency_from_preference(
    mock_verify, maintenance_client, db_session, users
):
    owner, _ = users
    owner.currency = "EUR"
    db_session.commit()
    vehicle = _create_vehicle(db_session, owner)
    _mock_owner(mock_verify)

    # currency omitted → always LKR (locked)
    response = maintenance_client.post(
        f"/api/v1/vehicles/{vehicle.id}/maintenance",
        headers=_auth_headers(),
        json={"date": "2026-05-20", "serviceType": "Oil Change", "costCents": 6500},
    )
    assert response.status_code == 201
    assert response.json()["currency"] == "LKR"

    # explicit currency is still coerced to LKR
    explicit = maintenance_client.post(
        f"/api/v1/vehicles/{vehicle.id}/maintenance",
        headers=_auth_headers(),
        json={"date": "2026-05-21", "serviceType": "Brake Service", "currency": "GBP"},
    )
    assert explicit.status_code == 201
    assert explicit.json()["currency"] == "LKR"


# ── Currency lock (LKR) tests ─────────────────────────────────────────────────


@patch("app.deps.auth.verify_id_token")
def test_create_maintenance_forces_lkr_even_if_client_sends_usd(
    mock_verify, maintenance_client, db_session, users
):
    """Currency is always coerced to LKR regardless of what the client sends."""
    owner, _ = users
    vehicle = _create_vehicle(db_session, owner)
    _mock_owner(mock_verify)

    response = maintenance_client.post(
        f"/api/v1/vehicles/{vehicle.id}/maintenance",
        headers=_auth_headers(),
        json={
            "date": "2026-06-10",
            "serviceType": "Oil Change",
            "currency": "USD",
        },
    )
    assert response.status_code == 201
    assert response.json()["currency"] == "LKR"
