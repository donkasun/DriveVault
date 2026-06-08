"""FastAPI application factory and router registration (see docs/01-tech-spec.md)."""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings
from app.routers import health

settings = get_settings()


def create_app() -> FastAPI:
    app = FastAPI(title="DriveVault API", version="0.1.0")

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Public, unversioned health check.
    app.include_router(health.router)

    # Versioned API routers are registered here as they are built (Tasks A5, B1–B6).
    # Example: app.include_router(vehicles.router, prefix=settings.api_v1_prefix)

    return app


app = create_app()
