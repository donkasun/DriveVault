"""Dashboard aggregate endpoint tests (Task B6)."""

from datetime import date, timedelta
from decimal import Decimal

from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select

from app.core.db import get_db
from app.main import create_app
from app.models.dashboard import DashboardData
from app.models.documents import Document
from app.models.fuel_logs import FuelLog
from app.models.maintenance_records import MaintenanceRecord
from app.models.users import User
from app.models.vehicles import Vehicle


@pytest.fixture
def dashboard_client(db_session):
      """Create a test client with database session override."""
    app = create_app()

    def _override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = _override_get_db
    with TestClient(app) as client:
        yield client
    app.dependency_overrides.clear()


@pytest.fixture
def users(db_session):
      """Create two test users for cross-user isolation tests."""
    owner = User(firebase_uid="dashboard-owner", email="owner@example.com")
    other = User(firebase_uid="dashboard-other", email="other@example.com")
    db_session.add_all([owner, other])
    db_session.commit()
    return owner, other


def _auth_headers(token: str = "owner-token") -> dict:
    return {"Authorization": f"Bearer {token}"}


def _create_vehicle(db_session, user: User, make: str = "Toyota") -> Vehicle:
      """Create a vehicle for testing."""
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
      """Create a fuel log for testing."""
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


def _create_document(db_session, vehicle: Vehicle, doc_type: str = "insurance", expiry_date: date = None):
      """Create a document for testing."""
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
def test_b6_dashboard_single_vehicle_with_all_costs_and_renewals(mock_verify, dashboard_client, db_session, users):
      """
   Test dashboard endpoint with a single vehicle containing fuel logs and maintenance records.
   A document should be created that expires in 30 days.

   Expected behavior:
     - vehicleCount: 1 (one vehicle)
     - monthlyFuelSpendCents: Sum of all fuel logs for current month
     - totalOwnershipCostCents: Sum of fuel + maintenance + purchase costs
     - costBreakdown: Proper breakdown by category
     - upcomingRenewals: Document expiring within 90 days
      """
    from app import deps as auth_deps

    owner, _ = users

       # Mock token verification
    mock_verify.return_value = {
          "uid": "dashboard-owner",
          "email": "owner@example.com",
          "email_verified": True,
        }

       # Create a vehicle
    vehicle = _create_vehicle(db_session, owner, make="Toyota")
    
       # Add fuel logs for the current month (2026-06)
    today = date.today()
      _create_fuel_log(db_session, vehicle, today, 45.0, 7020)   # $70.20
    
       # Add maintenance record
    maint_record = MaintenanceRecord(
        vehicle_id=vehicle.id,
        date=today - timedelta(days=10),
        service_type="Oil Change",
        cost_cents=320000,   # $3200.00
        odometer=47800,
        workshop="City Auto",
      )
    db_session.add(maint_record)
    db_session.commit()

       # Create a document that expires in 30 days
    doc = _create_document(db_session, vehicle, doc_type="insurance", expiry_date=today + timedelta(days=30))

       # Make dashboard request
    response = dashboard_client.get("/api/v1/dashboard", headers=_auth_headers())
    
    assert response.status_code == 200
    data = response.json()
    
      # Verify vehicle count
    assert data["vehicleCount"] == 1, f"Expected vehicleCount=1, got {data['vehicleCount']}"
    
      # Verify monthly fuel spend (from the one fuel log we created)
    assert data["monthlyFuelSpendCents"] == 7020, \
        f"Expected monthlyFuelSpendCents=7020, got {data['monthlyFuelSpendCents']}"
    
      # Verify total ownership cost (fuel + maintenance + purchase)
    expected_total_cost = 7020 + 320000 + 3500000
    assert data["totalOwnershipCostCents"] == expected_total_cost, \
        f"Expected totalOwnershipCostCents={expected_total_cost}, got {data['totalOwnershipCostCents']}"
    
      # Verify cost breakdown
    assert data["costBreakdown"]["fuelCents"] == 7020, \
        f"Expected fuelCents=7020, got {data['costBreakdown']['fuelCents']}"
    assert data["costBreakdown"]["maintenanceCents"] == 320000, \
        f"Expected maintenanceCents=320000, got {data['costBreakdown']['maintenanceCents']}"
    assert data["costBreakdown"]["purchaseCents"] == 3500000, \
        f"Expected purchaseCents=3500000, got {data['costBreakdown']['purchaseCents']}"
    
      # Verify upcoming renewals (document expiring in 30 days)
    assert len(data["upcomingRenewals"]) == 1, \
        f"Expected 1 upcoming renewal, got {len(data['upcomingRenewals'])}"
    
    renewal = data["upcomingRenewals"][0]
    assert renewal["vehicleId"] == str(vehicle.id), \
        f"Expected vehicleId={vehicle.id}, got {renewal['vehicleId']}"
    assert renewal["title"] == "Insurance Policy", \
        f"Expected title='Insurance Policy', got {renewal['title']}"
    assert renewal["expiryDate"] == (today + timedelta(days=30)).strftime("%Y-%m-%d"), \
        f"Expected expiryDate={(today + timedelta(days=30)).strftime('%Y-%m-%d')}, got {renewal['expiryDate']}"


@patch("app.deps.auth.verify_id_token")
def test_b6_dashboard_cross_user_404_isolation(mock_verify, dashboard_client, db_session, users):
      """
    Test that one user cannot see another user's data in the aggregate.

    Expected behavior:
      - When accessing dashboard as user A while trying to access user B's vehicle data,
       it should return 404 (not leak data).
      - Each user only sees their own aggregated data.
      """
    from app import deps as auth_deps
    
    owner, other = users

       # Mock token verification
    mock_verify.return_value = {
          "uid": "dashboard-owner",
          "email": "owner@example.com",
          "email_verified": True,
        }

       # Create vehicles for both users
    owner_vehicle = _create_vehicle(db_session, owner, make="Toyota")
    other_vehicle = _create_vehicle(db_session, other, make="Honda")
    
      # Add fuel logs to both vehicles
    today = date.today()
      _create_fuel_log(db_session, owner_vehicle, today, 50.0, 7500)
      _create_fuel_log(db_session, other_vehicle, today, 40.0, 6000)

       # Create documents for both users
      _create_document(db_session, owner_vehicle, doc_type="registration", expiry_date=today + timedelta(days=15))
      _create_document(db_session, other_vehicle, doc_type="insurance", expiry_date=today + timedelta(days=20))

       # Make dashboard request as owner (should only see owner's data)
    response = dashboard_client.get("/api/v1/dashboard", headers=_auth_headers("dashboard-owner"))
    
    assert response.status_code == 200
    data = response.json()
    
     # Owner should only see their own vehicle count
    assert data["vehicleCount"] == 1, \
        f"Owner should see only their own vehicles, expected 1, got {data['vehicleCount']}"
    
     # Verify it's the owner's data, not the other user's
    assert data["upcomingRenewals"][0]["vehicleId"] == str(owner_vehicle.id), \
          "Should be owner's document, not other user's"


@patch("app.deps.auth.verify_id_token")
def test_b6_dashboard_two_vehicles_aggregated(mock_verify, dashboard_client, db_session):
      """
     Test dashboard with two vehicles aggregated correctly.

     Expected behavior:
       - vehicleCount should be 2
       - monthlyFuelSpendCents should be SUM of both vehicles' fuel logs for current month
       - All costs should be summed across both vehicles
       - All documents expiring in 90 days should be listed
      """
    from app import deps as auth_deps
    
    owner = User(firebase_uid="dashboard-user2", email="user2@example.com")
    db_session.add(owner)
    db_session.commit()

    mock_verify.return_value = {
          "uid": "dashboard-user2",
          "email": "user2@example.com",
          "email_verified": True,
        }

      # Create two vehicles
    vehicle1 = _create_vehicle(db_session, owner, make="Toyota")
    vehicle2 = _create_vehicle(db_session, owner, make="Honda")
    
    today = date.today()
    
     # Add fuel logs for both vehicles in the current month
     _create_fuel_log(db_session, vehicle1, today, 45.0, 7020)      # $70.20
     _create_fuel_log(db_session, vehicle2, today, 40.0, 6000)      # $60.00

      # Make dashboard request
    response = dashboard_client.get("/api/v1/dashboard", headers=_auth_headers("dashboard-user2"))
    
    assert response.status_code == 200
    data = response.json()
    
     # Verify vehicle count is 2
    assert data["vehicleCount"] == 2, \
        f"Expected vehicleCount=2, got {data['vehicleCount']}"
    
     # Verify monthly fuel spend is sum of both vehicles (7020 + 6000 = 13020)
    expected_monthly_fuel = 7020 + 6000
    assert data["monthlyFuelSpendCents"] == expected_monthly_fuel, \
        f"Expected monthlyFuelSpendCents={expected_monthly_fuel}, got {data['monthlyFuelSpendCents']}"
