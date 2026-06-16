"""Shared renewal status helpers — reused by dashboard and vehicle docs_status."""

from datetime import date


def days_until(expiry_date: date, today: date) -> int:
    """Return days until expiry (negative if already overdue)."""
    return (expiry_date - today).days


def renewal_status(expiry_date: date, today: date) -> str:
    """Return 'overdue', 'soon' (0–30 days), or 'ok' (>30 days)."""
    remaining = days_until(expiry_date, today)
    if remaining < 0:
        return "overdue"
    if remaining <= 30:
        return "soon"
    return "ok"
