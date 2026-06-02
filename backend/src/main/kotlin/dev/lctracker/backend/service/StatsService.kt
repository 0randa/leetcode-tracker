package dev.lctracker.backend.service

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
    private fun sessionDates(userId: Long): List<LocalDate> =
        sessions.findByUserId(userId).map { it.createdAt.atZone(ZoneOffset.UTC).toLocalDate() }

    fun streak(userId: Long): Int {
        val days = sessionDates(userId).toSortedSet()
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

    fun totalSolved(userId: Long): Int = sessions.findByUserId(userId)
        .filter { it.outcome != SessionOutcome.DIDNT_SOLVE }
        .map { it.problem.id }
        .distinct()
        .size

    fun weekly(userId: Long): List<Int> {
        val counts = sessionDates(userId).groupingBy { it }.eachCount()
        val today = today()
        return (6 downTo 0).map { counts[today.minusDays(it.toLong())] ?: 0 }
    }

    @Transactional(readOnly = true)
    fun topicComfort(userId: Long): List<TopicComfortDto> {
        val rows = mutableMapOf<String, MutableList<Double>>()
        for (p in progressRepo.findByUserId(userId)) {
            val c = p.comfort ?: continue
            for (tag in p.problem.tags) rows.getOrPut(tag.name) { mutableListOf() }.add(c)
        }
        return rows.map { (topic, scores) ->
            TopicComfortDto(topic, (scores.average() * 10).toLong() / 10.0, scores.size)
        }.sortedByDescending { it.score }
    }
}
