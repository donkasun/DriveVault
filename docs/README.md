# DriveVault — Documentation Index

**DriveVault** is an AI-powered vehicle ownership platform — the single source of truth for a
vehicle's maintenance, fuel, expenses, and documents, with AI added in later phases.
*From first mile to resale.*

This folder holds everything needed to build the app. Read the docs in the order below.

---

## Read in this order

| # | Doc | What it gives you |
|---|---|---|
| 0 | [`DriveVault_PRD.md`](./DriveVault_PRD.md) | **The vision.** Problem, users, 6-phase roadmap, feature list. Read first for *why* and *what*. |
| 1 | [`01-tech-spec.md`](./01-tech-spec.md) | **The decisions.** Locked stack, architecture, auth/file flows, repo layout, env, conventions, AI strategy, out-of-scope. Authoritative for tech choices. |
| 2 | [`02-database-schema.md`](./02-database-schema.md) | **The data model.** Full schema for all 6 phases — exact tables, columns, types, FKs, indexes + ERD. |
| 3 | [`03-api-contract.md`](./03-api-contract.md) | **The API.** Phase 1 REST endpoints — every request/response shape, status codes, auth & ownership rules. |
| 4 | [`04-phase1-tasks.md`](./04-phase1-tasks.md) | **The build plan.** Phase 1 split into ~24 small, ordered, testable tasks. Do one at a time. |

Plus, at the repo root: [`../CLAUDE.md`](../CLAUDE.md) — the **working agreement** (rules) every
coding agent follows. The docs above are the *source of truth*; `CLAUDE.md` is the *rules*.

> **Precedence:** when the PRD and the spec docs disagree on a technical detail, the **spec docs win**.

---

## TL;DR architecture

```
Flutter (Riverpod)  →  FastAPI (Render)  →  Neon PostgreSQL 16 (+ pgvector @ Phase 6)
                    ↘  Firebase: Auth + Storage + Push (FCM)
AI (Phases 3/4/6)   →  Gemini free tier behind a swappable AIProvider; ML Kit OCR on-device
```

- **Source of truth for structured data:** Neon Postgres (never Firestore).
- **Firebase:** auth, file storage, push only.
- **MVP is online-first;** offline/Drift sync is a deferred later task.
- **No on-device LLM** — keeps the app download small.

---

## How to build with a coding agent (incl. smaller models)

1. Keep **`CLAUDE.md` + Docs 1–3** in context at all times (the fixed rules + contracts).
2. Hand the agent **one task at a time** from Doc 4 (e.g. *"Do Task B1"*).
3. Require the task's **"Done when" tests** before moving on.
4. Build the **backend fully first** (Docs 2 + 3 are a fixed contract), then the mobile app.

Suggested order: `A1→A5 → B1→B7 → C1→C3 → D1→D6 → E1` (see Doc 4).

---

## Status

- ✅ Specs complete for **Phase 1 (Foundation MVP)** — ready to implement.
- 🗓️ Phases 2–6 are designed at the schema level; each gets its own API/task docs when started.
