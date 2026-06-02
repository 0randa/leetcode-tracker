package dev.lctracker.backend.service

import dev.lctracker.backend.domain.UserTopicComfort
import dev.lctracker.backend.repo.TagRepository
import dev.lctracker.backend.repo.UserTopicComfortRepository
import dev.lctracker.backend.web.OnboardingRequest
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import org.springframework.web.server.ResponseStatusException

/** First-run topic comfort ratings → priors that seed the scheduler. */
@Service
class OnboardingService(
    private val tags: TagRepository,
    private val topicComfort: UserTopicComfortRepository,
) {
    /** The topic list to rate (the NeetCode categories), in a stable order. */
    @Transactional(readOnly = true)
    fun topics(): List<String> = tags.findAll().map { it.name }.sorted()

    /** Upsert each topic rating. Re-running onboarding overwrites prior ratings. */
    @Transactional
    fun submit(userId: Long, req: OnboardingRequest) {
        val existing = topicComfort.findByUserId(userId).associateBy { it.tag.name }
        for (r in req.ratings) {
            val tag = tags.findByName(r.category)
                ?: throw ResponseStatusException(HttpStatus.BAD_REQUEST, "Unknown topic '${r.category}'")
            val row = existing[r.category]
            if (row != null) {
                row.rating = r.rating
                topicComfort.save(row)
            } else {
                topicComfort.save(UserTopicComfort(tag = tag, rating = r.rating, userId = userId))
            }
        }
    }
}
