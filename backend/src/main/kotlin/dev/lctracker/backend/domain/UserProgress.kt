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
import jakarta.persistence.UniqueConstraint
import java.time.Instant

/**
 * Per-user, per-problem spaced-repetition state. `comfort` and `stage` are
 * computed by the backend scheduler; the user never edits them directly.
 */
@Entity
@Table(
    name = "user_progress",
    uniqueConstraints = [UniqueConstraint(columnNames = ["user_id", "problem_id"])],
)
class UserProgress(
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "problem_id", nullable = false)
    val problem: Problem,

    @Column(name = "user_id", nullable = false)
    var userId: Long,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    var status: ProgressStatus = ProgressStatus.TODO,

    /** Computed comfort 1.0–5.0; null until the first attempt is logged. */
    @Column
    var comfort: Double? = null,

    /** Index into the interval ladder (0..4). */
    @Column(nullable = false)
    var stage: Int = 0,

    @Column(name = "last_reviewed_at")
    var lastReviewedAt: Instant? = null,

    @Column(name = "next_review_at")
    var nextReviewAt: Instant? = null,

    @Column(name = "created_at", nullable = false)
    var createdAt: Instant = Instant.now(),

    @Column(name = "updated_at", nullable = false)
    var updatedAt: Instant = Instant.now(),

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,
)
