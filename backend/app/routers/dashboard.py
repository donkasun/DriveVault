"""Dashboard aggregate endpoint (Task B6)."""

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.db import get_db
from app.deps import get_current_user
from app.models.users import User
from app.schemas.documents import DashboardRead
from app.services.dashboard import get_dashboard_data

router = APIRouter(tags=["dashboard"])


@router.get("/dashboard", status_code=status.HTTP_200_OK, response_model=DashboardRead, response_model_by_alias=True)
def get_dashboard(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
     """
     GET /api/v1/dashboard
    
     Aggregated summary across all of the caller's vehicles.
     
     Returns:
         - vehicle_count: COUNT of vehicles owned by caller
         - monthly_fuel_spend_cents: SUM of fuel_logs.price_cents for current calendar month
         - total_ownership_cost_cents: fuelCents + maintenanceCents + purchaseCents
         - cost_breakdown: {fuelCents, maintenanceCents, purchaseCents}
         - upcoming_renewals: Documents expiring within 90 days (vehicleId, title, expiryDate)
     """
    data = get_dashboard_data(db, current_user)
    return data
