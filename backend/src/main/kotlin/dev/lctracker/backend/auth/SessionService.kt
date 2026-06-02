package dev.lctracker.backend.auth

import dev.lctracker.backend.domain.AuthSession
import dev.lctracker.backend.repo.SessionRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.security.SecureRandom
import java.time.Duration
import java.time.Instant
import java.util.Base64

/** Creates, resolves, and revokes opaque sessions. 30-day absolute expiry. */
@Service
class SessionService(private val sessions: SessionRepository) {
    private val random = SecureRandom()
    private val enc = Base64.getUrlEncoder().withoutPadding()
    private val lifetime = Duration.ofDays(30)

    @Transactional
    fun create(userId: Long, now: Instant): AuthSession {
        val token = enc.encodeToString(ByteArray(32).also(random::nextBytes))
        return sessions.save(
            AuthSession(token = token, userId = userId, expiresAt = now.plus(lifetime), createdAt = now, lastSeenAt = now),
        )
    }

    /** Resolve a token to its userId, or null if missing/expired. Touches last_seen_at. */
    @Transactional
    fun resolve(token: String, now: Instant): Long? {
        val s = sessions.findById(token).orElse(null) ?: return null
        if (!s.expiresAt.isAfter(now)) return null
        s.lastSeenAt = now
        sessions.save(s)
        return s.userId
    }

    @Transactional
    fun delete(token: String) {
        if (sessions.existsById(token)) sessions.deleteById(token)
    }
}
