"""Tasks B1-B3 — vehicles, fuel logs, and fuel stats endpoints."""

from datetime import date
from decimal import Decimal
from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select

from app.core.db import get_db
from app.main import create_app
from app.models.fuel_logs import FuelLog
from app.models.users import User
from app.models.vehicles import Vehicle


@pytest.fixture
def fuel_client(db_session):
    app = create_app()

    def _override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = _override_get_db
    with TestClient(app) as client:
        yield client
    app.dependency_overrides.clear()


@pytest.fixture
def users(db_session):
    owner = User(firebase_uid="fuel-owner", email="owner@example.com")
    other = User(firebase_uid="fuel-other", email="other@example.com")
    db_session.add_all([owner, other])
    db_session.commit()
    return owner, other


def _auth_headers(token: str = "owner-token") -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _mock_owner(mock_verify):
    mock_verify.return_value = {
        "uid": "fuel-owner",
        "email": "owner@example.com",
        "email_verified": True,
    }


def _create_vehicle(db_session, user: User, make: str = "Toyota") -> Vehicle:
    vehicle = Vehicle(user_id=user.id, make=make, model="Hilux", year=2020)
    db_session.add(vehicle)
    db_session.commit()
    db_session.refresh(vehicle)
    return vehicle


def _create_fuel_log(
    db_session,
    vehicle: Vehicle,
    log_date: date,
    odometer: int,
    liters: str = "40.000",
    price_cents: int = 6000,
    is_full_tank: bool = True,
) -> FuelLog:
    fuel_log = FuelLog(
        vehicle_id=vehicle.id,
        date=log_date,
        liters=Decimal(liters),
        price_cents=price_cents,
        odometer=odometer,
        is_full_tank=is_full_tank,
    )
    db_session.add(fuel_log)
    db_session.commit()
    db_session.refresh(fuel_log)
    return fuel_log


@patch("app.deps.auth.verify_id_token")
def test_b1_vehicle_crud_and_cross_user_404(mock_verify, fuel_client, db_session, users):
    owner, other = users
    other_vehicle = _create_vehicle(db_session, other, make="Honda")
    _mock_owner(mock_verify)

    create_response = fuel_client.post(
        "/api/v1/vehicles",
        headers=_auth_headers(),
        json={
            "make": "Toyota",
            "model": "Hilux",
            "year": 2021,
            "registrationNumber": "ABC-1234",
            "purchasePriceCents": 3500000,
            "currentMileage": 48000,
            "vehicleType": "pickup",
        },
    )
    assert create_response.status_code == 201
    created = create_response.json()
    assert created["make"] == "Toyota"
    assert created["registrationNumber"] == "ABC-1234"

    list_response = fuel_client.get("/api/v1/vehicles", headers=_auth_headers())
    assert list_response.status_code == 200
    assert [vehicle["id"] for vehicle in list_response.json()] == [created["id"]]

    get_response = fuel_client.get(f"/api/v1/vehicles/{created['id']}", headers=_auth_headers())
    assert get_response.status_code == 200
    assert get_response.json()["model"] == "Hilux"

    patch_response = fuel_client.patch(
        f"/api/v1/vehicles/{created['id']}",
        headers=_auth_headers(),
        json={"currentMileage": 49000, "photoPublicId": "vehicles/photo-1"},
    )
    assert patch_response.status_code == 200
    assert patch_response.json()["currentMileage"] == 49000
    assert patch_response.json()["photoPublicId"] == "vehicles/photo-1"

    cross_user_response = fuel_client.get(
        f"/api/v1/vehicles/{other_vehicle.id}",
        headers=_auth_headers(),
    )
    assert cross_user_response.status_code == 404

    delete_response = fuel_client.delete(
        f"/api/v1/vehicles/{created['id']}",
        headers=_auth_headers(),
    )
    assert delete_response.status_code == 204
    assert db_session.scalar(select(Vehicle).where(Vehicle.id == created["id"])) is None


@patch("app.deps.auth.verify_id_token")
def test_b2_fuel_logs_crud_filters_validation_and_ownership(
    mock_verify,
    fuel_client,
    db_session,
    users,
):
    owner, other = users
    vehicle = _create_vehicle(db_session, owner)
    other_vehicle = _create_vehicle(db_session, other, make="Honda")
    old_log = _create_fuel_log(db_session, vehicle, date(2026, 5, 1), 48000)
    new_log = _create_fuel_log(db_session, vehicle, date(2026, 6, 1), 48500)
    other_log = _create_fuel_log(db_session, other_vehicle, date(2026, 6, 2), 10000)
    _mock_owner(mock_verify)

    list_response = fuel_client.get(
        f"/api/v1/vehicles/{vehicle.id}/fuel-logs",
        headers=_auth_headers(),
        params={"from": "2026-06-01", "to": "2026-06-30"},
    )
    assert list_response.status_code == 200
    assert [log["id"] for log in list_response.json()] == [str(new_log.id)]

    create_response = fuel_client.post(
        f"/api/v1/vehicles/{vehicle.id}/fuel-logs",
        headers=_auth_headers(),
        json={
            "date": "2026-06-15",
            "liters": 45.5,
            "priceCents": 7800,
            "odometer": 49000,
            "isFullTank": True,
            "notes": "Highway trip",
        },
    )
    assert create_response.status_code == 201
    created = create_response.json()
    assert created["vehicleId"] == str(vehicle.id)
    assert created["priceCents"] == 7800

    invalid_response = fuel_client.post(
        f"/api/v1/vehicles/{vehicle.id}/fuel-logs",
        headers=_auth_headers(),
        json={
            "date": "2026-06-20",
            "liters": 0,
            "priceCents": 1000,
            "odometer": 49100,
        },
    )
    assert invalid_response.status_code == 422

    patch_response = fuel_client.patch(
        f"/api/v1/fuel-logs/{created['id']}",
        headers=_auth_headers(),
        json={"notes": "Updated note", "isFullTank": False},
    )
    assert patch_response.status_code == 200
    assert patch_response.json()["notes"] == "Updated note"
    assert patch_response.json()["isFullTank"] is False

    cross_user_response = fuel_client.patch(
        f"/api/v1/fuel-logs/{other_log.id}",
        headers=_auth_headers(),
        json={"notes": "not mine"},
    )
    assert cross_user_response.status_code == 404

    delete_response = fuel_client.delete(f"/api/v1/fuel-logs/{old_log.id}", headers=_auth_headers())
    assert delete_response.status_code == 204
    assert db_session.scalar(select(FuelLog).where(FuelLog.id == old_log.id)) is None


@patch("app.deps.auth.verify_id_token")
def test_b3_fuel_stats_computes_exact_metrics(mock_verify, fuel_client, db_session, users):
    owner, _ = users
    vehicle = _create_vehicle(db_session, owner)
    _create_fuel_log(db_session, vehicle, date(2026, 5, 1), 10000, "40.000", 6000)
    _create_fuel_log(db_session, vehicle, date(2026, 5, 15), 10250, "10.000", 1500, False)
    _create_fuel_log(db_session, vehicle, date(2026, 6, 1), 10500, "45.000", 7000)
    _create_fuel_log(db_session, vehicle, date(2026, 6, 20), 11000, "43.000", 6900)
    _mock_owner(mock_verify)

    response = fuel_client.get(f"/api/v1/vehicles/{vehicle.id}/fuel-stats", headers=_auth_headers())

    assert response.status_code == 200
    body = response.json()
    assert body["avgConsumptionLPer100Km"] == 8.8
    assert body["avgCostPerKmCents"] == 14
    assert body["totalLiters"] == 138.0
    assert body["totalSpentCents"] == 21400
    assert body["monthlySpend"] == [
        {"month": "2026-06", "spentCents": 13900},
        {"month": "2026-05", "spentCents": 7500},
    ]


# ── F3 tests (vehicle fuel + unit fields) ─────────────────────────────────────


@patch("app.deps.auth.verify_id_token")
def test_f3_vehicle_create_and_patch_fuel_and_unit_fields(
    mock_verify, fuel_client, db_session, users
):
    owner, _ = users
    _mock_owner(mock_verify)

    create_response = fuel_client.post(
        "/api/v1/vehicles",
        headers=_auth_headers(),
        json={
            "make": "Toyota",
            "model": "Hilux",
            "fuelType": "petrol",
            "defaultFuelVariant": "95 Octane",
            "distanceUnit": "mi",
        },
    )
    assert create_response.status_code == 201
    body = create_response.json()
    assert body["fuelType"] == "petrol"
    assert body["defaultFuelVariant"] == "95 Octane"
    assert body["distanceUnit"] == "mi"

    vehicle_id = body["id"]
    patch_response = fuel_client.patch(
        f"/api/v1/vehicles/{vehicle_id}",
        headers=_auth_headers(),
        json={"fuelType": "diesel", "defaultFuelVariant": "Premium", "distanceUnit": "km"},
    )
    assert patch_response.status_code == 200
    patched = patch_response.json()
    assert patched["fuelType"] == "diesel"
    assert patched["defaultFuelVariant"] == "Premium"
    assert patched["distanceUnit"] == "km"


@patch("app.deps.auth.verify_id_token")
def test_f3_vehicle_distance_unit_null_accepted(mock_verify, fuel_client, db_session, users):
    owner, _ = users
    _mock_owner(mock_verify)

    response = fuel_client.post(
        "/api/v1/vehicles",
        headers=_auth_headers(),
        json={"make": "Toyota", "model": "Corolla", "distanceUnit": None},
    )
    assert response.status_code == 201
    body = response.json()
    assert body["distanceUnit"] is None
    # fuel fields omitted → null (inherit / unset)
    assert body["fuelType"] is None
    assert body["defaultFuelVariant"] is None


@patch("app.deps.auth.verify_id_token")
def test_f3_vehicle_invalid_fuel_type_returns_422(mock_verify, fuel_client, db_session, users):
    owner, _ = users
    _mock_owner(mock_verify)

    response = fuel_client.post(
        "/api/v1/vehicles",
        headers=_auth_headers(),
        json={"make": "Toyota", "model": "Yaris", "fuelType": "kerosene"},
    )
    assert response.status_code == 422


# ── F4 tests (fuel variant + currency-from-preference) ────────────────────────


@patch("app.deps.auth.verify_id_token")
def test_f4_fuel_log_variant_and_currency_from_preference(
    mock_verify, fuel_client, db_session, users
):
    owner, _ = users
    owner.currency = "EUR"
    db_session.commit()
    vehicle = _create_vehicle(db_session, owner)
    _mock_owner(mock_verify)

    # currency omitted → falls back to the user's preference; fuelVariant persists
    response = fuel_client.post(
        f"/api/v1/vehicles/{vehicle.id}/fuel-logs",
        headers=_auth_headers(),
        json={
            "date": "2026-06-01",
            "liters": 45.5,
            "priceCents": 7800,
            "odometer": 48200,
            "fuelVariant": "98 Octane",
        },
    )
    assert response.status_code == 201
    body = response.json()
    assert body["currency"] == "EUR"
    assert body["fuelVariant"] == "98 Octane"

    # explicit currency wins
    explicit = fuel_client.post(
        f"/api/v1/vehicles/{vehicle.id}/fuel-logs",
        headers=_auth_headers(),
        json={
            "date": "2026-06-02",
            "liters": 40.0,
            "priceCents": 7000,
            "odometer": 48600,
            "currency": "GBP",
        },
    )
    assert explicit.status_code == 201
    assert explicit.json()["currency"] == "GBP"


@patch("app.deps.auth.verify_id_token")
def test_delete_vehicle_with_children_cascades(mock_verify, fuel_client, db_session, users):
    """Deleting a vehicle that has fuel logs must cascade (regression: was 500)."""
    owner, _ = users
    vehicle = _create_vehicle(db_session, owner)
    _create_fuel_log(db_session, vehicle, date(2026, 6, 1), 48200)
    _mock_owner(mock_verify)

    response = fuel_client.delete(f"/api/v1/vehicles/{vehicle.id}", headers=_auth_headers())

    assert response.status_code == 204
    assert db_session.scalar(select(Vehicle).where(Vehicle.id == vehicle.id)) is None
    assert db_session.scalar(select(FuelLog).where(FuelLog.vehicle_id == vehicle.id)) is None
