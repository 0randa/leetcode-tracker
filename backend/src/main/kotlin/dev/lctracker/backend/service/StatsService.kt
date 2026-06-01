package dev.lctracker.backend.service

import dev.lctracker.backend.domain.DEFAULT_USER_ID
import dev.lctracker.backend.domain.SessionOutcome
import dev.lctracker.backend.repo.ReviewSessionRepository
import dev.lctracker.backend.repo.UserProgressRepository
import dev.lctracker.backend.web.TopicComfortDto
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.LocalDate
import java.time.ZoneOffset

/** Streak / totals / topic-comfort rollups, shared by Today and Analytics. */
@Service
class StatsService(
    private val sessions: ReviewSessionRepository,
    private val progressRepo: UserProgressRepository,
) {
    private fun today(): LocalDate = LocalDate.now(ZoneOffset.UTC)
    private fun sessionDates(): List<LocalDate> =
        sessions.findByUserId(DEFAULT_USER_ID).map { it.createdAt.atZone(ZoneOffset.UTC).toLocalDate() }

    /** Consecutive days (UTC) with at least one session, ending today or yesterday. */
    fun streak(): Int {
        val days = sessionDates().toSortedSet()
        if (days.isEmpty()) return 0
        val today = today()
        var cursor = when {
            days.contains(today) -> today
            days.contains(today.minusDays(1)) -> today.minusDays(1)
            else -> return 0
        }
        var streak = 0
        while (days.contains(cursor)) {
            streak++
            cursor = cursor.minusDays(1)
        }
        return streak
    }

    /** Distinct problems with at least one genuinely-solved session. */
    fun totalSolved(): Int = sessions.findByUserId(DEFAULT_USER_ID)
        .filter { it.outcome != SessionOutcome.DIDNT_SOLVE }
        .map { it.problem.id }
        .distinct()
        .size

    /** Sessions per day for the last 7 days (oldest → newest), for the weekly trend. */
    fun weekly(): List<Int> {
        val counts = sessionDates().groupingBy { it }.eachCount()
        val today = today()
        return (6 downTo 0).map { counts[today.minusDays(it.toLong())] ?: 0 }
    }

    /** Topics ranked by mean comfort across attempted problems (strongest first). */
    @Transactional(readOnly = true)
    fun topicComfort(): List<TopicComfortDto> {
        val rows = mutableMapOf<String, MutableList<Double>>()
        for (p in progressRepo.findByUserId(DEFAULT_USER_ID)) {
            val c = p.comfort ?: continue
            for (tag in p.problem.tags) rows.getOrPut(tag.name) { mutableListOf() }.add(c)
        }
        return rows.map { (topic, scores) ->
            TopicComfortDto(topic, (scores.average() * 10).toLong() / 10.0, scores.size)
        }.sortedByDescending { it.score }
    }
}
