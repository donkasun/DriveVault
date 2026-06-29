"""Tests for GET /api/v1/activity endpoint (Task 13)."""

from datetime import date
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
def activity_client(db_session):
    app = create_app()

    def _override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = _override_get_db
    with TestClient(app) as client:
        yield client
    app.dependency_overrides.clear()


@pytest.fixture
def activity_user(db_session):
    user = User(firebase_uid="activity-owner", email="activity@example.com")
    db_session.add(user)
    db_session.commit()
    return user


@pytest.fixture
def activity_vehicle(db_session, activity_user):
    vehicle = Vehicle(user_id=activity_user.id, make="Honda", model="Civic", year=2022)
    db_session.add(vehicle)
    db_session.commit()
    db_session.refresh(vehicle)
    return vehicle


def _auth_headers() -> dict[str, str]:
    return {"Authorization": "Bearer activity-token"}


def _mock_verify(mock_verify):
    mock_verify.return_value = {
        "uid": "activity-owner",
        "email": "activity@example.com",
        "email_verified": True,
    }


def _create_document(
    db_session,
    vehicle: Vehicle,
    *,
    title: str,
    doc_type: str,
    issue_date: date | None = None,
):
    doc = Document(
        vehicle_id=vehicle.id,
        doc_type=doc_type,
        title=title,
        storage_url="https://example.com/doc.pdf",
        storage_public_id="vehicles/documents/doc-1",
        mime_type="application/pdf",
        file_size_bytes=12345,
        issue_date=issue_date,
        expiry_date=issue_date,
    )
    db_session.add(doc)
    db_session.commit()
    db_session.refresh(doc)
    return doc


def test_activity_endpoint_returns_list(activity_client, activity_user):
    """GET /api/v1/activity returns a list (may be empty on fresh DB)."""
    with patch("firebase_admin.auth.verify_id_token") as mock_verify:
        _mock_verify(mock_verify)
        resp = activity_client.get("/api/v1/activity", headers=_auth_headers())
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


def test_activity_endpoint_respects_limit(
    activity_client, activity_user, activity_vehicle, db_session
):
    """limit param caps the result."""
    # Insert 3 fuel logs and 3 maintenance records (6 total)
    for i in range(3):
        db_session.add(
            FuelLog(
                vehicle_id=activity_vehicle.id,
                date=date(2024, 1, i + 1),
                liters=Decimal("40.000"),
                price_cents=5000,
                odometer=10000 + i * 100,
                is_full_tank=True,
            )
        )
        db_session.add(
            MaintenanceRecord(
                vehicle_id=activity_vehicle.id,
                date=date(2024, 2, i + 1),
                service_type="Oil Change",
                cost_cents=3000,
            )
        )
    db_session.commit()

    with patch("firebase_admin.auth.verify_id_token") as mock_verify:
        _mock_verify(mock_verify)
        resp = activity_client.get("/api/v1/activity?limit=2", headers=_auth_headers())
    assert resp.status_code == 200
    assert len(resp.json()) <= 2


def test_activity_items_have_required_fields(
    activity_client, activity_user, activity_vehicle, db_session
):
    """Each item has the unified fields and type-specific document details."""
    db_session.add(
        FuelLog(
            vehicle_id=activity_vehicle.id,
            date=date(2024, 3, 15),
            liters=Decimal("35.500"),
            price_cents=4200,
            odometer=20000,
            is_full_tank=False,
        )
    )
    db_session.add(
        MaintenanceRecord(
            vehicle_id=activity_vehicle.id,
            date=date(2024, 3, 10),
            service_type="Tyre Rotation",
            cost_cents=1500,
        )
    )
    _create_document(
        db_session,
        activity_vehicle,
        title="Insurance Policy",
        doc_type="insurance",
        issue_date=date(2024, 3, 12),
    )
    db_session.commit()

    with patch("firebase_admin.auth.verify_id_token") as mock_verify:
        _mock_verify(mock_verify)
        resp = activity_client.get("/api/v1/activity", headers=_auth_headers())

    assert resp.status_code == 200
    items = resp.json()
    assert len(items) >= 2

    for item in items:
        assert "type" in item
        assert "id" in item
        assert "vehicleId" in item
        assert "vehicleLabel" in item
        assert "date" in item
        assert "amountCents" in item
        assert "label" in item
        assert "createdAt" in item
        assert item["type"] in ("fuel", "maintenance", "document")

    fuel_items = [i for i in items if i["type"] == "fuel"]
    maintenance_items = [i for i in items if i["type"] == "maintenance"]
    document_items = [i for i in items if i["type"] == "document"]

    for fi in fuel_items:
        assert fi["amountCents"] == 4200
        assert "isFullTank" in fi
        assert "odometer" in fi

    for mi in maintenance_items:
        assert mi["amountCents"] == 1500
        assert mi["label"] == "Tyre Rotation"
        assert "source" in mi

    for di in document_items:
        assert di["amountCents"] is None
        assert di["label"] == "Insurance Policy"
        assert di["docType"] == "insurance"
        assert di["title"] == "Insurance Policy"
        assert di["storageUrl"] == "https://example.com/doc.pdf"
        assert di["createdAt"]


def test_activity_includes_documents_in_date_order(
    activity_client, activity_user, activity_vehicle, db_session
):
    """Document entries are merged into the same newest-first activity list."""
    db_session.add(
        FuelLog(
            vehicle_id=activity_vehicle.id,
            date=date(2024, 3, 15),
            liters=Decimal("35.500"),
            price_cents=4200,
            odometer=20000,
            is_full_tank=False,
        )
    )
    db_session.add(
        MaintenanceRecord(
            vehicle_id=activity_vehicle.id,
            date=date(2024, 3, 10),
            service_type="Tyre Rotation",
            cost_cents=1500,
        )
    )
    _create_document(
        db_session,
        activity_vehicle,
        title="Insurance Policy",
        doc_type="insurance",
        issue_date=date(2024, 3, 12),
    )
    db_session.commit()

    with patch("firebase_admin.auth.verify_id_token") as mock_verify:
        _mock_verify(mock_verify)
        resp = activity_client.get("/api/v1/activity", headers=_auth_headers())

    assert resp.status_code == 200
    items = resp.json()
    assert [item["type"] for item in items[:3]] == [
        "fuel",
        "document",
        "maintenance",
    ]
    assert items[1]["title"] == "Insurance Policy"
    assert items[1]["date"] == "2024-03-12"


def test_activity_isolation(activity_client, activity_user, db_session):
    """User only sees their own vehicles' activity."""
    other = User(firebase_uid="activity-other", email="other@example.com")
    db_session.add(other)
    db_session.commit()

    other_vehicle = Vehicle(user_id=other.id, make="BMW", model="X5", year=2021)
    db_session.add(other_vehicle)
    db_session.commit()
    db_session.refresh(other_vehicle)

    db_session.add(
        FuelLog(
            vehicle_id=other_vehicle.id,
            date=date(2024, 4, 1),
            liters=Decimal("50.000"),
            price_cents=9000,
            odometer=5000,
        )
    )
    db_session.commit()

    with patch("firebase_admin.auth.verify_id_token") as mock_verify:
        _mock_verify(mock_verify)
        resp = activity_client.get("/api/v1/activity", headers=_auth_headers())

    assert resp.status_code == 200
    # activity_user has no vehicles, so result is empty — other user's data not leaked
    assert resp.json() == []
