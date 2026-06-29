# DriveVault — Operational Notes (read on demand)

Situational facts for deploys, local backend, and machine-specific build quirks.
**Not loaded every session** — read this only when doing the relevant operation.
CLAUDE.md links here; keep the day-to-day rules there, the trivia here.

## Local backend (Docker)

- **After any backend code change, restart the container** so new code takes effect:
  `docker compose restart backend` (or `docker compose up --build backend -d` if
  dependencies changed). The running container does not pick up file changes
  automatically.
- Local Docker Postgres may bind host port **5433** when macOS Postgres already
  occupies 5432.
- **iOS Simulator runs against the local Docker backend (`localhost:8000`).** No
  `--dart-define=API_BASE_URL` is set, so the app defaults to `localhost:8000`. The
  local Docker Postgres (5433) is the test DB — it has the 2015 Toyota Hilux and CR
  Test user data. Neon is production only. Keep the local backend running
  (`docker compose up`) when using the simulator.

## Deploy (Google Cloud Run)

- Backend hosting is Cloud Run (`--min-instances=0`) — always-free tier, ~1-3s cold
  starts. Live URL: `https://drivevault-backend-250609806849.us-central1.run.app`.
  Deploy via `gcloud run deploy` or push to `main` (GitHub Actions auto-deploys on
  `backend/**` changes).
- GCP deploy service account: `github-deployer@drivevault-app.iam.gserviceaccount.com`
  (roles: `run.admin`, `artifactregistry.writer`, `iam.serviceAccountUser`). Key
  stored as `GCP_SA_KEY` GitHub secret.
- When building the Docker image locally on Apple Silicon (arm64), always pass
  `--platform=linux/amd64` — Cloud Run requires amd64 and rejects an arm64 image with
  a manifest type error.
- Firebase service-account credentials are stored in GCP Secret Manager as
  `firebase-credentials` (project `drivevault-app`), injected into Cloud Run as
  `FIREBASE_CREDENTIALS_JSON`.

## Machine-specific build quirks

- **`dart run build_runner` requires `--force-jit` on this machine** (Homebrew Flutter
  SDK is missing the `gen_snapshot` binary — only a `.sym` stub is present). Always run:
  `dart run build_runner build --delete-conflicting-outputs --force-jit`

## MCP / tooling

- Claude Code Neon MCP is configured in repo-root `.mcp.json` (OAuth at
  `https://mcp.neon.tech/mcp`, safe to commit). No Render MCP (Render replaced by
  Cloud Run). Cursor MCP plugins are separate and not shared automatically.
