"""Application configuration loaded from environment / .env (see docs/01-tech-spec.md §5)."""

from functools import lru_cache
from typing import Literal

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    # Core
    environment: Literal["local", "production"] = "local"
    api_v1_prefix: str = "/api/v1"

    # Database (Neon in prod, Docker Postgres locally)
    database_url: str = "postgresql+psycopg://drivevault:drivevault@localhost:5432/drivevault"

    # Firebase
    firebase_project_id: str = ""
    # Path to a service-account JSON file, or inline JSON. Empty in tests (auth is mocked).
    firebase_credentials_json: str = ""

    # Cloudinary (file/photo storage). API secret stays server-side only.
    cloudinary_cloud_name: str = ""
    cloudinary_api_key: str = ""
    cloudinary_api_secret: str = ""

    # CORS (comma-separated origins)
    cors_origins: str = "*"

    @property
    def cors_origins_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
