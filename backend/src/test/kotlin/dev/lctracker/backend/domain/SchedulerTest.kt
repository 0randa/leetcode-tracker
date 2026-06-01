package dev.lctracker.backend.domain

import java.time.LocalDate
import kotlin.test.Test
import kotlin.test.assertEquals

/**
 * The scheduler is a verbatim port of the design's scheduler.jsx — the
 * spaced-repetition "brain". These tests pin the exact behaviors so the port
 * (and any future change) stays faithful.
 */
class SchedulerTest {

    private val EASY = 1e-9

    // --- session signal: outcome + peeked → raw 1..5 -----------------------

    @Test fun `clean solve signals 5`() =
        assertEquals(5.0, Scheduler.sessionSignal(SessionOutcome.SOLVED_CLEAN, peeked = false), EASY)

    @Test fun `hints signals 3`() =
        assertEquals(3.0, Scheduler.sessionSignal(SessionOutcome.SOLVED_HINTS, peeked = false), EASY)

    @Test fun `miss signals 1_5`() =
        assertEquals(1.5, Scheduler.sessionSignal(SessionOutcome.DIDNT_SOLVE, peeked = false), EASY)

    @Test fun `peeking subtracts one from the signal`() =
        assertEquals(4.0, Scheduler.sessionSignal(SessionOutcome.SOLVED_CLEAN, peeked = true), EASY)

    @Test fun `signal is clamped to a floor of 1 when peeking a miss`() =
        assertEquals(1.0, Scheduler.sessionSignal(SessionOutcome.DIDNT_SOLVE, peeked = true), EASY)

    // --- comfort: EMA of prior comfort and the session signal --------------

    @Test fun `comfort moves halfway toward a clean solve`() =
        assertEquals(3.5, Scheduler.nextComfort(2.0, SessionOutcome.SOLVED_CLEAN, peeked = false), EASY)

    @Test fun `comfort is rounded to one decimal`() =
        assertEquals(2.8, Scheduler.nextComfort(2.5, SessionOutcome.SOLVED_HINTS, peeked = false), EASY)

    @Test fun `comfort is clamped to 5`() =
        assertEquals(5.0, Scheduler.nextComfort(5.0, SessionOutcome.SOLVED_CLEAN, peeked = false), EASY)

    // --- stage movement on the ladder --------------------------------------

    @Test fun `clean solve advances a rung`() =
        assertEquals(2, Scheduler.nextStage(1, SessionOutcome.SOLVED_CLEAN, peeked = false))

    @Test fun `clean solve but peeked holds the stage`() =
        assertEquals(1, Scheduler.nextStage(1, SessionOutcome.SOLVED_CLEAN, peeked = true))

    @Test fun `hints holds the stage`() =
        assertEquals(2, Scheduler.nextStage(2, SessionOutcome.SOLVED_HINTS, peeked = false))

    @Test fun `hints with a peek slips back a rung`() =
        assertEquals(1, Scheduler.nextStage(2, SessionOutcome.SOLVED_HINTS, peeked = true))

    @Test fun `a miss resets to the first rung`() =
        assertEquals(0, Scheduler.nextStage(3, SessionOutcome.DIDNT_SOLVE, peeked = false))

    @Test fun `advancing is capped at the top rung`() =
        assertEquals(4, Scheduler.nextStage(4, SessionOutcome.SOLVED_CLEAN, peeked = false))

    @Test fun `slipping is floored at the first rung`() =
        assertEquals(0, Scheduler.nextStage(0, SessionOutcome.SOLVED_HINTS, peeked = true))

    // --- interval ladder ---------------------------------------------------

    @Test fun `ladder intervals are 3 7 15 30 90`() {
        assertEquals(3, Scheduler.intervalForStage(0))
        assertEquals(7, Scheduler.intervalForStage(1))
        assertEquals(15, Scheduler.intervalForStage(2))
        assertEquals(30, Scheduler.intervalForStage(3))
        assertEquals(90, Scheduler.intervalForStage(4))
    }

    @Test fun `interval clamps an out-of-range stage`() {
        assertEquals(3, Scheduler.intervalForStage(-1))
        assertEquals(90, Scheduler.intervalForStage(9))
    }

    // --- derived status -----------------------------------------------------

    @Test fun `no history is To do`() =
        assertEquals(ProgressStatus.TODO, Scheduler.statusFor(0, comfort = null, hasHistory = false))

    @Test fun `top rung with high comfort is Mastered`() =
        assertEquals(ProgressStatus.MASTERED, Scheduler.statusFor(4, comfort = 4.5, hasHistory = true))

    @Test fun `top rung with middling comfort is still In review`() =
        assertEquals(ProgressStatus.REVIEW, Scheduler.statusFor(4, comfort = 4.0, hasHistory = true))

    @Test fun `mid-ladder is In review`() =
        assertEquals(ProgressStatus.REVIEW, Scheduler.statusFor(2, comfort = 3.0, hasHistory = true))

    // --- topic priors -------------------------------------------------------

    @Test fun `topic priors seed comfort`() {
        assertEquals(4.0, Scheduler.topicPrior(TopicRating.COMFORTABLE), EASY)
        assertEquals(2.5, Scheduler.topicPrior(TopicRating.SHAKY), EASY)
        assertEquals(1.0, Scheduler.topicPrior(TopicRating.NOT_TRIED), EASY)
    }

    // --- due info -----------------------------------------------------------

    @Test fun `a past review date is overdue`() {
        val today = LocalDate.of(2026, 6, 1)
        val info = Scheduler.dueInfo(today.minusDays(2), today)
        assertEquals(DueState.OVERDUE, info.state)
        assertEquals(-2, info.days)
        assertEquals("Overdue · 2d", info.text)
    }

    @Test fun `today is due`() {
        val today = LocalDate.of(2026, 6, 1)
        val info = Scheduler.dueInfo(today, today)
        assertEquals(DueState.DUE, info.state)
        assertEquals("Due today", info.text)
    }

    @Test fun `tomorrow is soon`() {
        val today = LocalDate.of(2026, 6, 1)
        val info = Scheduler.dueInfo(today.plusDays(1), today)
        assertEquals(DueState.SOON, info.state)
        assertEquals("Due tomorrow", info.text)
    }

    @Test fun `further out is scheduled`() {
        val today = LocalDate.of(2026, 6, 1)
        val info = Scheduler.dueInfo(today.plusDays(4), today)
        assertEquals(DueState.SCHEDULED, info.state)
        assertEquals(4, info.days)
        assertEquals("Due in 4 days", info.text)
    }
}
