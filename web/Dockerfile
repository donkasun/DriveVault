# Production image for Cloud Run (see docs/01-tech-spec.md §6).
# Multi-stage: install deps -> build standalone output -> run the minimal server.

FROM node:22-alpine AS base
RUN corepack enable
WORKDIR /app

FROM base AS deps
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# `next build` imports every route module to collect page data, and
# src/server/db/client.ts throws at module scope when DATABASE_URL is unset.
# Every API route is dynamic, so nothing connects during the build — the real
# Neon URL is injected by Cloud Run at runtime.
ENV DATABASE_URL=postgresql://build:build@localhost:5432/build
ENV NEXT_TELEMETRY_DISABLED=1
RUN pnpm build

FROM base AS runner
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
# server.js reads PORT/HOSTNAME; Cloud Run injects PORT=8080.
ENV HOSTNAME=0.0.0.0
ENV PORT=8080

RUN addgroup -g 1001 -S nodejs && adduser -S nextjs -u 1001

# standalone omits public/ and .next/static; copy them in so server.js serves them.
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs
EXPOSE 8080

CMD ["node", "server.js"]
