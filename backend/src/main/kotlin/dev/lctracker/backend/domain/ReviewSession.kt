package dev.lctracker.backend.domain

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.FetchType
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.JoinColumn
import jakarta.persistence.ManyToOne
import jakarta.persistence.Table
import java.time.Instant

/**
 * One row per logged attempt — the history the detail screen and analytics read.
 * `comfortAfter`/`stageAfter` snapshot the scheduler's output for this session.
 */
@Entity
@Table(name = "review_sessions")
class ReviewSession(
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "problem_id", nullable = false)
    val problem: Problem,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 24)
    var outcome: SessionOutcome,

    @Column(nullable = false)
    var peeked: Boolean = false,

    @Column(name = "user_id", nullable = false)
    var userId: Long = DEFAULT_USER_ID,

    @Column(name = "time_taken_min")
    var timeTakenMin: Int? = null,

    @Column(name = "time_complexity", length = 16)
    var timeComplexity: String? = null,

    @Column(name = "space_complexity", length = 16)
    var spaceComplexity: String? = null,

    @Column(name = "comfort_after")
    var comfortAfter: Double? = null,

    @Column(name = "stage_after")
    var stageAfter: Int? = null,

    @Column(name = "created_at", nullable = false)
    var createdAt: Instant = Instant.now(),

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,
)
