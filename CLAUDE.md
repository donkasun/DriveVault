<!-- AI AGENT WORKING AGREEMENT: This file is read automatically by Claude Code and other
     AI coding agents. It defines coding conventions, architecture rules, and guardrails
     for AI-assisted development sessions. Human contributors can ignore it. -->

# DriveVault — Working Agreement for Coding Agents

Read this before writing any code. It keeps every coding session consistent. The detailed
specs live in `docs/` — **this file is the rules; those docs are the source of truth for
decisions.**

## Source-of-truth docs (read the section relevant to your task)
- `docs/01-tech-spec.md` — stack, architecture, conventions (authoritative for tech decisions)
- `docs/02-database-schema.md` — exact tables/columns/types
- `docs/03-api-contract.md` — exact endpoint request/response shapes
- `docs/04-phase1-tasks.md` — task list; pick ONE task and do only that task

Read what your task touches, not all four every time — a task brief already carries
its requirements. Consult the schema/contract docs before changing tables or endpoints.
When the PRD and these docs disagree on a technical detail, **the docs win**.

For situational details, read on demand (not loaded every session):
- `docs/ops-notes.md` — local backend/Docker, Cloud Run deploy, machine build quirks
- `docs/ui-conventions.md` — mobile form/screen/picker conventions

---

## Golden rules
1. **Do one task at a time.** Take a single task from `04-phase1-tasks.md`, finish it
   completely (including its "Done when" tests), then stop. Don't scope-creep into the next task.
2. **Match the contracts exactly.** Table names/types come from Doc 2. Endpoint shapes come
   from Doc 3. Do not invent fields, rename columns, or change JSON keys. If something is
   missing or ambiguous, **ask — don't guess.**
3. **No new dependencies** without flagging it first. Use what Doc 1 §1 already pins.
4. **Write the tests** described in the task. A task isn't done until its tests pass.
5. **Stay in scope.** No AI, no offline/Drift sync, no Phase 2+ features during Phase 1
   (see Doc 1 §7). Don't refactor unrelated code.

---

## The stack (do not deviate)
- **Mobile:** Flutter 3.44 + Riverpod 3.x + go_router. (Drift/offline is a LATER phase — not now.)
- **Backend:** FastAPI 0.115 + Python 3.12 + SQLAlchemy 2 + Alembic.
- **DB:** PostgreSQL 16 (Neon in prod, Docker locally). pgvector only from Phase 6.
- **Firebase:** Auth + FCM only. **Never** use Firestore as the database.
- **File storage:** Cloudinary (free tier). Clients upload directly via a backend-signed
  request; the backend stores only the returned `secure_url`. (Firebase Storage is NOT used —
  it requires the paid Blaze plan.)
- **Hosting:** Google Cloud Run (`--min-instances=0`, always-free tier) + Neon (DB).
- **AI (Phases 3/4/6 only):** Gemini free tier behind an `AIProvider` interface; ML Kit for
  on-device OCR. **No on-device LLM / no bundled model** (keeps app size small).

---

## Conventions (enforced)
- **IDs:** UUID v4 primary keys (`id`), `gen_random_uuid()`.
- **Timestamps:** every table has `created_at` / `updated_at` (`timestamptz`, UTC).
- **Money:** integer **cents** (`*_cents`) + 3-letter `currency`. **Never floats for money.**
- **Mileage/odometer:** integer kilometres.
- **Naming:** `snake_case` in Python/SQL · `camelCase` in Dart · `lowerCamelCase` JSON keys.
- **API:** REST, JSON, plural nouns (`/vehicles`, `/fuel-logs`), all under `/api/v1`.
- **Errors:** FastAPI returns `{ "detail": "<message>" }` with correct HTTP status.
- **Ownership:** a user only sees their own data. Another user's resource → **404** (not 403).
- **Auth:** every protected endpoint verifies the `Authorization: Bearer <Firebase ID token>`
  via Firebase Admin SDK and resolves the `users` row by `firebase_uid`. Backend stores no passwords.

---

## Architecture boundaries (keep units small & single-purpose)
**Backend**
- `routers/` parse requests + call services. **No SQL or business logic in routers.**
- `services/` hold business logic + DB access (SQLAlchemy). Independently testable.
- `schemas/` (Pydantic) define the only shapes that cross the wire.
- File bytes **never** pass through FastAPI — clients upload to Cloudinary (using a
  backend-signed request) and send back the resulting `secure_url`.

**Mobile**
- Per feature: `data/` (repository + api) → `domain/` (models) → `presentation/` (screens, providers, widgets).
- **Only repositories call the API.** Providers expose state; widgets never call the API directly.
- The API base URL comes from `--dart-define=API_BASE_URL=...` (never hard-coded).

If a file grows past a few hundred lines, split it — it's doing too much.

---

## Definition of done (every task)
- [ ] Matches Doc 2 (schema) and Doc 3 (API contract) exactly.
- [ ] The task's "Done when" tests are written and **passing**.
- [ ] No secrets committed (`.env`, Firebase service-account JSON, `google-services.json`).
- [ ] No out-of-scope changes; no unpinned new dependencies.
- [ ] Lint/format clean (`ruff`/`black` for Python; `dart format` for Flutter).

When unsure, stop and ask. A small clarifying question is cheaper than a wrong implementation.

---

## Learned User Preferences

- Do not commit changes unless explicitly asked.
- Email verification uses a **soft nudge, not a hard gate**: after email/password sign-up the user lands on `/home` like everyone else; a per-session dismissible `VerifyEmailBanner` on the dashboard prompts them to verify (Resend / I've verified actions). A Firebase verification email is still sent on sign-up. (The earlier hard `/verify-email` gate was removed; the 48h purge-unverified idea was rejected.)
- Use isolated git worktrees under `.worktrees/` for parallel Phase 1 task branches (e.g. `task/backend-models`, `task/mobile-auth`).
- When pointed at a plan in `docs/superpowers/plans/`, implement that plan rather than improvising.
- Configure project MCP for Claude Code via repo-root `.mcp.json`; Cursor MCP plugins are separate and not shared automatically.
- **Model delegation (pay special attention to cost):** cost discipline is a first-class concern on every task. Keep the main session (Opus) for planning, contract/schema decisions, and review — and offload the actual work to subagents, choosing the model by task complexity:
  - **Coding/implementation tasks → Sonnet subagents** (e.g. writing a router/service, building a screen, implementing a well-specified task from `07-fuel-prefs-tasks.md`). Give the subagent the exact task + the relevant doc sections.
  - **Small mechanical tasks → Haiku subagents** (file moves/renames/deletes, `grep`/search/locate, simple find-and-replace, listing/counting).
  - **Never use Fable** for any task — it is not approved for this project.
  - Use judgement: anything ambiguous, cross-cutting, or contract-affecting stays in the main session; only dispatch once the task is well-defined. Default to the cheapest model that can do the job correctly.
- **Test scope:** run only the tests relevant to the feature(s) being changed — not the full battery — for isolated changes (e.g. `flutter test test/features/fuel`, or the specific backend test module). Reserve a full-suite run for broad/cross-cutting changes or a final pre-merge check. Subagents fixing one feature should likewise run just that feature's tests + a scoped `analyze`.
- **Mobile UI conventions** (form headers, pickers, specific forms, navigation) live in `docs/ui-conventions.md` — read it when building or editing a mobile screen.

## Learned Workspace Facts

- **Operational details** (local backend/Docker, Cloud Run deploy, machine build quirks, MCP) live in `docs/ops-notes.md` — read it when doing the relevant operation.
- Email verification was originally a hard gate (task C2d, plan `docs/superpowers/plans/2026-06-09-email-verification-gate.md`) but was later replaced by the soft `VerifyEmailBanner` nudge — see `docs/superpowers/specs/2026-06-13-fuel-economy-quick-entry-verify-banner-design.md`.
