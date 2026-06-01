package dev.lctracker.backend.domain

/**
 * Persisted as the constant name (EnumType.STRING). The DB CHECK constraints in
 * V1__init.sql must match these names exactly.
 */

enum class Difficulty { EASY, MEDIUM, HARD }

/** Lifecycle on the spaced-repetition ladder: a problem joins it only once attempted. */
enum class ProgressStatus { TODO, REVIEW, MASTERED }

/** Onboarding self-rating per topic; seeds the comfort prior for that topic's problems. */
enum class TopicRating { COMFORTABLE, SHAKY, NOT_TRIED }

/** Outcome of a single attempt, logged by the user. */
enum class SessionOutcome { SOLVED_CLEAN, SOLVED_HINTS, DIDNT_SOLVE }
