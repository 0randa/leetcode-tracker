# LeetCode Review Tracker — Backend

Kotlin + Spring Boot API. Owns all logic (scheduling, comfort scoring, the LeetCode
seed) and the database. Clients talk to it over HTTPS/JSON and never touch the DB.

- **Stack:** Spring Boot 4, Kotlin, JPA/Hibernate, Flyway, PostgreSQL.
- **DB:** Postgres on Neon in production; local Postgres via Docker for development.

## Run locally

```bash
# 1. start a local Postgres (localhost:5432, db/user/pass all "lctracker")
docker compose up -d

# 2. run the app (uses the local defaults in application.yml)
./gradlew bootRun

# 3. verify
curl localhost:8080/health        # -> {"status":"ok"}
```

Flyway applies `src/main/resources/db/migration` on startup, so the schema is
created automatically against a fresh database.

## Seeding the catalogue

The catalogue is seeded from the bundled NeetCode-150 list
(`src/main/resources/seed/neetcode-150.json`, a curated `category` + LeetCode
`slug` list) enriched with live metadata from LeetCode's GraphQL API. It upserts
keyed on the numeric LeetCode id, so it is **safe to re-run** (renames update in
place; nothing is duplicated or orphaned).

Run it by starting the app with `--seed` (it does nothing on a normal boot):

```bash
docker compose up -d
java -jar build/libs/backend-0.0.1-SNAPSHOT.jar --seed   # or: ./gradlew bootRun --args='--seed'
```

This populates 150 `problems`, 18 `tags` (the NeetCode categories), and 150
`problem_tags`. The backend is the only thing that talks to LeetCode; the seed
takes ~90s (it paces requests to be polite).

## Configuration

The datasource is env-driven (defaults target local Docker). For Neon, set:

| Env var        | Example                                                              |
| -------------- | ------------------------------------------------------------------- |
| `DATABASE_URL` | `jdbc:postgresql://ep-xxx.region.aws.neon.tech/lctracker?sslmode=require` |
| `DB_USER`      | `lctracker`                                                          |
| `DB_PASSWORD`  | `••••••`                                                             |
| `PORT`         | `8080` (default)                                                    |

See `.env.example`.

## Schema (Flyway `V1__init.sql`)

Six tables. `problems` is keyed on the **numeric LeetCode id** so upstream renames
never orphan progress. Per-user tables carry a `user_id` slot (default `1`, the
single implicit user) so auth can be added later without a migration — no auth is
wired now.

| Table                | Purpose                                                        |
| -------------------- | -------------------------------------------------------------- |
| `problems`           | Catalogue: id, slug, title, difficulty, is_active, NeetCode-150 flag |
| `tags`               | Topic/category list                                            |
| `problem_tags`       | Join: problem ↔ tag                                            |
| `user_progress`      | Per-problem state: status, computed comfort, ladder stage, next review |
| `user_topic_comfort` | Per-topic onboarding self-ratings (priors)                     |
| `review_sessions`    | One row per logged attempt — the history detail/analytics read |

Enum-like columns are stored as text constrained by CHECK to match the Kotlin
enum names in `domain/enums.kt`.

## API

All endpoints are single-user (no auth in the MVP). Base path `/api`.

| Method & path                          | Purpose                                                        |
| -------------------------------------- | -------------------------------------------------------------- |
| `GET /api/today`                       | Daily set: 2 most-overdue reviews + new (backfilled to 3), with streak, totals, est. minutes |
| `GET /api/problems`                    | Catalogue list; filters `search`, `topic`, `difficulty`, `status` |
| `GET /api/problems/{id}`               | Detail: status, comfort, comfort trend, next review, session history |
| `POST /api/problems/{id}/sessions`     | Log an attempt → reschedules + recomputes comfort, returns the result |
| `POST /api/problems/{id}/sessions/preview` | Same computation **without** persisting (powers the Log sheet's live preview) |
| `GET /api/topics`                      | The 18 NeetCode categories to rate in onboarding               |
| `POST /api/onboarding`                 | Submit topic comfort ratings (priors)                          |
| `GET /api/resolve?query=`              | Off-script: resolve a pasted LeetCode URL or search by name    |
| `GET /api/analytics`                   | Streak, total solved, topics ranked by comfort, weekly trend   |
| `GET /health`                          | Liveness                                                       |

The spaced-repetition logic lives in `domain/Scheduler.kt` (a verbatim port of the
design's `scheduler.jsx`), unit-tested in `SchedulerTest`.

Log-session request body:

```json
{ "outcome": "SOLVED_CLEAN", "peeked": false, "timeTakenMin": 18,
  "timeComplexity": "O(n^2)", "spaceComplexity": "O(1)" }
```

`outcome` ∈ `SOLVED_CLEAN | SOLVED_HINTS | DIDNT_SOLVE`; onboarding `rating` ∈
`COMFORTABLE | SHAKY | NOT_TRIED`.

## Status

- [x] **Step 1** — backend scaffold + Postgres schema.
- [x] **Step 2** — seed script (LeetCode GraphQL → problems/tags, NeetCode 150). Run with `--seed`.
- [x] **Step 3** — core API + scheduling/comfort logic (scheduler unit-tested; loop verified end-to-end over HTTP).
- [ ] Step 4 — iOS (SwiftUI) client.
