package dev.lctracker.backend.seed

import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import org.springframework.web.client.RestClient

/** Problem metadata as returned by LeetCode's public GraphQL API. */
data class LeetCodeQuestion(
    val questionFrontendId: String,
    val title: String,
    val titleSlug: String,
    val difficulty: String,
    val isPaidOnly: Boolean = false,
)

/**
 * Thin client over LeetCode's public GraphQL endpoint. The backend is the only
 * thing that talks to LeetCode (clients never do). Used by the seed to enrich a
 * curated slug list with the stable numeric id, title, and difficulty.
 */
@Component
class LeetCodeClient {
    private val log = LoggerFactory.getLogger(javaClass)

    private val client: RestClient = RestClient.builder()
        .baseUrl("https://leetcode.com")
        // LeetCode rejects requests without a browser-like UA / Referer.
        .defaultHeader("User-Agent", "Mozilla/5.0 (compatible; lctracker-seed/1.0)")
        .defaultHeader("Referer", "https://leetcode.com")
        .defaultHeader("Content-Type", "application/json")
        .build()

    /** Fetch metadata for one problem by its title-slug, or null if not found / on error. */
    fun fetchQuestion(slug: String): LeetCodeQuestion? {
        val body = mapOf(
            "operationName" to "questionData",
            "variables" to mapOf("titleSlug" to slug),
            "query" to QUESTION_QUERY,
        )
        return try {
            val resp = client.post()
                .uri("/graphql")
                .body(body)
                .retrieve()
                .body(GraphQlResponse::class.java)
            val q = resp?.data?.question
            if (q == null) log.warn("No LeetCode question for slug '{}'", slug)
            q
        } catch (e: Exception) {
            log.warn("Failed to fetch slug '{}': {}", slug, e.message)
            null
        }
    }

    private data class GraphQlResponse(val data: DataNode?)
    private data class DataNode(val question: LeetCodeQuestion?)

    private companion object {
        const val QUESTION_QUERY = """
            query questionData(${'$'}titleSlug: String!) {
              question(titleSlug: ${'$'}titleSlug) {
                questionFrontendId
                title
                titleSlug
                difficulty
                isPaidOnly
              }
            }
        """
    }
}
