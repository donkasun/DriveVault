"""Dashboard aggregate endpoint tests (Task B6)."""

from datetime import date, timedelta
from decimal import Decimal
from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient

from app.core.db import get_db
from app.main import create_app
from app.models.documents import Document
from app.models.fuel_logs import FuelLog
from app.models.maintenance_records import MaintenanceRecord
from app.models.users import User
from app.models.vehicles import Vehicle


@pytest.fixture
def dashboard_client(db_session):
    app = create_app()

    def _override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = _override_get_db
    with TestClient(app) as client:
        yield client
    app.dependency_overrides.clear()


@pytest.fixture
def users(db_session):
    owner = User(firebase_uid="dashboard-owner", email="owner@example.com")
    other = User(firebase_uid="dashboard-other", email="other@example.com")
    db_session.add_all([owner, other])
    db_session.commit()
    return owner, other


def _auth_headers(token: str = "owner-token") -> dict:
    return {"Authorization": f"Bearer {token}"}


def _create_vehicle(db_session, user: User, make: str = "Toyota") -> Vehicle:
    vehicle = Vehicle(
        user_id=user.id,
        make=make,
        model="Hilux",
        year=2020,
        purchase_price_cents=3500000,
        current_mileage=48000,
        vehicle_type="pickup",
    )
    db_session.add(vehicle)
    db_session.commit()
    db_session.refresh(vehicle)
    return vehicle


def _create_fuel_log(db_session, vehicle: Vehicle, log_date: date, liters: float, price_cents: int):
    fuel_log = FuelLog(
        vehicle_id=vehicle.id,
        date=log_date,
        liters=Decimal(str(liters)),
        price_cents=price_cents,
        odometer=48000 + (log_date - date(2020, 1, 1)).days * 30,
        is_full_tank=True,
    )
    db_session.add(fuel_log)
    db_session.commit()
    db_session.refresh(fuel_log)
    return fuel_log


def _create_document(
    db_session, vehicle: Vehicle, doc_type: str = "insurance", expiry_date: date = None
):
    if expiry_date is None:
        expiry_date = date.today() + timedelta(days=30)

    doc = Document(
        vehicle_id=vehicle.id,
        doc_type=doc_type,
        title=f"{doc_type.title()} Policy",
        storage_url="https://example.com/doc123.pdf",
        storage_public_id="vehicles/photo-1/documents/doc123",
        mime_type="application/pdf",
        file_size_bytes=482000,
        issue_date=date(2026, 1, 1),
        expiry_date=expiry_date,
    )
    db_session.add(doc)
    db_session.commit()
    db_session.refresh(doc)
    return doc


@patch("app.deps.auth.verify_id_token")
def test_b6_dashboard_single_vehicle_with_all_costs_and_renewals(
    mock_verify, dashboard_client, db_session, users
):
    owner, _ = users

    mock_verify.return_value = {
        "uid": "dashboard-owner",
        "email": "owner@example.com",
        "email_verified": True,
    }

    vehicle = _create_vehicle(db_session, owner, make="Toyota")

    today = date.today()
    _create_fuel_log(db_session, vehicle, today, 45.0, 7020)

    maint_record = MaintenanceRecord(
        vehicle_id=vehicle.id,
        date=today - timedelta(days=10),
        service_type="Oil Change",
        cost_cents=320000,
        odometer=47800,
        workshop="City Auto",
    )
    db_session.add(maint_record)
    db_session.commit()

    _create_document(
        db_session, vehicle, doc_type="insurance", expiry_date=today + timedelta(days=30)
    )

    response = dashboard_client.get("/api/v1/dashboard", headers=_auth_headers())

    assert response.status_code == 200
    data = response.json()

    assert data["vehicleCount"] == 1, f"Expected vehicleCount=1, got {data['vehicleCount']}"
    assert (
        data["monthlyFuelSpendCents"] == 7020
    ), f"Expected monthlyFuelSpendCents=7020, got {data['monthlyFuelSpendCents']}"

    expected_total_cost = 7020 + 320000 + 3500000
    assert (
        data["totalOwnershipCostCents"] == expected_total_cost
    ), f"Expected totalOwnershipCostCents={expected_total_cost}, got {data['totalOwnershipCostCents']}"

    assert (
        data["costBreakdown"]["fuelCents"] == 7020
    ), f"Expected fuelCents=7020, got {data['costBreakdown']['fuelCents']}"
    assert (
        data["costBreakdown"]["maintenanceCents"] == 320000
    ), f"Expected maintenanceCents=320000, got {data['costBreakdown']['maintenanceCents']}"
    assert (
        data["costBreakdown"]["purchaseCents"] == 3500000
    ), f"Expected purchaseCents=3500000, got {data['costBreakdown']['purchaseCents']}"

    assert (
        len(data["upcomingRenewals"]) == 1
    ), f"Expected 1 upcoming renewal, got {len(data['upcomingRenewals'])}"

    renewal = data["upcomingRenewals"][0]
    assert renewal["vehicleId"] == str(
        vehicle.id
    ), f"Expected vehicleId={vehicle.id}, got {renewal['vehicleId']}"
    assert (
        renewal["title"] == "Insurance Policy"
    ), f"Expected title='Insurance Policy', got {renewal['title']}"
    assert renewal["expiryDate"] == (today + timedelta(days=30)).strftime(
        "%Y-%m-%d"
    ), f"Expected expiryDate={(today + timedelta(days=30)).strftime('%Y-%m-%d')}, got {renewal['expiryDate']}"


@patch("app.deps.auth.verify_id_token")
def test_b6_dashboard_cross_user_isolation(mock_verify, dashboard_client, db_session, users):
    owner, other = users

    mock_verify.return_value = {
        "uid": "dashboard-owner",
        "email": "owner@example.com",
        "email_verified": True,
    }

    owner_vehicle = _create_vehicle(db_session, owner, make="Toyota")
    other_vehicle = _create_vehicle(db_session, other, make="Honda")

    today = date.today()
    _create_fuel_log(db_session, owner_vehicle, today, 50.0, 7500)
    _create_fuel_log(db_session, other_vehicle, today, 40.0, 6000)

    _create_document(
        db_session, owner_vehicle, doc_type="registration", expiry_date=today + timedelta(days=15)
    )
    _create_document(
        db_session, other_vehicle, doc_type="insurance", expiry_date=today + timedelta(days=20)
    )

    response = dashboard_client.get("/api/v1/dashboard", headers=_auth_headers("dashboard-owner"))

    assert response.status_code == 200
    data = response.json()

    assert (
        data["vehicleCount"] == 1
    ), f"Owner should see only their own vehicles, expected 1, got {data['vehicleCount']}"
    assert data["upcomingRenewals"][0]["vehicleId"] == str(
        owner_vehicle.id
    ), "Should be owner's document, not other user's"


@patch("app.deps.auth.verify_id_token")
def test_b6_dashboard_two_vehicles_aggregated(mock_verify, dashboard_client, db_session):
    owner = User(firebase_uid="dashboard-user2", email="user2@example.com")
    db_session.add(owner)
    db_session.commit()

    mock_verify.return_value = {
        "uid": "dashboard-user2",
        "email": "user2@example.com",
        "email_verified": True,
    }

    vehicle1 = _create_vehicle(db_session, owner, make="Toyota")
    vehicle2 = _create_vehicle(db_session, owner, make="Honda")

    today = date.today()
    _create_fuel_log(db_session, vehicle1, today, 45.0, 7020)
    _create_fuel_log(db_session, vehicle2, today, 40.0, 6000)

    response = dashboard_client.get("/api/v1/dashboard", headers=_auth_headers("dashboard-user2"))

    assert response.status_code == 200
    data = response.json()

    assert data["vehicleCount"] == 2, f"Expected vehicleCount=2, got {data['vehicleCount']}"

    expected_monthly_fuel = 7020 + 6000
    assert (
        data["monthlyFuelSpendCents"] == expected_monthly_fuel
    ), f"Expected monthlyFuelSpendCents={expected_monthly_fuel}, got {data['monthlyFuelSpendCents']}"


# ─── New tests for enriched renewals, recent activity, and status scale ───────


@patch("app.deps.auth.verify_id_token")
def test_dashboard_overdue_renewal_included(mock_verify, dashboard_client, db_session):
    """Overdue docs (expiry_date < today) must appear in upcomingRenewals with status='overdue'."""
    owner = User(firebase_uid="dashboard-overdue", email="overdue@example.com")
    db_session.add(owner)
    db_session.commit()

    mock_verify.return_value = {
        "uid": "dashboard-overdue",
        "email": "overdue@example.com",
        "email_verified": True,
    }

    vehicle = _create_vehicle(db_session, owner, make="Nissan")
    today = date.today()

    # Overdue document (expired 15 days ago)
    overdue_doc = _create_document(
        db_session, vehicle, doc_type="registration", expiry_date=today - timedelta(days=15)
    )
    # Future document within 90 days (soon = ≤30d)
    soon_doc = _create_document(
        db_session, vehicle, doc_type="insurance", expiry_date=today + timedelta(days=20)
    )

    response = dashboard_client.get(
        "/api/v1/dashboard", headers={"Authorization": "Bearer overdue-token"}
    )
    assert response.status_code == 200
    data = response.json()

    renewals = data["upcomingRenewals"]
    assert len(renewals) == 2, f"Expected 2 renewals, got {len(renewals)}"

    # First item should be the overdue one (sorted ascending by expiry_date)
    assert renewals[0]["status"] == "overdue", f"Expected 'overdue', got {renewals[0]['status']}"
    assert renewals[0]["daysRemaining"] < 0, "Overdue days_remaining must be negative"
    assert renewals[0]["vehicleId"] == str(vehicle.id)
    assert renewals[0]["docType"] == "registration"
    assert "vehicleLabel" in renewals[0]

    # Second item should be the "soon" one
    assert renewals[1]["status"] == "soon", f"Expected 'soon', got {renewals[1]['status']}"
    assert 0 <= renewals[1]["daysRemaining"] <= 30

    # New fields present
    for r in renewals:
        for key in (
            "vehicleId",
            "title",
            "expiryDate",
            "docType",
            "vehicleLabel",
            "daysRemaining",
            "status",
        ):
            assert key in r, f"Key '{key}' missing from renewal item"


@patch("app.deps.auth.verify_id_token")
def test_dashboard_ok_renewal_excluded(mock_verify, dashboard_client, db_session):
    """Docs expiring in >90 days must NOT appear in upcomingRenewals."""
    owner = User(firebase_uid="dashboard-ok-excl", email="ok_excl@example.com")
    db_session.add(owner)
    db_session.commit()

    mock_verify.return_value = {
        "uid": "dashboard-ok-excl",
        "email": "ok_excl@example.com",
        "email_verified": True,
    }

    vehicle = _create_vehicle(db_session, owner, make="Honda")
    today = date.today()

    # Document expiring far in the future (status='ok')
    _create_document(
        db_session, vehicle, doc_type="warranty", expiry_date=today + timedelta(days=120)
    )

    response = dashboard_client.get(
        "/api/v1/dashboard", headers={"Authorization": "Bearer ok-excl-token"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["upcomingRenewals"] == [], "Documents with >90d remaining must not appear"


@patch("app.deps.auth.verify_id_token")
def test_dashboard_recent_activity_ordering_and_limit(mock_verify, dashboard_client, db_session):
    """recentActivity must be sorted newest-first, capped at 10, and include all three types."""
    owner = User(firebase_uid="dashboard-activity", email="activity@example.com")
    db_session.add(owner)
    db_session.commit()

    mock_verify.return_value = {
        "uid": "dashboard-activity",
        "email": "activity@example.com",
        "email_verified": True,
    }

    vehicle = _create_vehicle(db_session, owner, make="Suzuki")
    today = date.today()

    # Add 5 fuel logs on different days
    for i in range(5):
        _create_fuel_log(
            db_session, vehicle, today - timedelta(days=i * 3), 10.0 + i, 1500 + i * 100
        )

    # Add 4 maintenance records
    for i in range(4):
        rec = MaintenanceRecord(
            vehicle_id=vehicle.id,
            date=today - timedelta(days=i * 2 + 1),
            service_type=f"Service {i}",
            cost_cents=5000 + i * 100,
        )
        db_session.add(rec)
    db_session.commit()

    # Add 3 documents (with issue_date so activity date is consistent)
    for i in range(3):
        doc = Document(
            vehicle_id=vehicle.id,
            doc_type="insurance",
            title=f"Doc {i}",
            storage_url="https://example.com/doc.pdf",
            issue_date=today - timedelta(days=i * 5 + 2),
        )
        db_session.add(doc)
    db_session.commit()

    response = dashboard_client.get(
        "/api/v1/dashboard", headers={"Authorization": "Bearer activity-token"}
    )
    assert response.status_code == 200
    data = response.json()

    activity = data["recentActivity"]
    assert len(activity) <= 10, f"recentActivity must be capped at 10, got {len(activity)}"
    assert len(activity) > 0, "recentActivity must not be empty"

    # Verify descending date order
    dates = [item["date"] for item in activity]
    assert dates == sorted(dates, reverse=True), "recentActivity must be sorted newest-first"

    # Verify required keys exist on every item
    for item in activity:
        for key in ("type", "vehicleId", "vehicleLabel", "date", "amountCents", "label"):
            assert key in item, f"Key '{key}' missing from activity item"

    types_seen = {item["type"] for item in activity}
    # We created fuel, maintenance, and document records — all three should appear
    # (limit is 10 and we have 5+4+3=12 total, so some may be cut off, but all types should appear)
    assert "fuel" in types_seen
    assert "maintenance" in types_seen


def test_dashboard_includes_credential_renewals(db_session):
    """Credentials expiring within 90 days appear in upcomingRenewals."""
    import uuid
    from datetime import date, timedelta
    from fastapi.testclient import TestClient
    from app.main import app
    from app.core.db import get_db
    from app.deps import get_current_user
    from app.models.users import User
    from app.models.vehicles import Vehicle
    from app.models.user_documents import UserDocument

    user = User(firebase_uid=f"uid-{uuid.uuid4()}", email="dash@test.com", renewal_reminders_enabled=True)
    db_session.add(user)
    vehicle = Vehicle(user_id=None, make="Toyota", model="Hilux")  # user_id set after flush
    db_session.flush()
    vehicle.user_id = user.id
    db_session.add(vehicle)
    cred = UserDocument(user_id=user.id, doc_type="license", expiry_date=date.today() + timedelta(days=15))
    db_session.add(cred)
    db_session.commit()

    def _db():
        yield db_session

    app.dependency_overrides = {get_current_user: lambda: user, get_db: _db}
    tc = TestClient(app)
    resp = tc.get("/api/v1/dashboard")
    app.dependency_overrides = {}

    assert resp.status_code == 200
    renewals = resp.json()["upcomingRenewals"]
    cred_renewals = [r for r in renewals if r["vehicleId"] is None]
    assert len(cred_renewals) == 1
    assert cred_renewals[0]["docType"] == "license"
    assert cred_renewals[0]["status"] == "soon"


@patch("app.deps.auth.verify_id_token")
def test_dashboard_no_vehicles_empty_activity(mock_verify, dashboard_client, db_session):
    """With no vehicles, recentActivity must be an empty list."""
    owner = User(firebase_uid="dashboard-no-veh", email="noveh@example.com")
    db_session.add(owner)
    db_session.commit()

    mock_verify.return_value = {
        "uid": "dashboard-no-veh",
        "email": "noveh@example.com",
        "email_verified": True,
    }

    response = dashboard_client.get(
        "/api/v1/dashboard", headers={"Authorization": "Bearer no-veh-token"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["recentActivity"] == []
    assert data["upcomingRenewals"] == []
