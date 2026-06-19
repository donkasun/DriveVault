"""Tests for the daily reminder processing service."""

from __future__ import annotations

import uuid
from datetime import UTC, date, datetime, timedelta

import pytest
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.documents import Document
from app.models.reminders import Reminder
from app.models.user_documents import UserDocument
from app.models.users import User
from app.models.vehicles import Vehicle


def _make_user(db: Session, fcm: str | None = "fcm-token-abc") -> User:
    user = User(
        firebase_uid=f"uid-{uuid.uuid4()}",
        email="remind@test.com",
        renewal_reminders_enabled=True,
        fcm_token=fcm,
    )
    db.add(user)
    db.flush()
    return user


def _make_vehicle(db: Session, user: User) -> Vehicle:
    v = Vehicle(user_id=user.id, make="Toyota", model="Hilux")
    db.add(v)
    db.flush()
    return v


def test_creates_reminder_for_expiring_credential(db_session: Session, monkeypatch):
    """Credential expiring in exactly 30 days → reminder row created + FCM called."""
    from app.services.reminder_processing import process_reminders

    sent_messages = []

    def _mock_send(message):
        sent_messages.append(message)

    monkeypatch.setattr("app.services.reminder_processing._send_fcm", _mock_send)

    user = _make_user(db_session)
    expiry = date.today() + timedelta(days=30)
    cred = UserDocument(user_id=user.id, doc_type="license", expiry_date=expiry)
    db_session.add(cred)
    db_session.commit()

    result = process_reminders(db_session)
    assert result["sent"] >= 1

    reminders = list(db_session.scalars(
        select(Reminder).where(Reminder.user_document_id == cred.id)
    ))
    assert len(reminders) == 1
    assert reminders[0].due_date == expiry - timedelta(days=30)
    assert reminders[0].status == "sent"
    assert len(sent_messages) == 1


def test_idempotent_no_duplicate_reminders(db_session: Session, monkeypatch):
    """Running process_reminders twice for the same item only creates one reminder."""
    from app.services.reminder_processing import process_reminders

    monkeypatch.setattr("app.services.reminder_processing._send_fcm", lambda m: None)

    user = _make_user(db_session)
    expiry = date.today() + timedelta(days=7)
    cred = UserDocument(user_id=user.id, doc_type="permit", expiry_date=expiry)
    db_session.add(cred)
    db_session.commit()

    process_reminders(db_session)
    process_reminders(db_session)

    reminders = list(db_session.scalars(
        select(Reminder).where(Reminder.user_document_id == cred.id)
    ))
    assert len(reminders) == 1


def test_creates_reminder_for_vehicle_document(db_session: Session, monkeypatch):
    """Vehicle document expiring in 1 day → reminder created."""
    from app.services.reminder_processing import process_reminders

    monkeypatch.setattr("app.services.reminder_processing._send_fcm", lambda m: None)

    user = _make_user(db_session)
    v = _make_vehicle(db_session, user)
    expiry = date.today() + timedelta(days=1)
    doc = Document(
        vehicle_id=v.id,
        doc_type="insurance",
        title="2026 Insurance",
        storage_url="https://example.com/doc.pdf",
        expiry_date=expiry,
    )
    db_session.add(doc)
    db_session.commit()

    result = process_reminders(db_session)
    assert result["sent"] >= 1
    reminders = list(db_session.scalars(select(Reminder).where(Reminder.document_id == doc.id)))
    assert len(reminders) == 1


def test_skips_fcm_when_reminders_disabled(db_session: Session, monkeypatch):
    """FCM is not sent when user has renewalRemindersEnabled = False."""
    from app.services.reminder_processing import process_reminders

    sent = []
    monkeypatch.setattr("app.services.reminder_processing._send_fcm", lambda m: sent.append(m))

    user = _make_user(db_session)
    user.renewal_reminders_enabled = False
    db_session.commit()

    expiry = date.today() + timedelta(days=7)
    cred = UserDocument(user_id=user.id, doc_type="license", expiry_date=expiry)
    db_session.add(cred)
    db_session.commit()

    process_reminders(db_session)
    assert len(sent) == 0
