"""FastAPI application factory and router registration (see docs/01-tech-spec.md)."""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings
from app.core.firebase import init_firebase
from app.routers import health, me

settings = get_settings()


def create_app() -> FastAPI:
    init_firebase()

    app = FastAPI(title="DriveVault API", version="0.1.0")

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(health.router)
    app.include_router(me.router, prefix=settings.api_v1_prefix)

    return app


app = create_app()
