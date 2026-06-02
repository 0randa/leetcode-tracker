package dev.lctracker.backend.service

import dev.lctracker.backend.domain.Difficulty
import dev.lctracker.backend.domain.Problem
import dev.lctracker.backend.repo.ProblemRepository
import dev.lctracker.backend.repo.UserProgressRepository
import dev.lctracker.backend.seed.LeetCodeClient
import dev.lctracker.backend.web.ResolveResponse
import dev.lctracker.backend.web.toSummary
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

/** Off-script logging: resolve a pasted LeetCode URL or a typed name to a problem. */
@Service
class OffScriptService(
    private val problems: ProblemRepository,
    private val progressRepo: UserProgressRepository,
    private val leetCode: LeetCodeClient,
) {
    private val urlSlug = Regex("""leetcode\.com/problems/([a-z0-9-]+)""", RegexOption.IGNORE_CASE)

    @Transactional
    fun resolve(userId: Long, query: String): ResolveResponse {
        val q = query.trim()
        if (q.isEmpty()) return ResolveResponse(found = false, matches = emptyList(), note = "Enter a URL or problem name")

        // A pasted LeetCode URL resolves directly to one problem.
        urlSlug.find(q)?.groupValues?.get(1)?.let { slug ->
            val match = problems.findBySlug(slug) ?: fetchAndStore(slug)
            return if (match != null) {
                ResolveResponse(true, listOf(summary(userId, match)), trackingNote(userId, match))
            } else {
                ResolveResponse(false, emptyList(), "Couldn't find that one on LeetCode")
            }
        }

        // Otherwise treat it as a name search over the catalogue.
        val hits = problems.findAll().asSequence()
            .filter { it.isActive && it.title.contains(q, ignoreCase = true) }
            .sortedBy { it.id }
            .take(10)
            .map { summary(userId, it) }
            .toList()
        return ResolveResponse(found = hits.isNotEmpty(), matches = hits)
    }

    private fun summary(userId: Long, p: Problem) =
        toSummary(p, progressRepo.findByUserIdAndProblem_Id(userId, p.id))

    private fun trackingNote(userId: Long, p: Problem): String {
        val progress = progressRepo.findByUserIdAndProblem_Id(userId, p.id)
        val date = progress?.nextReviewAt ?: return "Not tracked yet — logging starts its schedule"
        return "Already in review (next $date) — logging reschedules from today"
    }

    /** Resolve a slug not in our catalogue against LeetCode, storing it off-script (untagged). */
    private fun fetchAndStore(slug: String): Problem? {
        val q = leetCode.fetchQuestion(slug) ?: return null
        val id = q.questionFrontendId.toLong()
        return problems.findById(id).orElseGet {
            problems.save(
                Problem(
                    id = id,
                    slug = q.titleSlug,
                    title = q.title,
                    difficulty = Difficulty.valueOf(q.difficulty.uppercase()),
                    isNeetcode150 = false,
                ),
            )
        }
    }
}
