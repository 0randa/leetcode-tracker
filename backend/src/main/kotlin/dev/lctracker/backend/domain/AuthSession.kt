package dev.lctracker.backend.domain

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.Id
import jakarta.persistence.Table
import java.time.Instant

/** An opaque server-side session. The token is the primary key. */
@Entity
@Table(name = "sessions")
class AuthSession(
    @Id
    @Column(name = "token")
    val token: String,

    @Column(name = "user_id", nullable = false)
    val userId: Long,

    @Column(name = "expires_at", nullable = false)
    var expiresAt: Instant,

    @Column(name = "created_at", nullable = false)
    val createdAt: Instant = Instant.now(),

    @Column(name = "last_seen_at", nullable = false)
    var lastSeenAt: Instant = Instant.now(),
)
