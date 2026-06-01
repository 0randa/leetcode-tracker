package dev.lctracker.backend.seed

import dev.lctracker.backend.domain.Difficulty
import dev.lctracker.backend.domain.Problem
import dev.lctracker.backend.domain.Tag
import dev.lctracker.backend.repo.ProblemRepository
import dev.lctracker.backend.repo.TagRepository
import org.slf4j.LoggerFactory
import org.springframework.boot.ApplicationArguments
import org.springframework.boot.ApplicationRunner
import org.springframework.core.io.ClassPathResource
import org.springframework.stereotype.Component
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import tools.jackson.databind.ObjectMapper

/** Shape of the bundled `seed/neetcode-150.json` resource. */
data class SeedList(val problems: List<SeedEntry>)
data class SeedEntry(val category: String, val slug: String)

/**
 * Seeds the catalogue from the bundled NeetCode-150 list, enriching each entry
 * with metadata from LeetCode's GraphQL API. Upsert keyed on the numeric LeetCode
 * id, so it is safe to re-run. Only runs when the app is started with `--seed`:
 *
 *   ./gradlew bootRun --args='--seed'
 *   java -jar build/libs/backend-*.jar --seed
 */
@Component
class SeedRunner(
    private val leetCode: LeetCodeClient,
    private val seedService: SeedService,
    private val objectMapper: ObjectMapper,
) : ApplicationRunner {
    private val log = LoggerFactory.getLogger(javaClass)

    override fun run(args: ApplicationArguments) {
        if (!args.containsOption("seed")) return

        val list = ClassPathResource("seed/neetcode-150.json").inputStream.use {
            objectMapper.readValue(it, SeedList::class.java)
        }
        log.info("Seeding {} problems from NeetCode-150 list...", list.problems.size)

        var ok = 0
        var failed = 0
        val failures = mutableListOf<String>()
        for ((i, entry) in list.problems.withIndex()) {
            val q = leetCode.fetchQuestion(entry.slug)
            if (q == null) {
                failed++
                failures += entry.slug
                continue
            }
            seedService.upsert(q, entry.category)
            ok++
            if ((i + 1) % 25 == 0) log.info("  ... {}/{}", i + 1, list.problems.size)
            Thread.sleep(250) // be polite to LeetCode
        }

        log.info("Seed complete: {} upserted, {} failed.", ok, failed)
        if (failures.isNotEmpty()) log.warn("Failed slugs: {}", failures)
    }
}

@Service
class SeedService(
    private val problems: ProblemRepository,
    private val tags: TagRepository,
) {
    /** Upsert one problem + its NeetCode category tag. Idempotent on the numeric id. */
    @Transactional
    fun upsert(q: LeetCodeQuestion, category: String) {
        val tag = tags.findByName(category) ?: tags.save(Tag(name = category))
        val id = q.questionFrontendId.toLong()
        val difficulty = Difficulty.valueOf(q.difficulty.uppercase())

        val problem = problems.findById(id).orElse(null)?.apply {
            // Keep metadata fresh on re-seed; numeric id is the stable key so a
            // slug/title rename updates in place rather than orphaning progress.
            slug = q.titleSlug
            title = q.title
            this.difficulty = difficulty
            isNeetcode150 = true
            isActive = true
        } ?: Problem(
            id = id,
            slug = q.titleSlug,
            title = q.title,
            difficulty = difficulty,
            isNeetcode150 = true,
        )

        if (problem.tags.none { it.name == category }) problem.tags.add(tag)
        problems.save(problem)
    }
}
