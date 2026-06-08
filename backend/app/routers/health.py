"""Public health check used by Render and uptime pings (see docs/03-api-contract.md)."""

from fastapi import APIRouter

router = APIRouter(tags=["health"])


@router.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
