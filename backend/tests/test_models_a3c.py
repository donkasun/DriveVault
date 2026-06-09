"""Task A3c — maintenance_schedules and reminders models + migration."""

from datetime import date

from sqlalchemy import inspect, select

from app.models.reminders import Reminder
from app.models.schedules import MaintenanceSchedule
from app.models.users import User
from app.models.vehicles import Vehicle


def test_a3c_migration_creates_schedule_and_reminder_tables(migrated_engine):
    tables = inspect(migrated_engine).get_table_names()
    assert "maintenance_schedules" in tables
    assert "reminders" in tables


def test_a3c_insert_schedule_and_reminder(db_session):
    user = User(firebase_uid="uid-a3c", email="a3c@example.com")
    db_session.add(user)
    db_session.flush()

    vehicle = Vehicle(user_id=user.id, make="Ford", model="Ranger")
    db_session.add(vehicle)
    db_session.flush()

    schedule = MaintenanceSchedule(
        vehicle_id=vehicle.id,
        service_type="Oil Change",
        interval_months=6,
        interval_km=5000,
    )
    db_session.add(schedule)
    db_session.flush()

    reminder = Reminder(
        vehicle_id=vehicle.id,
        schedule_id=schedule.id,
        reminder_type="service_due",
        title="Oil change due",
        due_date=date(2026, 12, 1),
    )
    db_session.add(reminder)
    db_session.commit()

    loaded_schedule = db_session.scalar(
        select(MaintenanceSchedule).where(MaintenanceSchedule.vehicle_id == vehicle.id)
    )
    loaded_reminder = db_session.scalar(
        select(Reminder).where(Reminder.vehicle_id == vehicle.id)
    )

    assert loaded_schedule is not None
    assert loaded_schedule.interval_months == 6
    assert loaded_reminder is not None
    assert loaded_reminder.schedule_id == loaded_schedule.id
    assert loaded_reminder.status == "pending"
