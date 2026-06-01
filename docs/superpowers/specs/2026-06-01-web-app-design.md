# Web App (SvelteKit) — Design & Build Spec

_Created 2026-06-01. This is a build-ready spec for a **new agent** to implement
the web version of the LeetCode Review Tracker. It assumes no prior conversation
context. Read this top to bottom, then run the **brainstorming → writing-plans**
flow only if you need to refine; otherwise go straight to the **Build order**._

> Prereqs to read first: `CLAUDE.md` (working agreement) and `HANDOFF.md` (current
> state — backend + iOS app are done and deployed). The backend is the source of
> truth for all logic; **this project adds a second client only.**

---

## 1. Goal

Build a **web client** for the existing tracker so it can be used with no App Store
install and shared via a URL. The existing **Kotlin/Spring Boot backend stays
exactly as-is** — the web app is a thin client over the same `/api`, exactly like
the iOS app. Do **not** reimplement scheduling/comfort logic in the frontend.

This is a deliberate addition to the original iOS-first plan, made because the user
wants other people to be able to use it eventually. The existing **SwiftUI app
remains the iOS client**; this becomes the web client. Neither replaces the other.

## 2. Locked decisions (from a brainstorming session — do not relitigate)

| Decision | Choice | Why |
|---|---|---|
| Frontend framework | **SvelteKit** (TypeScript) | Design source is already component-shaped; SvelteKit gives SSR + server routes |
| Hosting | **Vercel** (`@sveltejs/adapter-vercel`, Node runtime) | Best free SvelteKit tier, no cold-sleep on the frontend, GitHub auto-deploy |
| FE ↔ BE | **BFF proxy** — browser → SvelteKit server → Spring `/api` | No CORS, backend URL hidden, natural home for auth/session later |
| Backend | **Unchanged** | It's already a platform-agnostic JSON API |
| Scope | **Full parity — all 7 screens** | Every screen + endpoint already exists and is verified on iOS |
| Users | **Single-user now, structured for multi-user later** | Ship fast; leave clean seams for auth (see §9) |

## 3. Architecture & request flow

```
Browser ──▶ SvelteKit (Vercel, Node)                    ──▶ Spring /api ──▶ Neon
            ├─ +page.server.ts  load() fns (SSR reads)      (unchanged, on Render)
            ├─ routes/api/[...path]/+server.ts (proxy)
            └─ form actions (log session, onboarding submit)
                    │
                    └─ later: session cookie + user_id injected here
```

- **The browser only ever talks to same-origin SvelteKit routes.** Only the
  SvelteKit *server* knows the Spring base URL (env var `SPRING_API_BASE`). No CORS
  config is needed on the backend, and the backend URL never reaches the client.
- **Reads** (Today, Problems, Detail, Analytics) happen in `+page.server.ts`
  `load()` functions → server-rendered first paint, no client loading spinners on
  navigation.
- **Mutations** (log a session, submit onboarding, resolve off-script) use SvelteKit
  **form actions** (progressive-enhancement friendly; the natural seam for attaching
  a session/user later).
- A catch-all proxy route `routes/api/[...path]/+server.ts` forwards any remaining
  client-side fetches to Spring (used for the off-script live search / log preview,
  which are interactive).
- **Cold start:** the Spring backend is on Render's free tier and sleeps after ~15
  min idle; the first request cold-starts in ~30–60s (measured 69s once). The
  server fetch wrapper uses a **90s timeout** and surfaces a "waking the server…"
  state rather than hanging. (The iOS client had a 60s timeout that was too short —
  do not repeat that.)

## 4. Tech stack & dependencies

- **SvelteKit** (latest, Svelte 5 runes) + **TypeScript** (strict).
- **`@sveltejs/adapter-vercel`** (Node runtime, not edge — we need full Node fetch).
- **Vite** (comes with SvelteKit).
- **Styling: plain CSS / CSS custom properties** ported from the design tokens. **Do
  NOT add Tailwind or a component library** — the design is a bespoke, locked,
  near-grayscale system; a UI kit would fight it. Keep it dependency-light (matches
  `CLAUDE.md`: "prefer simple… don't add libraries the loop doesn't need").
- **Fonts: IBM Plex Sans (variable) + IBM Plex Mono.** Self-host in `static/fonts/`
  (copy from `ios/LCTracker/LCTracker/Fonts/`) — do not pull from a CDN.
- No state-management library needed — SvelteKit `load` data + a couple of small
  stores (e.g. a toast store) is enough.
- Charts (Analytics weekly trend + comfort bars): **hand-build with divs/SVG**, no
  chart lib — they're simple bars. Mirror the iOS `StatsView` implementation.

## 5. Project structure

Create the web client at **`web/`** in the repo root (siblings: `backend/`, `ios/`,
`web/`).

```
web/
├── package.json, svelte.config.js, vite.config.ts, tsconfig.json
├── .env.example                 # SPRING_API_BASE=...
├── static/fonts/                # IBM Plex Sans VF + Mono (copied from ios/.../Fonts)
├── src/
│   ├── app.css                  # design tokens (:root custom props) + base/reset
│   ├── app.html
│   ├── lib/
│   │   ├── server/
│   │   │   └── api.ts            # typed fetch wrapper → SPRING_API_BASE, 90s timeout
│   │   ├── types.ts             # TS mirrors of the backend DTOs (see §6)
│   │   ├── format.ts            # date/relative formatting (mirror ios Formatting.swift)
│   │   ├── components/          # design-system primitives (see §8)
│   │   └── stores/toast.ts
│   └── routes/
│       ├── +layout.svelte       # 3-tab bottom nav shell (Today · Problems · Stats) + header gear slot
│       ├── +layout.server.ts    # onboarding-gate check
│       ├── +page.server.ts / +page.svelte          # Today (/)
│       ├── onboarding/+page.svelte + .server.ts     # first-run rating flow
│       ├── problems/+page.server.ts / +page.svelte  # list + filters
│       ├── problems/[id]/+page.server.ts / +page.svelte  # detail/history
│       ├── stats/+page.server.ts / +page.svelte     # analytics
│       └── api/[...path]/+server.ts                 # proxy passthrough
└── ...
```

Modal-style screens (**Log a session**, **Off-script find/confirm**) are components
rendered as overlays, not separate routes — same as iOS. Log can also be reached as
a route param/query if SSR-friendliness is wanted, but the overlay approach matches
the design.

## 6. Backend contract — DTOs & endpoints

The backend is single-user, base path **`/api`**, plus `/health`. **All shapes
below are mirrored from the verified iOS `Models.swift`** — reproduce them exactly
in `src/lib/types.ts`.

### Endpoints

| Method & path | Purpose | Returns |
|---|---|---|
| `GET /api/today` | Daily set + streak/totals/est. minutes | `Today` |
| `GET /api/problems?search=&topic=&difficulty=&status=` | Catalogue list | `ProblemSummary[]` |
| `GET /api/problems/{id}` | Detail: status, comfort, trend, next review, history | `ProblemDetail` |
| `POST /api/problems/{id}/sessions` | Log attempt → reschedule + recompute comfort | `ScheduleResult` |
| `POST /api/problems/{id}/sessions/preview` | Same computation, **no persist** (live Log preview) | `ScheduleResult` |
| `GET /api/topics` | 18 onboarding categories | `string[]` |
| `POST /api/onboarding` | Submit topic comfort ratings | (ack) |
| `GET /api/resolve?query=` | Off-script: resolve a LeetCode URL or search by name | `ResolveResponse` |
| `GET /api/analytics` | Streak, total solved, topics by comfort, weekly trend | `Analytics` |
| `GET /health` | Liveness | `{"status":"ok"}` |

### Enums (Jackson serializes the Kotlin constant names — use these exact strings)

- `Difficulty`: `EASY` `MEDIUM` `HARD` (display: Easy/Medium/Hard; grayscale ordinal 1/2/3)
- `ProgressStatus`: `TODO` `REVIEW` `MASTERED` (display: To do / In review / Mastered)
- `TopicRating`: `COMFORTABLE` `SHAKY` `NOT_TRIED` (display: Comfortable / Shaky / Not tried)
- `SessionOutcome`: `SOLVED_CLEAN` `SOLVED_HINTS` `DIDNT_SOLVE` (display: Solved cleanly / Solved with hints / Didn't solve)
- `DueState`: `OVERDUE` `DUE` `SOON` `SCHEDULED`
- Dates: `LocalDate` as `"yyyy-MM-dd"`, `Instant` as ISO-8601. **Keep as strings;
  format in the view layer** (mirror `Formatting.swift`).

### TypeScript type targets (mirror exactly)

```ts
type Difficulty = 'EASY' | 'MEDIUM' | 'HARD';
type ProgressStatus = 'TODO' | 'REVIEW' | 'MASTERED';
type TopicRating = 'COMFORTABLE' | 'SHAKY' | 'NOT_TRIED';
type SessionOutcome = 'SOLVED_CLEAN' | 'SOLVED_HINTS' | 'DIDNT_SOLVE';
type DueState = 'OVERDUE' | 'DUE' | 'SOON' | 'SCHEDULED';

interface DueInfo { state: DueState; days: number; text: string }
interface ProblemSummary { id: number; slug: string; title: string; difficulty: Difficulty;
  topics: string[]; status: ProgressStatus; comfort: number; lcUrl: string }
interface TodayCard { kind: 'Review' | 'New'; due: DueInfo | null; problem: ProblemSummary }
interface Today { date: string; reviewCount: number; newCount: number; estimatedMinutes: number;
  streak: number; totalSolved: number; set: TodayCard[] }
interface Session { date: string; outcome: SessionOutcome; peeked: boolean;
  timeTakenMin: number | null; timeComplexity: string | null; spaceComplexity: string | null;
  comfort: number | null }
interface ProblemDetail { id: number; slug: string; title: string; difficulty: Difficulty;
  topics: string[]; status: ProgressStatus; comfort: number; comfortTrend: number[];
  nextReview: DueInfo | null; lcUrl: string; history: Session[] }
interface ScheduleResult { stageFrom: number; stageTo: number; comfortFrom: number; comfortTo: number;
  intervalDays: number; reviewDate: string; dueText: string; status: ProgressStatus;
  advanced: boolean; slipped: boolean }
interface LogSessionRequest { outcome: SessionOutcome; peeked?: boolean; timeTakenMin?: number | null;
  timeComplexity?: string | null; spaceComplexity?: string | null }
interface TopicRatingDTO { category: string; rating: TopicRating }
interface OnboardingRequest { ratings: TopicRatingDTO[] }
interface ResolveResponse { found: boolean; matches: ProblemSummary[]; note: string | null }
interface TopicComfort { topic: string; score: number; count: number }
interface Analytics { streak: number; totalSolved: number; topics: TopicComfort[]; weekly: number[] }
```

## 7. The server API layer (`lib/server/api.ts`)

- Single typed wrapper around `fetch(`${SPRING_API_BASE}${path}`, …)`.
- **90s timeout** via `AbortController` (cold-start tolerant).
- JSON in/out; throws a typed error on non-2xx that `load`/actions turn into
  SvelteKit `error(status, …)`.
- `SPRING_API_BASE` from `$env/dynamic/private` (e.g.
  `https://lctracker-backend.onrender.com`). Never import this in client code.
- The catch-all `routes/api/[...path]/+server.ts` reuses this wrapper to forward
  interactive client fetches (off-script search, log preview).

## 8. Design system & screens (source of truth = the design files)

**The UI/UX is already designed and locked. Implement it faithfully; do not
redesign, rename flows, or invent screens.** (Same rule as `CLAUDE.md`.)

- **Design files:** fetch the design bundle from
  `https://api.anthropic.com/v1/design/h/Ey8HQbTfZR7VhLnOKb2HZA` (gzipped tar).
  It contains **React/JSX** sources — `wireframe-kit.jsx` (tokens), `screens.jsx`
  (onboarding/home/list/log/analytics), `detail.jsx`, `offscript.jsx`,
  `scheduler.jsx` (backend logic — already ported, ignore for FE), `SUMMARY.md`.
  **These JSX files port to Svelte components nearly 1:1** — that's the main reason
  SvelteKit was chosen.
- **Cross-reference the working iOS implementation** in
  `ios/LCTracker/LCTracker/` for resolved states/copy/behavior already figured out:
  - `DesignSystem/Theme.swift` — the exact token values (colors, type scale,
    spacing, radii). Port these into `app.css` `:root` custom properties.
  - `DesignSystem/Components.svelte`-equivalents → from `Components.swift`: Badge,
    DiffBadge (grayscale ordinal), StatusBadge, TopicTag, DueChip, Comfort dots,
    Btn, Segmented, Toggle, Radio, Eyebrow, Input, an SF-Symbols→equivalent icon map
    (use a small inline-SVG icon set; do not pull a heavy icon lib).
  - Each `Features/*` folder maps to a route below.
- **Visual direction (locked):** restrained near-grayscale; a **single cool-blue
  accent used only for signal** (difficulty, comfort, due vs overdue); difficulty is
  a **grayscale ordinal**, not a hue; primary actions ink-black; **IBM Plex Sans /
  Mono**, mono-forward. Motion restrained, honor `prefers-reduced-motion`. No new
  hues, no decoration the design doesn't have.
- **Locked variant picks:** Onboarding **A** (segmented), Home **A** (stacked
  cards), Log **A** (bottom sheet + exact Big-O accordions), Detail **A** (timeline),
  off-script **FAB**.
- If something in the design is ambiguous, **ask — do not invent**.

### Screens → routes → data

| Screen | Route | Data source | Notes |
|---|---|---|---|
| **Onboarding** (rate 18 categories) | `/onboarding` | `GET /api/topics`; submit `POST /api/onboarding` | First-run only; gate via a cookie/localStorage flag (`onboardingComplete`). Segmented Comfortable/Shaky/Not tried + progress bar. |
| **Today / Home** | `/` | `GET /api/today` | Stacked cards (2 review + 1 new), progress strip + streak, stat chips w/ filter. States: **awaiting-log** (opening on LeetCode marks in-progress; not "done" until logged), **nothing-due** all-new, **first-run welcome**. Cards open detail. |
| **Problem list** | `/problems` | `GET /api/problems` (+ search/topic/difficulty/status filters) | Searchable/filterable; rows → detail. |
| **Log a session** (modal) | overlay (from Today/Detail) | `POST .../sessions/preview` (live), `POST .../sessions` (save) | Outcome radios, peeked toggle, time, **exact Big-O accordions**, **live schedule preview**, save → reschedule. |
| **Problem detail / history** | `/problems/[id]` | `GET /api/problems/{id}` | Comfort + trend dots, next-review card, session history timeline, never-attempted empty state, "Log a session" footer. |
| **Analytics / Stats** | `/stats` | `GET /api/analytics` | Streak + solved summary, weekly solved-trend bars (7 UTC days, today accented), topic comfort bars. Backend exposes only a 7-day window → render a static "Last 7 days" label (don't fabricate Weekly/Monthly/Yearly). No-data empty state. |
| **Off-script logging** | overlay ("+" FAB on Today) | `GET /api/resolve?query=` | One smart input (URL parse + name search) → result rows / "Resolved from link" / empty hint + quick picks / not-found → confirm card → reuses Log modal → toast + Today reload. |

**Navigation:** three-tab bottom bar **Today · Problems · Stats**. Settings is a
**reserved gear slot in the header — do NOT build the Settings screen** (out of
scope, same as iOS).

## 9. Auth-later seams (build single-user, don't paint into a corner)

Single-user now, but leave these seams so multi-user drops in cleanly later:

- **All backend calls funnel through `lib/server/api.ts`** — when auth lands, inject
  the user/session there (header or cookie-forwarded), one file to change.
- **Mutations go through form actions / server endpoints**, never raw client fetch
  to Spring — so a session cookie can be read server-side later.
- Keep an explicit (currently no-op) **`getSession(event)`** helper in
  `hooks.server.ts` returning a single hardcoded user context now; swap for real
  auth later.
- **Do NOT** scatter the backend URL or build auth UI now. The backend's `user_id`
  slot stays unwired until a dedicated multi-user project (tracked in `HANDOFF.md`).

## 10. Config & environment

- **`SPRING_API_BASE`** (private server env): `https://lctracker-backend.onrender.com`.
  Set in `.env` locally and in Vercel project env vars. Document in `.env.example`.
- Local dev: `npm run dev` proxies to the live Render backend by default (or point
  at a local `./gradlew bootRun` on `http://localhost:8080`).
- No public/`PUBLIC_*` env needed — the browser never sees the backend URL.

## 11. Deployment (Vercel)

1. `@sveltejs/adapter-vercel` (Node runtime).
2. New Vercel project → import the GitHub repo `0randa/leetcode-tracker` → set
   **Root Directory = `web`**.
3. Add env var `SPRING_API_BASE = https://lctracker-backend.onrender.com`.
4. Deploy → Vercel auto-builds on push to `main`.
5. **PWA / "Add to Home Screen"** (optional polish, deferred): add a web manifest +
   icons so it installs app-like on phones. Not required for v1; note it and move on.

## 12. Build order (keep it runnable at each step)

1. **Scaffold** `web/` SvelteKit + TS + adapter-vercel; `app.css` tokens from
   `Theme.swift`; fonts; `types.ts`; `lib/server/api.ts` (with 90s timeout);
   the proxy route. Verify `/health` round-trips through the proxy.
2. **Layout shell** — 3-tab bottom nav + header gear slot + onboarding gate.
3. **Today** (`/`) — the core screen; verify against live data first.
4. **Log a session** modal — preview + save loop (reschedule). This closes the loop.
5. **Onboarding** — first-run gate + submit.
6. **Problem list** + **detail/history**.
7. **Analytics**.
8. **Off-script** FAB → find → confirm → reuse Log.
9. **Deploy to Vercel**; verify the full loop end-to-end on the deployed URL.
10. Stop. PWA/manifest and multi-user auth are explicitly deferred.

## 13. Verification

- Type-check (`svelte-check`) + build clean.
- Run against the **live backend** and walk the loop: onboarding → today → open a
  problem on LeetCode → log → see it reschedule → detail history updates → analytics
  reflects it → off-script resolve+log.
- Watch the **first request cold-start** behaves (waking state, not a hang/timeout).
- Cross-check every screen against the design files + the iOS app for fidelity.

## 14. Out of scope (do not build unless asked)

Auth/accounts (seams only — §9), the second-platform parity beyond this, push
notifications, the Settings screen, deeper analytics scoring, offline support. Same
guardrails as `CLAUDE.md`. **Do not store LeetCode problem content** — link out
only.

---

### Quick-start pointers for the next agent
- Backend is **live and unchanged**: `https://lctracker-backend.onrender.com`
  (`/health`, `/api/...`). Free tier sleeps → first call ~30–60s.
- DTO/enum truth: `ios/LCTracker/LCTracker/Networking/Models.swift`.
- Token/component truth: `ios/LCTracker/LCTracker/DesignSystem/{Theme,Components}.swift`
  and the design bundle's JSX.
- Behavior/state truth (resolved copy + edge states): `ios/.../Features/*`.
- Don't reimplement scheduling/comfort — it's all server-side already.
