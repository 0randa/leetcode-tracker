package dev.lctracker.backend.service

import dev.lctracker.backend.domain.DEFAULT_USER_ID
import dev.lctracker.backend.domain.Problem
import dev.lctracker.backend.domain.ProgressStatus
import dev.lctracker.backend.domain.ReviewSession
import dev.lctracker.backend.domain.Scheduler
import dev.lctracker.backend.domain.SessionOutcome
import dev.lctracker.backend.domain.UserProgress
import dev.lctracker.backend.repo.ProblemRepository
import dev.lctracker.backend.repo.ReviewSessionRepository
import dev.lctracker.backend.repo.UserProgressRepository
import dev.lctracker.backend.repo.UserTopicComfortRepository
import dev.lctracker.backend.web.LogSessionRequest
import dev.lctracker.backend.web.ScheduleResultDto
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.server.ResponseStatusException
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneOffset
import kotlin.math.roundToLong

/** Default comfort when a problem's topic has no onboarding rating (matches scheduler.jsx). */
private const val UNKNOWN_PRIOR = 2.5

/**
 * Applies the [Scheduler] to log sessions and preview their effect. This is where
 * the spaced-repetition model meets persistence; all the math lives in [Scheduler].
 */
@Service
class ProgressService(
    private val problems: ProblemRepository,
    private val progressRepo: UserProgressRepository,
    private val sessions: ReviewSessionRepository,
    private val topicComfort: UserTopicComfortRepository,
) {
    private fun today(): LocalDate = LocalDate.now(ZoneOffset.UTC)
    private fun round1(v: Double) = (v * 10).roundToLong() / 10.0

    private fun problemOrThrow(id: Long): Problem =
        problems.findById(id).orElseThrow { ResponseStatusException(HttpStatus.NOT_FOUND, "No problem $id") }

    /** Prior comfort to feed the EMA: the problem's current comfort, else its topic prior. */
    private fun priorComfort(problem: Problem, progress: UserProgress?): Double {
        progress?.comfort?.let { return it }
        val ratings = topicComfort.findByUserId(DEFAULT_USER_ID).associate { it.tag.name to it.rating }
        return problem.tags.mapNotNull { ratings[it.name] }
            .minOfOrNull { Scheduler.topicPrior(it) }
            ?: UNKNOWN_PRIOR
    }

    private fun compute(problem: Problem, progress: UserProgress?, outcome: SessionOutcome, peeked: Boolean): ScheduleResultDto {
        val stage0 = progress?.stage ?: 0
        val comfort0 = priorComfort(problem, progress)
        val stage1 = Scheduler.nextStage(stage0, outcome, peeked)
        val comfort1 = Scheduler.nextComfort(comfort0, outcome, peeked)
        val interval = Scheduler.intervalForStage(stage1)
        val reviewDate = today().plusDays(interval.toLong())
        val status = Scheduler.statusFor(stage1, comfort1, hasHistory = true)
        return ScheduleResultDto(
            stageFrom = stage0,
            stageTo = stage1,
            comfortFrom = round1(comfort0),
            comfortTo = comfort1,
            intervalDays = interval,
            reviewDate = reviewDate,
            dueText = "Due in $interval days",
            status = status,
            advanced = stage1 > stage0,
            slipped = stage1 < stage0,
        )
    }

    /** Compute what logging this session would do, without persisting. */
    @Transactional(readOnly = true)
    fun preview(problemId: Long, outcome: SessionOutcome, peeked: Boolean): ScheduleResultDto {
        val problem = problemOrThrow(problemId)
        val progress = progressRepo.findByUserIdAndProblem_Id(DEFAULT_USER_ID, problemId)
        return compute(problem, progress, outcome, peeked)
    }

    /** Log a session: write history and reschedule the problem from today. */
    @Transactional
    fun log(problemId: Long, req: LogSessionRequest): ScheduleResultDto {
        val problem = problemOrThrow(problemId)
        val progress = progressRepo.findByUserIdAndProblem_Id(DEFAULT_USER_ID, problemId)
        val result = compute(problem, progress, req.outcome, req.peeked)
        val now = Instant.now()

        sessions.save(
            ReviewSession(
                problem = problem,
                outcome = req.outcome,
                peeked = req.peeked,
                timeTakenMin = req.timeTakenMin,
                timeComplexity = req.timeComplexity,
                spaceComplexity = req.spaceComplexity,
                comfortAfter = result.comfortTo,
                stageAfter = result.stageTo,
                createdAt = now,
            ),
        )

        val p = progress ?: UserProgress(problem = problem, createdAt = now)
        p.stage = result.stageTo
        p.comfort = result.comfortTo
        p.status = result.status
        p.lastReviewedAt = now
        p.nextReviewAt = result.reviewDate.atStartOfDay(ZoneOffset.UTC).toInstant()
        p.updatedAt = now
        progressRepo.save(p)

        return result
    }
}
