# LeetCode Review Tracker — Web client

The web client for the tracker, built with **SvelteKit + TypeScript** and deployed
on **Vercel**. It's a thin client over the existing Kotlin/Spring Boot backend —
all scheduling/comfort logic lives server-side and is never reimplemented here.

The browser only ever talks to same-origin SvelteKit routes. A **BFF proxy**
(SvelteKit server → Spring `/api`) keeps the backend URL server-side, so there's
no CORS to manage and a clean seam for auth later.

```
Browser ──▶ SvelteKit (Vercel, Node) ──▶ Spring /api ──▶ Neon
            ├─ +page.server.ts load()   (SSR reads)
            ├─ routes/api/[...path]      (proxy for live search / log preview)
            └─ form actions              (onboarding submit)
```

## Run locally

```bash
npm install
cp .env.example .env        # SPRING_API_BASE defaults to the live Render backend
npm run dev                 # http://localhost:5173
```

By default `dev` proxies to the live Render backend. To run against a local
backend instead, set `SPRING_API_BASE=http://localhost:8080` in `.env` and start
`cd ../backend && ./gradlew bootRun`.

The free Render tier sleeps after ~15 min idle; the first request cold-starts in
~30–60s. The server fetch wrapper uses a **90s timeout** and surfaces a "waking the
server…" error page rather than hanging.

## Commands

| Command | What it does |
|---|---|
| `npm run dev` | Dev server with HMR |
| `npm run build` | Production build (adapter-vercel) |
| `npm run preview` | Preview the production build |
| `npm run check` | `svelte-check` type-check |

## Configuration

| Env var | Notes |
|---|---|
| `SPRING_API_BASE` | Private, server-only. e.g. `https://lctracker-backend.onrender.com`. The browser never sees it. |

## Deploy (Vercel)

1. New Vercel project → import the GitHub repo → set **Root Directory = `web`**.
2. Add env var `SPRING_API_BASE = https://lctracker-backend.onrender.com`.
3. Deploy. Vercel auto-builds on push to `main` (`@sveltejs/adapter-vercel`, Node runtime).

## Layout

```
web/
├── src/
│   ├── app.css                 # design tokens (ported from ios Theme.swift) + fonts/reset
│   ├── hooks.server.ts         # resolves the (single-user) session → locals
│   ├── lib/
│   │   ├── server/             # api.ts (90s fetch wrapper), backend.ts (typed endpoints), session.ts (auth seam)
│   │   ├── client-api.ts       # interactive calls via the same-origin proxy
│   │   ├── types.ts            # TS mirrors of the backend DTOs + label maps
│   │   ├── format.ts           # UTC date/comfort formatting (mirrors ios Formatting.swift)
│   │   ├── stores/toast.ts
│   │   └── components/          # design-system primitives + screen pieces
│   └── routes/
│       ├── +layout.svelte       # phone-width frame, 3-tab bottom nav, toast
│       ├── +layout.server.ts    # onboarding gate (cookie)
│       ├── +page.*              # Today (/)
│       ├── onboarding/          # first-run rating flow
│       ├── problems/            # list + [id] detail/history
│       ├── stats/               # analytics
│       └── api/[...path]/        # BFF proxy passthrough
└── static/fonts/                # IBM Plex Sans VF + Mono (self-hosted)
```

## Scope

Single-user, full 7-screen parity with the iOS client. Auth is left as seams only
(`lib/server/session.ts`, form actions, the proxy). Out of scope: accounts, push
notifications, the Settings screen, deeper analytics, offline. See
`docs/superpowers/specs/2026-06-01-web-app-design.md` for the full spec.
```
