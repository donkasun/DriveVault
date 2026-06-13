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
    assert body["avgConsumptionLPer100Km"] == 9.8
    assert body["avgCostPerKmCents"] == 15
    assert body["totalLiters"] == 138.0
    assert body["totalSpentCents"] == 21400
    assert body["monthlySpend"] == [
        {"month": "2026-06", "spentCents": 13900},
        {"month": "2026-05", "spentCents": 7500},
    ]


@patch("app.deps.auth.verify_id_token")
def test_fuel_stats_ignores_trailing_partial_fill(mock_verify, fuel_client, db_session, users):
    """A partial fill after the last full tank is excluded from the average
    (interval never closes) but still counts in total_liters."""
    owner, _ = users
    vehicle = _create_vehicle(db_session, owner)
    _create_fuel_log(db_session, vehicle, date(2026, 5, 1), 1000, "40.000", 6000)
    _create_fuel_log(db_session, vehicle, date(2026, 5, 10), 1500, "30.000", 4500)
    # Trailing partial — must NOT drag the average down.
    _create_fuel_log(db_session, vehicle, date(2026, 5, 20), 1800, "12.000", 1800, False)
    _mock_owner(mock_verify)

    body = fuel_client.get(
        f"/api/v1/vehicles/{vehicle.id}/fuel-stats", headers=_auth_headers()
    ).json()

    # Only the closed interval 1000->1500 counts: 30 L over 500 km.
    assert body["avgConsumptionLPer100Km"] == 6.0
    assert body["avgCostPerKmCents"] == 9  # 4500 / 500
    # Totals still include every log.
    assert body["totalLiters"] == 82.0
    assert body["totalSpentCents"] == 12300


@patch("app.deps.auth.verify_id_token")
def test_fuel_stats_partial_fill_counts_toward_next_full_interval(
    mock_verify, fuel_client, db_session, users
):
    """A partial fill mid-sequence is accumulated into the interval that closes
    at the next full tank."""
    owner, _ = users
    vehicle = _create_vehicle(db_session, owner)
    _create_fuel_log(db_session, vehicle, date(2026, 5, 1), 1000, "40.000", 6000)
    _create_fuel_log(db_session, vehicle, date(2026, 5, 10), 1300, "15.000", 2250, False)
    _create_fuel_log(db_session, vehicle, date(2026, 5, 20), 1600, "25.000", 3750)
    _mock_owner(mock_verify)

    body = fuel_client.get(
        f"/api/v1/vehicles/{vehicle.id}/fuel-stats", headers=_auth_headers()
    ).json()

    # Closed interval 1000->1600 = 600 km; liters = 15 + 25 = 40.
    assert body["avgConsumptionLPer100Km"] == 6.7  # 40/600*100 = 6.66.. -> 6.7
    assert body["avgCostPerKmCents"] == 10  # (2250 + 3750) / 600


@patch("app.deps.auth.verify_id_token")
def test_fuel_stats_single_full_log_has_no_average(mock_verify, fuel_client, db_session, users):
    owner, _ = users
    vehicle = _create_vehicle(db_session, owner)
    _create_fuel_log(db_session, vehicle, date(2026, 5, 1), 1000, "40.000", 6000)
    _mock_owner(mock_verify)

    body = fuel_client.get(
        f"/api/v1/vehicles/{vehicle.id}/fuel-stats", headers=_auth_headers()
    ).json()

    assert body["avgConsumptionLPer100Km"] is None
    assert body["avgCostPerKmCents"] is None
    assert body["totalLiters"] == 40.0


@patch("app.deps.auth.verify_id_token")
def test_fuel_stats_skips_non_positive_distance(mock_verify, fuel_client, db_session, users):
    """A log whose odometer is <= the previous log's is dropped from the
    average entirely (bad data guard)."""
    owner, _ = users
    vehicle = _create_vehicle(db_session, owner)
    _create_fuel_log(db_session, vehicle, date(2026, 5, 1), 1000, "40.000", 6000)
    _create_fuel_log(db_session, vehicle, date(2026, 5, 10), 800, "20.000", 3000)
    _mock_owner(mock_verify)

    body = fuel_client.get(
        f"/api/v1/vehicles/{vehicle.id}/fuel-stats", headers=_auth_headers()
    ).json()

    # Second log has negative distance -> skipped -> no closed interval.
    assert body["avgConsumptionLPer100Km"] is None
    assert body["totalLiters"] == 60.0


@patch("app.deps.auth.verify_id_token")
def test_fuel_stats_ignores_leading_partial_before_first_full_tank(
    mock_verify, fuel_client, db_session, users
):
    """An interval can only OPEN at a full tank. A partial fill before the first
    full tank is not a valid measurement anchor and must be excluded."""
    owner, _ = users
    vehicle = _create_vehicle(db_session, owner)
    # First log is a PARTIAL fill — not a valid starting reference.
    _create_fuel_log(db_session, vehicle, date(2026, 5, 1), 1000, "20.000", 3000, False)
    _create_fuel_log(db_session, vehicle, date(2026, 5, 10), 1450, "35.000", 5250)
    _create_fuel_log(db_session, vehicle, date(2026, 5, 25), 1950, "40.000", 6000)
    _mock_owner(mock_verify)

    body = fuel_client.get(
        f"/api/v1/vehicles/{vehicle.id}/fuel-stats", headers=_auth_headers()
    ).json()

    # Only the interval between the two FULL tanks (1450 -> 1950) counts:
    # 40 L over 500 km. The leading partial interval (1000 -> 1450) is excluded.
    assert body["avgConsumptionLPer100Km"] == 8.0
    assert body["avgCostPerKmCents"] == 12  # 6000 / 500


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
            "distanceUnit": "mi",
        },
    )
    assert create_response.status_code == 201
    body = create_response.json()
    assert body["fuelType"] == "petrol"
    assert body["distanceUnit"] == "mi"

    vehicle_id = body["id"]
    patch_response = fuel_client.patch(
        f"/api/v1/vehicles/{vehicle_id}",
        headers=_auth_headers(),
        json={"fuelType": "diesel", "distanceUnit": "km"},
    )
    assert patch_response.status_code == 200
    patched = patch_response.json()
    assert patched["fuelType"] == "diesel"
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
    # fuel type omitted → null (inherit / unset)
    assert body["fuelType"] is None


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


# ── F4 tests (currency-from-preference) ──────────────────────────────────────


@patch("app.deps.auth.verify_id_token")
def test_f4_fuel_log_currency_from_preference(mock_verify, fuel_client, db_session, users):
    owner, _ = users
    owner.currency = "EUR"
    db_session.commit()
    vehicle = _create_vehicle(db_session, owner)
    _mock_owner(mock_verify)

    # currency omitted → always LKR (locked)
    response = fuel_client.post(
        f"/api/v1/vehicles/{vehicle.id}/fuel-logs",
        headers=_auth_headers(),
        json={
            "date": "2026-06-01",
            "liters": 45.5,
            "priceCents": 7800,
            "odometer": 48200,
        },
    )
    assert response.status_code == 201
    body = response.json()
    assert body["currency"] == "LKR"

    # explicit currency is still coerced to LKR
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
    assert explicit.json()["currency"] == "LKR"


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


# ── Odometer validation + mileage-sync tests ──────────────────────────────────


@patch("app.deps.auth.verify_id_token")
def test_odometer_create_first_log_no_validation(mock_verify, fuel_client, db_session, users):
    """First fuel log for a vehicle is accepted regardless of odometer value."""
    owner, _ = users
    vehicle = _create_vehicle(db_session, owner)
    _mock_owner(mock_verify)

    response = fuel_client.post(
        f"/api/v1/vehicles/{vehicle.id}/fuel-logs",
        headers=_auth_headers(),
        json={
            "date": "2026-06-01",
            "liters": 40.0,
            "priceCents": 6000,
            "odometer": 50000,
        },
    )
    assert response.status_code == 201
    db_session.refresh(vehicle)
    assert vehicle.current_mileage == 50000


@patch("app.deps.auth.verify_id_token")
def test_odometer_create_above_max_accepted(mock_verify, fuel_client, db_session, users):
    """Creating a log with odometer strictly greater than existing max is accepted."""
    owner, _ = users
    vehicle = _create_vehicle(db_session, owner)
    _create_fuel_log(db_session, vehicle, date(2026, 5, 1), 48000)
    _mock_owner(mock_verify)

    response = fuel_client.post(
        f"/api/v1/vehicles/{vehicle.id}/fuel-logs",
        headers=_auth_headers(),
        json={
            "date": "2026-06-01",
            "liters": 45.0,
            "priceCents": 7000,
            "odometer": 48001,
        },
    )
    assert response.status_code == 201
    db_session.refresh(vehicle)
    assert vehicle.current_mileage == 48001


@patch("app.deps.auth.verify_id_token")
def test_odometer_create_equal_to_max_rejected(mock_verify, fuel_client, db_session, users):
    """Creating a log with odometer equal to existing max returns 400."""
    owner, _ = users
    vehicle = _create_vehicle(db_session, owner)
    _create_fuel_log(db_session, vehicle, date(2026, 5, 1), 48500)
    _mock_owner(mock_verify)

    response = fuel_client.post(
        f"/api/v1/vehicles/{vehicle.id}/fuel-logs",
        headers=_auth_headers(),
        json={
            "date": "2026-06-01",
            "liters": 45.0,
            "priceCents": 7000,
            "odometer": 48500,
        },
    )
    assert response.status_code == 400
    assert (
        response.json()["detail"] == "Odometer must be greater than the latest reading (48500 km)"
    )


@patch("app.deps.auth.verify_id_token")
def test_odometer_create_below_max_rejected(mock_verify, fuel_client, db_session, users):
    """Creating a log with odometer less than existing max returns 400."""
    owner, _ = users
    vehicle = _create_vehicle(db_session, owner)
    _create_fuel_log(db_session, vehicle, date(2026, 5, 1), 48500)
    _mock_owner(mock_verify)

    response = fuel_client.post(
        f"/api/v1/vehicles/{vehicle.id}/fuel-logs",
        headers=_auth_headers(),
        json={
            "date": "2026-06-01",
            "liters": 45.0,
            "priceCents": 7000,
            "odometer": 48000,
        },
    )
    assert response.status_code == 400
    assert (
        response.json()["detail"] == "Odometer must be greater than the latest reading (48500 km)"
    )


@patch("app.deps.auth.verify_id_token")
def test_odometer_delete_latest_reverts_mileage(mock_verify, fuel_client, db_session, users):
    """Deleting the latest log reverts current_mileage to the second-to-last odometer."""
    owner, _ = users
    vehicle = _create_vehicle(db_session, owner)
    _create_fuel_log(db_session, vehicle, date(2026, 5, 1), 48000)
    latest = _create_fuel_log(db_session, vehicle, date(2026, 6, 1), 49000)
    # Manually set current_mileage so we can verify it changes
    vehicle.current_mileage = 49000
    db_session.commit()
    _mock_owner(mock_verify)

    response = fuel_client.delete(f"/api/v1/fuel-logs/{latest.id}", headers=_auth_headers())
    assert response.status_code == 204
    db_session.refresh(vehicle)
    assert vehicle.current_mileage == 48000


@patch("app.deps.auth.verify_id_token")
def test_odometer_delete_only_log_sets_mileage_null(mock_verify, fuel_client, db_session, users):
    """Deleting the only fuel log sets vehicle.current_mileage to None."""
    owner, _ = users
    vehicle = _create_vehicle(db_session, owner)
    only_log = _create_fuel_log(db_session, vehicle, date(2026, 6, 1), 50000)
    vehicle.current_mileage = 50000
    db_session.commit()
    _mock_owner(mock_verify)

    response = fuel_client.delete(f"/api/v1/fuel-logs/{only_log.id}", headers=_auth_headers())
    assert response.status_code == 204
    db_session.refresh(vehicle)
    assert vehicle.current_mileage is None


# ── Currency lock (LKR) tests ─────────────────────────────────────────────────


@patch("app.deps.auth.verify_id_token")
def test_create_fuel_log_forces_lkr_even_if_client_sends_usd(
    mock_verify, fuel_client, db_session, users
):
    """Currency is always coerced to LKR regardless of what the client sends."""
    owner, _ = users
    vehicle = _create_vehicle(db_session, owner)
    _mock_owner(mock_verify)

    response = fuel_client.post(
        f"/api/v1/vehicles/{vehicle.id}/fuel-logs",
        headers=_auth_headers(),
        json={
            "date": "2026-06-10",
            "liters": 40.0,
            "priceCents": 7500,
            "odometer": 51000,
            "currency": "USD",
        },
    )
    assert response.status_code == 201
    assert response.json()["currency"] == "LKR"
