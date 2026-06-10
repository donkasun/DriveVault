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
  models/        # SQLAlchemy models
  schemas/       # Pydantic request/response (per resource)
  routers/       # one file per resource
  services/      # business logic (no SQL in routers)
  deps.py        # shared dependencies (get_db, get_current_user)
tests/           # pytest
```

---

## Production deployment (Cloud Run + Neon)

### Infrastructure

| Resource | Details |
|---|---|
| **Hosting** | Google Cloud Run, project `drivevault-app`, region `us-central1` |
| **Service name** | `drivevault-backend` |
| **Live URL** | `https://drivevault-backend-250609806849.us-central1.run.app` |
| **Database** | Neon PostgreSQL 16, project `silent-haze-14400595` (`drivevault`) |
| **Image registry** | `us-central1-docker.pkg.dev/drivevault-app/drivevault/backend` |
| **Firebase credentials** | GCP Secret Manager secret `firebase-credentials` (project `drivevault-app`) |
| **Deploy SA** | `github-deployer@drivevault-app.iam.gserviceaccount.com` |

### Auto-deploy (CI/CD)

Pushing to `main` with any change under `backend/**` triggers
`.github/workflows/deploy-backend.yml`, which builds and deploys automatically.

Required GitHub secret: `GCP_SA_KEY` — JSON key for the `github-deployer` service account
(roles: `run.admin`, `artifactregistry.writer`, `iam.serviceAccountUser`).

### Manual deploy

```bash
# From repo root — MUST use --platform=linux/amd64 on Apple Silicon
docker build --platform=linux/amd64 \
  -t us-central1-docker.pkg.dev/drivevault-app/drivevault/backend:latest \
  backend/

docker push us-central1-docker.pkg.dev/drivevault-app/drivevault/backend:latest

gcloud run deploy drivevault-backend \
  --image=us-central1-docker.pkg.dev/drivevault-app/drivevault/backend:latest \
  --region=us-central1 \
  --project=drivevault-app \
  --quiet
```

> **Apple Silicon note:** Cloud Run requires `linux/amd64`. Building without
> `--platform=linux/amd64` on an M-series Mac produces an arm64 image that Cloud Run
> rejects with a manifest type error.

### Environment variables (set on the Cloud Run service)

| Variable | Source |
|---|---|
| `ENVIRONMENT` | `production` |
| `DATABASE_URL` | Neon connection string (set on service) |
| `FIREBASE_PROJECT_ID` | `drivevault-app` |
| `FIREBASE_CREDENTIALS_JSON` | Injected from Secret Manager `firebase-credentials:latest` |
| `CLOUDINARY_CLOUD_NAME` | Set on service |
| `CLOUDINARY_API_KEY` | Set on service |
| `CLOUDINARY_API_SECRET` | Set on service |
| `CORS_ORIGINS` | `*` (tighten before public launch) |

### Migrations

Alembic runs automatically at container startup (`alembic upgrade head` in the Dockerfile
`CMD`). It is idempotent — safe to run on every deploy. To run manually against Neon:

```bash
DATABASE_URL="<neon-connection-string>" alembic upgrade head
```

### Logs

```bash
gcloud run services logs read drivevault-backend \
  --region=us-central1 --project=drivevault-app --limit=50
```
