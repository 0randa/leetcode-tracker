package dev.lctracker.backend.domain

import java.time.LocalDate
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToLong

/** Where a review date sits relative to today; drives the UI's single-accent urgency ramp. */
enum class DueState { OVERDUE, DUE, SOON, SCHEDULED }

data class DueInfo(val state: DueState, val days: Int, val text: String)

/**
 * The spaced-repetition brain — a verbatim port of the design's scheduler.jsx.
 * Pure functions: comfort is an EMA seeded by the topic prior, on a fixed
 * interval ladder, with outcome + peeking moving the stage up or down. Every
 * "due in N days" / "reschedules from today" the UI shows is computed from this.
 */
object Scheduler {

    /** Interval ladder — days at each stage (0..4). */
    val LADDER = listOf(3, 7, 15, 30, 90)

    /** EMA weight on the newest session (0.5 = newest counts as much as all history). */
    const val ALPHA = 0.5

    /** Comfort threshold at the top rung for a problem to count as Mastered. */
    private const val MASTERED_COMFORT = 4.3

    private fun clamp(v: Double, lo: Double, hi: Double) = max(lo, min(hi, v))
    private fun round1(v: Double) = (v * 10).roundToLong() / 10.0

    /** Onboarding self-rating → seed comfort for that topic's problems. */
    fun topicPrior(rating: TopicRating): Double = when (rating) {
        TopicRating.COMFORTABLE -> 4.0
        TopicRating.SHAKY -> 2.5
        TopicRating.NOT_TRIED -> 1.0
    }

    /** A single session's raw comfort signal from the outcome and whether they peeked. */
    fun sessionSignal(outcome: SessionOutcome, peeked: Boolean): Double {
        val base = when (outcome) {
            SessionOutcome.SOLVED_CLEAN -> 5.0
            SessionOutcome.SOLVED_HINTS -> 3.0
            SessionOutcome.DIDNT_SOLVE -> 1.5
        }
        return clamp(if (peeked) base - 1 else base, 1.0, 5.0)
    }

    /** Next comfort = EMA of prior comfort and this session's signal. */
    fun nextComfort(prevComfort: Double, outcome: SessionOutcome, peeked: Boolean): Double {
        val sig = sessionSignal(outcome, peeked)
        return clamp(round1((1 - ALPHA) * prevComfort + ALPHA * sig), 1.0, 5.0)
    }

    /** Stage movement — outcome and peeking push the stage up or down the ladder. */
    fun nextStage(stage: Int, outcome: SessionOutcome, peeked: Boolean): Int = when (outcome) {
        SessionOutcome.DIDNT_SOLVE -> 0                                   // reset to the short interval
        SessionOutcome.SOLVED_HINTS -> if (peeked) max(stage - 1, 0) else stage  // hold, or slip if peeked
        SessionOutcome.SOLVED_CLEAN -> if (peeked) stage else min(stage + 1, LADDER.size - 1) // advance, cap if peeked
    }

    fun intervalForStage(stage: Int): Int = LADDER[stage.coerceIn(0, LADDER.size - 1)]

    /** Derived tracked status from where a problem sits on the ladder. */
    fun statusFor(stage: Int, comfort: Double?, hasHistory: Boolean): ProgressStatus {
        if (!hasHistory) return ProgressStatus.TODO
        if (stage >= LADDER.size - 1 && (comfort ?: 0.0) >= MASTERED_COMFORT) return ProgressStatus.MASTERED
        return ProgressStatus.REVIEW
    }

    /** A review date relative to today → { state, days, text } for the UI. */
    fun dueInfo(reviewDate: LocalDate, today: LocalDate): DueInfo {
        val diff = (reviewDate.toEpochDay() - today.toEpochDay()).toInt()
        return when {
            diff < 0 -> DueInfo(DueState.OVERDUE, diff, "Overdue · ${-diff}d")
            diff == 0 -> DueInfo(DueState.DUE, 0, "Due today")
            diff == 1 -> DueInfo(DueState.SOON, 1, "Due tomorrow")
            else -> DueInfo(DueState.SCHEDULED, diff, "Due in $diff days")
        }
    }
}
