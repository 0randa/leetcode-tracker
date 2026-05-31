# LeetCode Tracker

## What it is

A small web app for tracking LeetCode practice and deciding what to work on each day. It started as a fix for one specific, annoying problem: doing NeetCode 150 on and off, losing the thread every time life got busy, and coming back with no idea which problems had gone stale.

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

The plan is to ship a single deployable web app first, then split out a separate service later, and only when the smarter features make that worth the trouble.

### The first version

The MVP is a Next.js app doing everything: pages, API routes, and database access in one TypeScript codebase. No separate backend, no auth, one user. The point is to get something real and deployed fast.

| Piece | Choice | Reason |
|---|---|---|
| Framework | Next.js (App Router) + TypeScript | One language across client and server, with shared types |
| UI | Tailwind + shadcn/ui | Good-looking, accessible components without much fuss |
| Client data | TanStack Query | Lets "mark reviewed" update the screen instantly |
| Database | PostgreSQL on Neon | Serverless, free tier, branches cleanly |
| ORM | Drizzle | Stays close to the SQL, which helps when the logic later moves to Java |
| Hosting | Vercel + Neon | Free, and gives you a live URL to point at |

A one-time script pulls the problem catalog from LeetCode's GraphQL endpoint and writes it into Postgres, with the NeetCode 150 marked.

### Data model

Six tables cover it:

- `problems`: the static catalog (number, slug, title, difficulty)
- `tags` and `problem_tags`: the topics, and which problems belong to each
- `user_progress`: per-problem state (status, live comfort, interval, next review date)
- `user_topic_comfort`: the per-topic self ratings from onboarding
- `review_sessions`: one row per attempt (outcome, peeked, time, complexity, timestamp), kept as history so comfort can be recomputed and the timelines drawn later

Comfort lives on `user_progress` as a computed value, not something the user edits directly.

### Shape of it

```
Today (MVP)

  Browser  (Next.js, Tailwind, shadcn/ui)
     |
  Next.js API routes  (TypeScript, Drizzle)
     |
  Postgres (Neon)   <-- seeded once from LeetCode GraphQL


Later

  React Native (Expo) ---\
                          >--- Spring Boot (Java) --- Postgres
  Next.js web --------/         scheduling, scoring, caching
                                      |
                               LeetCode GraphQL  (live user stats)
```

### Where it goes next

The heavier features come after the basic loop works:

- A mobile app in React Native (Expo), sharing logic with the web app.
- A Spring Boot service in Java that owns the scheduling job, the comfort and topic scoring, and the caching of LeetCode data. Pulling this out of the monolith later is a deliberate step in the design, not an afterthought.
- Accounts through GitHub or Google sign-in, which fill the `user_id` the schema already leaves room for.
- Weekly, monthly, and yearly views of progress that surface strong and weak topics from the session history.

### Out of scope for the first version

Auth, mobile, the Java service, analytics, and notifications are all left out of the MVP on purpose. They matter, but the daily loop has to work first, and a finished small thing beats an unfinished big one.