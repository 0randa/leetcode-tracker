package dev.lctracker.backend.domain

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.Table
import jakarta.persistence.UniqueConstraint
import java.time.Instant

/** Links a provider login (google/github) to a [User]. One user may link both. */
@Entity
@Table(
    name = "user_identities",
    uniqueConstraints = [UniqueConstraint(columnNames = ["provider", "provider_user_id"])],
)
class UserIdentity(
    @Column(name = "user_id", nullable = false)
    val userId: Long,

    @Column(nullable = false)
    var provider: String,

    @Column(name = "provider_user_id", nullable = false)
    var providerUserId: String,

    @Column
    var email: String? = null,

    @Column(name = "created_at", nullable = false)
    val createdAt: Instant = Instant.now(),

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,
)
