# LeetCode Tracker

## What it is

A web app for tracking LeetCode practice and deciding what to work on each day. It started as a fix for one specific, annoying problem: doing NeetCode 150 on and off, losing the thread every time life got busy, and coming back with no idea which problems had gone stale.

Instead of another checklist, it works like a spaced repetition system for algorithm problems. Each day it hands you a short, fixed set of work: two problems to review and one new one. You solve them on LeetCode as usual, then tell the app how it went. Over time it learns which topics you're shaky on and keeps those in rotation.

## Why it exists

There's no shortage of LeetCode problems or curated lists. The hard part is staying consistent and knowing what to revisit. A problem you solved cleanly three weeks ago is not the same as one you got last night by peeking at the editorial, but a plain checklist treats them identically.

So the goal is narrow:

- Make the daily decision for you, so you open the app and just start.
- Resurface problems right before you'd forget how to solve them.
- Keep comfort honest. Marking something "done" should not mean "done forever."

Motivation is the real enemy here, not a shortage of problems. A predictable two reviews plus one new each day is easier to keep up than a vague plan to "grind."

## How it works

### Getting started

The first time you open the app there's no history to schedule from. Rather than guess, it shows you the full list of topics (arrays, two pointers, sliding window, and so on) and asks you to mark which ones you're comfortable or shaky with. That gives the scheduler somewhere to start.

That rating is only a starting point. The app does not treat it as the truth. As you actually solve problems it recalculates your comfort from how you performed, and your early guesses fade out of the math.

### The daily set

Every day you get two reviews and one new problem.

The two reviews are whatever is most overdue in your queue. The new problem is the next one worth learning, picked from the topic order but weighted toward the areas you've rated or shown yourself weaker in. If nothing is due yet, the day fills up with new problems instead. Once you've worked through everything, it becomes pure review.

### Logging a session

After you solve (or fail) a problem, the app asks a few quick questions: did you get it, did you peek at the solution, how long it took, and what time and space complexity you ended up with. All of it is self-reported, on purpose. LeetCode already tells you whether your code passed, so the app doesn't try to re-judge correctness or parse your solution. Whether you peeked isn't something software can detect from the outside, so it just asks.

### Comfort and scheduling

Each problem has a comfort score from 1 to 5. It starts from your topic rating, then moves with your performance: solving cleanly nudges it up, peeking or struggling pulls it down. The update is a weighted average that leans on recent attempts, so two or three real sessions are enough to wash out the original guess.

Comfort drives the review interval. The intervals climb a fixed ladder, roughly 3, 7, 15, 30, and 90 days. Do well and a problem moves up a rung and comes back less often. Do badly and it drops back down. The schedule is just "last reviewed plus the current interval," which makes "what's due today" a single fast query.

## Architecture

The app is split into a thin client and an authoritative backend, and that split has been there since the first commit, not bolted on later. The backend owns everything that matters — the scheduling logic, the comfort scoring, the LeetCode catalog, and the database. The client renders state and sends user actions; it never touches the database directly. That keeps the rules in one place no matter how many clients there are.

### The stack

The client is a **web app** built with SvelteKit and deployed on Vercel. The browser only ever calls SvelteKit's own server routes, which proxy through to the backend — so the backend's address (and, later, login sessions) stay server-side and there's no cross-origin wiring to manage. The backend is Kotlin with Spring Boot, holding the logic and the database, with PostgreSQL on Neon behind it.

There's also an **iOS client** (Swift + SwiftUI) from the project's first phase. It runs against the same backend and proved out the full loop on a real device; the web app is now the primary direction, since sharing a URL beats sideloading an app. The backend doesn't care how many clients it has — the web app and the iOS app are just two front ends over the same API.

No auth and a single user to start. The client/server split exists from day one because the logic and the data are deliberately kept out of the client, not because any one client demands it.

| Piece | Choice | Reason |
|---|---|---|
| Web client | SvelteKit + TypeScript, on Vercel | Shared via a URL, no install; talks to the backend through its own server layer |
| iOS client | Swift + SwiftUI | Original native client from phase one; runs on the same backend |
| Backend | Kotlin + Spring Boot | Owns the scheduling logic, comfort scoring, and the database |
| Database | PostgreSQL on Neon | Serverless, free tier, sits behind the backend |
| Hosting | Vercel for the web app, Render for the backend | Free-tier web host plus a containerized API |

A one-time job on the backend pulls the problem catalog from LeetCode's GraphQL endpoint into Postgres, with the NeetCode 150 marked.

### Data model

Six tables cover it:

- `problems`: the static catalog (number, slug, title, difficulty)
- `tags` and `problem_tags`: the topics, and which problems belong to each
- `user_progress`: per-problem state (status, live comfort, interval, next review date)
- `user_topic_comfort`: the per-topic self ratings from onboarding
- `review_sessions`: one row per attempt (outcome, peeked, time, complexity, timestamp), kept as history so comfort can be recomputed and the timelines drawn later

Comfort lives on `user_progress` as a computed value, not something the user edits directly. Only the backend reads and writes these tables; the clients see them through the API.

### Shape of it

```
  Web  (SvelteKit on Vercel) ---\
                                  >--- Backend API  (Kotlin / Spring Boot) --- Postgres (Neon)
  iOS  (Swift / SwiftUI) --------/        scheduling, comfort scoring, seeding
                                                 |
                                          LeetCode GraphQL  (seed)
```

### Where it goes next

The heavier features come after the basic loop is solid:

- Accounts through GitHub or Google, with the OAuth handled by the backend, filling the `user_id` the schema already leaves room for. This is what turns it from a single-user tool into something other people can use with their own data.
- Weekly, monthly, and yearly views of progress that surface strong and weak topics from the session history.
- Review reminders, so "three are due today" reaches you instead of waiting for you to check.

### Out of scope for now

Accounts, deeper analytics, and reminders are left out on purpose until the daily loop is solid end to end. They matter, but a finished small thing beats an unfinished big one.
