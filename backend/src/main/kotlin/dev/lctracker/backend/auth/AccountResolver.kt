package dev.lctracker.backend.auth

/** What to do with an incoming OAuth profile. */
sealed interface AccountResolution {
    data class Existing(val userId: Long) : AccountResolution
    data class Link(val userId: Long) : AccountResolution
    data object New : AccountResolution
}

/**
 * Pure account-resolution decision. One account per verified email; a known identity
 * always wins; an unknown identity with a matching *verified* email links to it.
 */
object AccountResolver {
    fun resolve(byIdentity: Long?, byEmail: Long?, emailVerified: Boolean): AccountResolution = when {
        byIdentity != null -> AccountResolution.Existing(byIdentity)
        emailVerified && byEmail != null -> AccountResolution.Link(byEmail)
        else -> AccountResolution.New
    }
}
