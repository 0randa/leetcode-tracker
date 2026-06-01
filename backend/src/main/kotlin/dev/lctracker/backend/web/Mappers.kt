package dev.lctracker.backend.web

import dev.lctracker.backend.domain.DueInfo
import dev.lctracker.backend.domain.Problem
import dev.lctracker.backend.domain.ProgressStatus
import dev.lctracker.backend.domain.ReviewSession
import dev.lctracker.backend.domain.UserProgress
import kotlin.math.roundToInt

/** Must be called inside a transaction (touches the lazy `tags` association). */
fun Problem.topicNames(): List<String> = tags.map { it.name }.sorted()

fun lcUrl(slug: String) = "https://leetcode.com/problems/$slug/"

fun DueInfo.toDto() = DueInfoDto(state, days, text)

fun toSummary(problem: Problem, progress: UserProgress?) = ProblemSummaryDto(
    id = problem.id,
    slug = problem.slug,
    title = problem.title,
    difficulty = problem.difficulty,
    topics = problem.topicNames(),
    status = progress?.status ?: ProgressStatus.TODO,
    comfort = progress?.comfort?.roundToInt() ?: 0,
    lcUrl = lcUrl(problem.slug),
)

fun toSessionDto(s: ReviewSession) = SessionDto(
    date = s.createdAt,
    outcome = s.outcome,
    peeked = s.peeked,
    timeTakenMin = s.timeTakenMin,
    timeComplexity = s.timeComplexity,
    spaceComplexity = s.spaceComplexity,
    comfort = s.comfortAfter,
)
