"""Vehicles and nested fuel endpoints (Tasks B1-B3)."""

from datetime import date
from uuid import UUID

from fastapi import APIRouter, Depends, Query, Response, status
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.deps import get_current_user
from app.models.users import User
from app.schemas.fuel_logs import FuelLogCreate, FuelLogRead, FuelLogUpdate, FuelStatsRead
from app.schemas.vehicles import VehicleCreate, VehicleRead, VehicleUpdate
from app.services import fuel_logs as fuel_log_service
from app.services import vehicles as vehicle_service

router = APIRouter(tags=["vehicles"])


@router.get("/vehicles", response_model=list[VehicleRead], response_model_by_alias=True)
def list_vehicles(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return vehicle_service.list_vehicles(db, current_user)


@router.post(
    "/vehicles",
    response_model=VehicleRead,
    response_model_by_alias=True,
    status_code=status.HTTP_201_CREATED,
)
def create_vehicle(
    payload: VehicleCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return vehicle_service.create_vehicle(db, current_user, payload)


@router.get("/vehicles/{vehicle_id}", response_model=VehicleRead, response_model_by_alias=True)
def get_vehicle(
    vehicle_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return vehicle_service.get_vehicle_read_for_user(db, current_user, vehicle_id)


@router.patch("/vehicles/{vehicle_id}", response_model=VehicleRead, response_model_by_alias=True)
def update_vehicle(
    vehicle_id: UUID,
    payload: VehicleUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return vehicle_service.update_vehicle(db, current_user, vehicle_id, payload)


@router.delete("/vehicles/{vehicle_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_vehicle(
    vehicle_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    vehicle_service.delete_vehicle(db, current_user, vehicle_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/vehicles/{vehicle_id}/fuel-logs", response_model=list[FuelLogRead])
def list_fuel_logs(
    vehicle_id: UUID,
    from_date: date | None = Query(default=None, alias="from"),
    to_date: date | None = Query(default=None, alias="to"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return fuel_log_service.list_fuel_logs(db, current_user, vehicle_id, from_date, to_date)


@router.post(
    "/vehicles/{vehicle_id}/fuel-logs",
    response_model=FuelLogRead,
    status_code=status.HTTP_201_CREATED,
)
def create_fuel_log(
    vehicle_id: UUID,
    payload: FuelLogCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return fuel_log_service.create_fuel_log(db, current_user, vehicle_id, payload)


@router.patch("/fuel-logs/{fuel_log_id}", response_model=FuelLogRead)
def update_fuel_log(
    fuel_log_id: UUID,
    payload: FuelLogUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return fuel_log_service.update_fuel_log(db, current_user, fuel_log_id, payload)


@router.delete("/fuel-logs/{fuel_log_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_fuel_log(
    fuel_log_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    fuel_log_service.delete_fuel_log(db, current_user, fuel_log_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/vehicles/{vehicle_id}/fuel-stats", response_model=FuelStatsRead)
def get_fuel_stats(
    vehicle_id: UUID,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return fuel_log_service.compute_fuel_stats(db, current_user, vehicle_id)
