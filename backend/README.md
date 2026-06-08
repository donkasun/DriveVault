# DriveVault Backend (FastAPI)

See `../docs/01-tech-spec.md` for architecture and `../docs/03-api-contract.md` for the API.

## Local setup

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"

cp .env.example .env        # edit as needed

# Start local Postgres (optional for /health; required once models exist)
docker compose up -d

# Run the API
uvicorn app.main:app --reload
# → http://localhost:8000/health  ->  {"status":"ok"}
# → http://localhost:8000/docs    (Swagger UI)
```

## Tests

```bash
pytest
```

## Layout
```
app/
  main.py        # app factory + router registration
  core/          # config, db session
  models/        # SQLAlchemy models (Task A3)
  schemas/       # Pydantic request/response (per resource)
  routers/       # one file per resource
  services/      # business logic (no SQL in routers)
  deps.py        # shared dependencies (get_db, get_current_user)
tests/           # pytest
```

## Build status
- ✅ A1 — scaffold + `/health`
- ✅ A2 — config + DB session + docker-compose
- ⬜ next: A3 (models + Alembic), A4 (Firebase auth), A5 (`/me`) … see `../docs/04-phase1-tasks.md`
