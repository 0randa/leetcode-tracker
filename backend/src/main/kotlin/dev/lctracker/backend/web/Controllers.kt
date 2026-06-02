package dev.lctracker.backend.web

import dev.lctracker.backend.domain.Difficulty
import dev.lctracker.backend.domain.ProgressStatus
import dev.lctracker.backend.security.CurrentUserId
import dev.lctracker.backend.service.CatalogService
import dev.lctracker.backend.service.OffScriptService
import dev.lctracker.backend.service.OnboardingService
import dev.lctracker.backend.service.ProgressService
import dev.lctracker.backend.service.StatsService
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api")
class TodayController(private val catalog: CatalogService) {
    @GetMapping("/today")
    fun today(@CurrentUserId userId: Long): TodayDto = catalog.today(userId)
}

@RestController
@RequestMapping("/api/problems")
class ProblemController(
    private val catalog: CatalogService,
    private val progress: ProgressService,
) {
    @GetMapping
    fun list(
        @CurrentUserId userId: Long,
        @RequestParam(required = false) search: String?,
        @RequestParam(required = false) topic: String?,
        @RequestParam(required = false) difficulty: Difficulty?,
        @RequestParam(required = false) status: ProgressStatus?,
    ): List<ProblemSummaryDto> = catalog.list(userId, search, topic, difficulty, status)

    @GetMapping("/{id}")
    fun detail(@CurrentUserId userId: Long, @PathVariable id: Long): ProblemDetailDto = catalog.detail(userId, id)

    @PostMapping("/{id}/sessions")
    fun log(@CurrentUserId userId: Long, @PathVariable id: Long, @RequestBody req: LogSessionRequest): ScheduleResultDto =
        progress.log(userId, id, req)

    @PostMapping("/{id}/sessions/preview")
    fun preview(@CurrentUserId userId: Long, @PathVariable id: Long, @RequestBody req: LogSessionRequest): ScheduleResultDto =
        progress.preview(userId, id, req.outcome, req.peeked)
}

@RestController
@RequestMapping("/api")
class OnboardingController(private val onboarding: OnboardingService) {
    @GetMapping("/topics")
    fun topics(): List<String> = onboarding.topics()

    @PostMapping("/onboarding")
    fun submit(@CurrentUserId userId: Long, @RequestBody req: OnboardingRequest): Map<String, String> {
        onboarding.submit(userId, req)
        return mapOf("status" to "ok")
    }
}

@RestController
@RequestMapping("/api")
class ResolveController(private val offScript: OffScriptService) {
    @GetMapping("/resolve")
    fun resolve(@CurrentUserId userId: Long, @RequestParam query: String): ResolveResponse = offScript.resolve(userId, query)
}

@RestController
@RequestMapping("/api")
class AnalyticsController(private val stats: StatsService) {
    @GetMapping("/analytics")
    fun analytics(@CurrentUserId userId: Long): AnalyticsDto = AnalyticsDto(
        streak = stats.streak(userId),
        totalSolved = stats.totalSolved(userId),
        topics = stats.topicComfort(userId),
        weekly = stats.weekly(userId),
    )
}
