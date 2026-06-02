package dev.lctracker.backend.auth

import dev.lctracker.backend.domain.User
import dev.lctracker.backend.domain.UserIdentity
import dev.lctracker.backend.repo.UserIdentityRepository
import dev.lctracker.backend.repo.UserRepository
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional

/** Result of resolving an OAuth profile to an account. */
data class UpsertResult(val userId: Long, val isNew: Boolean)

/** Upserts users + identities from an OAuth profile using [AccountResolver]. */
@Service
class AuthService(
    private val users: UserRepository,
    private val identities: UserIdentityRepository,
) {
    @Transactional
    fun upsert(profile: OAuthProfile): UpsertResult {
        val byIdentity = identities
            .findByProviderAndProviderUserId(profile.provider, profile.providerUserId)?.userId
        val byEmail = profile.email?.let { users.findByEmail(it)?.id }

        return when (val decision = AccountResolver.resolve(byIdentity, byEmail, profile.emailVerified)) {
            is AccountResolution.Existing -> UpsertResult(decision.userId, isNew = false)

            is AccountResolution.Link -> {
                identities.save(
                    UserIdentity(
                        userId = decision.userId,
                        provider = profile.provider,
                        providerUserId = profile.providerUserId,
                        email = profile.email,
                    ),
                )
                UpsertResult(decision.userId, isNew = false)
            }

            AccountResolution.New -> {
                val user = users.save(
                    User(email = profile.email, name = profile.name, avatarUrl = profile.avatarUrl),
                )
                identities.save(
                    UserIdentity(
                        userId = user.id,
                        provider = profile.provider,
                        providerUserId = profile.providerUserId,
                        email = profile.email,
                    ),
                )
                UpsertResult(user.id, isNew = true)
            }
        }
    }

    @Transactional(readOnly = true)
    fun user(userId: Long): User? = users.findById(userId).orElse(null)
}
