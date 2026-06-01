package dev.lctracker.backend.service

import dev.lctracker.backend.domain.DEFAULT_USER_ID
import dev.lctracker.backend.domain.Difficulty
import dev.lctracker.backend.domain.ProgressStatus
import dev.lctracker.backend.domain.Scheduler
import dev.lctracker.backend.domain.UserProgress
import dev.lctracker.backend.repo.ProblemRepository
import dev.lctracker.backend.repo.ReviewSessionRepository
import dev.lctracker.backend.repo.UserProgressRepository
import dev.lctracker.backend.repo.UserTopicComfortRepository
import dev.lctracker.backend.web.ProblemDetailDto
import dev.lctracker.backend.web.ProblemSummaryDto
import dev.lctracker.backend.web.TodayCardDto
import dev.lctracker.backend.web.TodayDto
import dev.lctracker.backend.web.lcUrl
import dev.lctracker.backend.web.toSessionDto
import dev.lctracker.backend.web.toSummary
import dev.lctracker.backend.web.topicNames
import dev.lctracker.backend.web.toDto
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.server.ResponseStatusException
import java.time.LocalDate
import java.time.ZoneOffset

/** Daily set size (2 review + 1 new), and per-card time estimate. */
private const val DAILY_SET_SIZE = 3
private const val MAX_REVIEWS = 2
private const val MINUTES_PER_CARD = 15

/** Reads for Today, the problem list, and problem detail. */
@Service
class CatalogService(
    private val problems: ProblemRepository,
    private val progressRepo: UserProgressRepository,
    private val sessions: ReviewSessionRepository,
    private val topicComfort: UserTopicComfortRepository,
    private val stats: StatsService,
) {
    private fun todayDate(): LocalDate = LocalDate.now(ZoneOffset.UTC)
    private fun UserProgress.reviewDate(): LocalDate? =
        nextReviewAt?.atZone(ZoneOffset.UTC)?.toLocalDate()

    /** Today's set: up to 2 most-overdue reviews + new problems backfilling to 3. */
    @Transactional(readOnly = true)
    fun today(): TodayDto {
        val today = todayDate()
        val allProgress = progressRepo.findByUserId(DEFAULT_USER_ID)
        val progressByProblem = allProgress.associateBy { it.problem.id }

        val dueReviews = allProgress
            .filter { it.status == ProgressStatus.REVIEW }
            .filter { it.reviewDate()?.let { d -> !d.isAfter(today) } == true }
            .sortedBy { it.nextReviewAt }
            .take(MAX_REVIEWS)

        val newNeeded = DAILY_SET_SIZE - dueReviews.size
        val ratings = topicComfort.findByUserId(DEFAULT_USER_ID).associate { it.tag.name to it.rating }
        val newCandidates = problems.findAll()
            .filter { it.isActive && it.id !in progressByProblem.keys }
            // weighted toward weaker topics: lower prior first, then stable by id
            .sortedWith(compareBy({ p -> p.tags.mapNotNull { ratings[it.name] }.minOfOrNull(Scheduler::topicPrior) ?: 5.0 }, { it.id }))
            .take(newNeeded)

        val cards = dueReviews.map { prog ->
            TodayCardDto(
                kind = "Review",
                due = prog.reviewDate()?.let { Scheduler.dueInfo(it, today).toDto() },
                problem = toSummary(prog.problem, prog),
            )
        } + newCandidates.map { p ->
            TodayCardDto(kind = "New", due = null, problem = toSummary(p, null))
        }

        return TodayDto(
            date = today,
            reviewCount = dueReviews.size,
            newCount = newCandidates.size,
            estimatedMinutes = cards.size * MINUTES_PER_CARD,
            streak = stats.streak(),
            totalSolved = stats.totalSolved(),
            set = cards,
        )
    }

    @Transactional(readOnly = true)
    fun list(search: String?, topic: String?, difficulty: Difficulty?, status: ProgressStatus?): List<ProblemSummaryDto> {
        val progressByProblem = progressRepo.findByUserId(DEFAULT_USER_ID).associateBy { it.problem.id }
        return problems.findAll().asSequence()
            .filter { it.isActive }
            .map { toSummary(it, progressByProblem[it.id]) }
            .filter { search.isNullOrBlank() || it.title.contains(search, ignoreCase = true) }
            .filter { topic.isNullOrBlank() || it.topics.contains(topic) }
            .filter { difficulty == null || it.difficulty == difficulty }
            .filter { status == null || it.status == status }
            .sortedBy { it.id }
            .toList()
    }

    @Transactional(readOnly = true)
    fun detail(id: Long): ProblemDetailDto {
        val problem = problems.findById(id)
            .orElseThrow { ResponseStatusException(HttpStatus.NOT_FOUND, "No problem $id") }
        val progress = progressRepo.findByUserIdAndProblem_Id(DEFAULT_USER_ID, id)
        val history = sessions.findByUserIdAndProblem_IdOrderByCreatedAtDesc(DEFAULT_USER_ID, id)
        // comfort trend oldest → newest, for the sparkline/dots
        val trend = history.reversed().mapNotNull { it.comfortAfter }
        val nextReview = progress?.reviewDate()?.let { Scheduler.dueInfo(it, todayDate()).toDto() }

        return ProblemDetailDto(
            id = problem.id,
            slug = problem.slug,
            title = problem.title,
            difficulty = problem.difficulty,
            topics = problem.topicNames(),
            status = progress?.status ?: ProgressStatus.TODO,
            comfort = progress?.comfort?.let { Math.round(it).toInt() } ?: 0,
            comfortTrend = trend,
            nextReview = nextReview,
            lcUrl = lcUrl(problem.slug),
            history = history.map { toSessionDto(it) },
        )
    }
}
