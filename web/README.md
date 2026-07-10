# DriveVault Web

Next.js (App Router) app that will host:

1. **Public / compliance site** — privacy, terms, support, landing
2. **DriveVault REST API** — `/api/v1/*` (migrating from FastAPI on Cloud Run)

## Docs

- [Best practices](./docs/best-practices.md) — Next.js, API, auth, DB conventions
- [Migration plan](./docs/migration-plan.md) — FastAPI → Next.js phased plan
- Repo contracts: `../docs/03-api-contract.md`, `../docs/02-database-schema.md`

## Getting started

```bash
pnpm install
cp .env.example .env.local   # fill in secrets
pnpm dev
```

Open [http://localhost:3000](http://localhost:3000).

Use **pnpm only** — do not commit `package-lock.json` or `yarn.lock`.

## Scripts

| Command | Purpose |
|---|---|
| `pnpm dev` | Dev server (Turbopack) |
| `pnpm build` | Production build |
| `pnpm start` | Start production server |
| `pnpm lint` | ESLint |
