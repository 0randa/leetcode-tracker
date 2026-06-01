package dev.lctracker.backend.web

import dev.lctracker.backend.domain.Difficulty
import dev.lctracker.backend.domain.DueState
import dev.lctracker.backend.domain.ProgressStatus
import dev.lctracker.backend.domain.SessionOutcome
import dev.lctracker.backend.domain.TopicRating
import java.time.Instant
import java.time.LocalDate

/** Where a problem's review sits relative to today; mirrors the design's due ramp. */
data class DueInfoDto(val state: DueState, val days: Int, val text: String)

/** A catalogue row / card payload. `comfort` is the computed 1–5 (0 = never attempted). */
data class ProblemSummaryDto(
    val id: Long,
    val slug: String,
    val title: String,
    val difficulty: Difficulty,
    val topics: List<String>,
    val status: ProgressStatus,
    val comfort: Int,
    val lcUrl: String,
)

/** One item in today's set. `kind` is "Review" or "New". */
data class TodayCardDto(
    val kind: String,
    val due: DueInfoDto?,
    val problem: ProblemSummaryDto,
)

data class TodayDto(
    val date: LocalDate,
    val reviewCount: Int,
    val newCount: Int,
    val estimatedMinutes: Int,
    val streak: Int,
    val totalSolved: Int,
    val set: List<TodayCardDto>,
)

/** One logged attempt — the history the detail screen reads. */
data class SessionDto(
    val date: Instant,
    val outcome: SessionOutcome,
    val peeked: Boolean,
    val timeTakenMin: Int?,
    val timeComplexity: String?,
    val spaceComplexity: String?,
    val comfort: Double?,
)

data class ProblemDetailDto(
    val id: Long,
    val slug: String,
    val title: String,
    val difficulty: Difficulty,
    val topics: List<String>,
    val status: ProgressStatus,
    val comfort: Int,
    val comfortTrend: List<Double>,
    val nextReview: DueInfoDto?,
    val lcUrl: String,
    val history: List<SessionDto>,
)

/** Result of logging (or previewing) a session — powers the Log sheet's live preview. */
data class ScheduleResultDto(
    val stageFrom: Int,
    val stageTo: Int,
    val comfortFrom: Double,
    val comfortTo: Double,
    val intervalDays: Int,
    val reviewDate: LocalDate,
    val dueText: String,
    val status: ProgressStatus,
    val advanced: Boolean,
    val slipped: Boolean,
)

data class LogSessionRequest(
    val outcome: SessionOutcome,
    val peeked: Boolean = false,
    val timeTakenMin: Int? = null,
    val timeComplexity: String? = null,
    val spaceComplexity: String? = null,
)

data class TopicRatingDto(val category: String, val rating: TopicRating)
data class OnboardingRequest(val ratings: List<TopicRatingDto>)

/** Off-script resolve result: a single match for a pasted URL, or search hits for a name. */
data class ResolveResponse(
    val found: Boolean,
    val matches: List<ProblemSummaryDto>,
    val note: String? = null,
)

data class TopicComfortDto(val topic: String, val score: Double, val count: Int)
data class AnalyticsDto(
    val streak: Int,
    val totalSolved: Int,
    val topics: List<TopicComfortDto>,
    val weekly: List<Int>,
)
