"""Daily reminder scan: find expiring docs/credentials, insert reminders, send FCM."""

from __future__ import annotations

import logging
from datetime import date, timedelta
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.documents import Document
from app.models.reminders import Reminder
from app.models.user_documents import DOC_TYPE_LABELS as _DOC_TYPE_LABELS
from app.models.user_documents import UserDocument
from app.models.users import User
from app.models.vehicles import Vehicle

logger = logging.getLogger(__name__)

_THRESHOLDS = [30, 7, 1]  # days before expiry


def _send_fcm(message: dict[str, Any]) -> bool:
    """Send one FCM message via Firebase Admin SDK. Returns True on success. Swapped out in tests."""
    try:
        from firebase_admin import messaging

        fcm_message = messaging.Message(
            notification=messaging.Notification(
                title=message["title"],
                body=message["body"],
            ),
            data=message.get("data", {}),
            token=message["token"],
        )
        messaging.send(fcm_message)
        return True
    except Exception as exc:
        logger.warning("FCM send failed: %s", exc)
        return False


def _reminder_exists(db: Session, *, document_id=None, user_document_id=None, due_date: date) -> bool:
    assert document_id is not None or user_document_id is not None, \
        "_reminder_exists requires at least one of document_id or user_document_id"
    stmt = select(Reminder).where(
        Reminder.due_date == due_date,
        Reminder.status.in_(("sent", "pending")),
    )
    if document_id is not None:
        stmt = stmt.where(Reminder.document_id == document_id)
    else:
        stmt = stmt.where(Reminder.user_document_id == user_document_id)
    return db.scalar(stmt) is not None


def process_reminders(db: Session) -> dict[str, int]:
    """Scan both tables for items expiring in exactly 30/7/1 days. Idempotent."""
    today = date.today()
    processed = sent = skipped = 0

    # ── vehicle documents ────────────────────────────────────────────────────
    for threshold in _THRESHOLDS:
        target_date = today + timedelta(days=threshold)
        docs: list[Document] = list(
            db.scalars(
                select(Document).where(
                    Document.expiry_date == target_date,
                    Document.expiry_date.isnot(None),
                )
            )
        )
        for doc in docs:
            processed += 1
            due_date = target_date
            if _reminder_exists(db, document_id=doc.id, due_date=due_date):
                skipped += 1
                continue

            # look up vehicle owner
            vehicle = db.get(Vehicle, doc.vehicle_id)
            if vehicle is None:
                skipped += 1
                continue
            user = db.get(User, vehicle.user_id)
            if user is None:
                skipped += 1
                continue

            wants_fcm = user.renewal_reminders_enabled and bool(user.fcm_token)
            reminder = Reminder(
                vehicle_id=doc.vehicle_id,
                document_id=doc.id,
                reminder_type="document_expiry",
                title=f"{doc.title} expiring in {threshold} day(s)",
                due_date=due_date,
                status="pending",
            )
            db.add(reminder)
            db.flush()

            if wants_fcm:
                if _send_fcm({
                    "token": user.fcm_token,
                    "title": "Renewal Reminder",
                    "body": f"{doc.title} expires in {threshold} day(s).",
                    "data": {"type": "document_expiry", "docType": doc.doc_type},
                }):
                    reminder.status = "sent"
            sent += 1

    # ── user driving credentials ─────────────────────────────────────────────
    for threshold in _THRESHOLDS:
        target_date = today + timedelta(days=threshold)
        creds: list[UserDocument] = list(
            db.scalars(
                select(UserDocument).where(
                    UserDocument.expiry_date == target_date,
                    UserDocument.expiry_date.isnot(None),
                )
            )
        )
        for cred in creds:
            processed += 1
            due_date = target_date
            if _reminder_exists(db, user_document_id=cred.id, due_date=due_date):
                skipped += 1
                continue

            user = db.get(User, cred.user_id)
            if user is None:
                skipped += 1
                continue

            label = _DOC_TYPE_LABELS.get(cred.doc_type, cred.doc_type)
            wants_fcm = user.renewal_reminders_enabled and bool(user.fcm_token)
            reminder = Reminder(
                user_document_id=cred.id,
                reminder_type="document_expiry",
                title=f"{label} expiring in {threshold} day(s)",
                due_date=due_date,
                status="pending",
            )
            db.add(reminder)
            db.flush()

            if wants_fcm:
                if _send_fcm({
                    "token": user.fcm_token,
                    "title": "Renewal Reminder",
                    "body": f"Your {label} expires in {threshold} day(s).",
                    "data": {"type": "credential_expiry", "docType": cred.doc_type},
                }):
                    reminder.status = "sent"
            sent += 1

    db.commit()
    return {"processed": processed, "sent": sent, "skipped": skipped}
