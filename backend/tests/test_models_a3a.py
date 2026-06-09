"""Task A3a — users and vehicles models + migration."""

from datetime import date

from sqlalchemy import inspect, select

from app.models.users import User
from app.models.vehicles import Vehicle


def test_a3a_migration_creates_users_and_vehicles_tables(migrated_engine):
    tables = inspect(migrated_engine).get_table_names()
    assert "users" in tables
    assert "vehicles" in tables


def test_a3a_insert_user_and_vehicle(db_session):
    user = User(firebase_uid="uid-a3a", email="a3a@example.com")
    db_session.add(user)
    db_session.flush()

    vehicle = Vehicle(user_id=user.id, make="Toyota", model="Hilux", year=2020)
    db_session.add(vehicle)
    db_session.commit()

    loaded_user = db_session.scalar(select(User).where(User.firebase_uid == "uid-a3a"))
    loaded_vehicle = db_session.scalar(select(Vehicle).where(Vehicle.make == "Toyota"))

    assert loaded_user is not None
    assert loaded_user.email == "a3a@example.com"
    assert loaded_vehicle is not None
    assert loaded_vehicle.model == "Hilux"
    assert loaded_vehicle.user_id == loaded_user.id
    assert loaded_vehicle.year == 2020
    assert isinstance(loaded_vehicle.purchase_date, date) or loaded_vehicle.purchase_date is None
