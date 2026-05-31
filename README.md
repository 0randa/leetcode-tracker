# LeetCode Tracker

## What it is

A native mobile app, on iOS and Android, for tracking LeetCode practice and deciding what to work on each day. It started as a fix for one specific, annoying problem: doing NeetCode 150 on and off, losing the thread every time life got busy, and coming back with no idea which problems had gone stale.

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

Going native changes the shape of the project. A web app could have been one deployable thing that served pages and talked to the database itself. Phone apps can't do that, so they call a backend over an API, and the backend owns the database and all the logic. There's a client and a server from the first commit, not bolted on later.

### The first version

Two thin native clients and one backend. The iOS app is Swift with SwiftUI, the Android app is Kotlin with Jetpack Compose, and both call a backend that holds the scheduling logic, the comfort scoring, and the database. No auth and a single user to start, but the client/server split is baked in from day one, because a phone app has nowhere to keep a database.

If you want to ship sooner, build one platform first (whichever phone you carry day to day) and add the second once the loop works end to end. The backend doesn't care how many clients it has.

| Piece | Choice | Reason |
|---|---|---|
| iOS client | Swift + SwiftUI | Native, current iOS UI |
| Android client | Kotlin + Jetpack Compose | Native, current Android UI |
| Backend | Kotlin + Spring Boot | Owns the logic and the database, and shares a language with the Android app |
| Database | PostgreSQL on Neon | Serverless, free tier, sits behind the backend |
| Hosting | Railway, Render, or Fly.io for the backend; the App Store and Play Store for the apps | A containerized API plus the usual stores |

A one-time job on the backend pulls the problem catalog from LeetCode's GraphQL endpoint into Postgres, with the NeetCode 150 marked.

### Data model

Six tables cover it:

- `problems`: the static catalog (number, slug, title, difficulty)
- `tags` and `problem_tags`: the topics, and which problems belong to each
- `user_progress`: per-problem state (status, live comfort, interval, next review date)
- `user_topic_comfort`: the per-topic self ratings from onboarding
- `review_sessions`: one row per attempt (outcome, peeked, time, complexity, timestamp), kept as history so comfort can be recomputed and the timelines drawn later

Comfort lives on `user_progress` as a computed value, not something the user edits directly. Only the backend reads and writes these tables; the apps see them through the API.

### Shape of it

```
  iOS  (Swift / SwiftUI) --------\
                                  >--- Backend API  (Kotlin / Spring Boot) --- Postgres (Neon)
  Android  (Kotlin / Compose) ---/        scheduling, comfort scoring, seeding
                                                 |
                                          LeetCode GraphQL  (seed + live user stats)
```

### Where it goes next

The heavier features come after the basic loop works on one platform:

- The second native app, if you shipped one platform first.
- Accounts through GitHub or Google, with the OAuth handled by the backend, filling the `user_id` the schema already leaves room for.
- Push notifications for review reminders. This is one place going native pays off: real push (APNs on iOS, FCM on Android) is the natural bridge from "your phone says three are due" to sitting down at your computer to solve them, which is where the actual work happens.
- Weekly, monthly, and yearly views of progress that surface strong and weak topics from the session history.

### Out of scope for the first version

Auth, analytics, notifications, and the second platform (if you start with one) are left out of the first version on purpose. They matter, but the daily loop has to work end to end first, and a finished small thing beats an unfinished big one.
