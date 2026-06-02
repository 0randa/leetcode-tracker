package dev.lctracker.backend.auth

import com.fasterxml.jackson.annotation.JsonProperty
import org.springframework.http.MediaType
import org.springframework.stereotype.Component
import org.springframework.util.LinkedMultiValueMap
import org.springframework.web.client.RestClient
import java.net.URLEncoder
import java.nio.charset.StandardCharsets

/** Normalized identity from a provider. */
data class OAuthProfile(
    val provider: String,
    val providerUserId: String,
    val email: String?,
    val emailVerified: Boolean,
    val name: String?,
    val avatarUrl: String?,
)

/**
 * Hand-rolled OAuth2 authorization-code client for Google + GitHub, on the same
 * RestClient idiom as seed/LeetCodeClient. The backend is the only thing that holds
 * the client secrets and performs the token exchange.
 */
@Component
class OAuthClient(private val props: AuthProperties) {
    private val http: RestClient = RestClient.builder().build()

    fun authorizeUrl(provider: String, state: String): String = when (provider) {
        "google" -> buildUrl(
            "https://accounts.google.com/o/oauth2/v2/auth",
            "client_id" to props.googleClientId,
            "redirect_uri" to redirectUri("google"),
            "response_type" to "code",
            "scope" to "openid email profile",
            "access_type" to "online",
            "state" to state,
        )

        "github" -> buildUrl(
            "https://github.com/login/oauth/authorize",
            "client_id" to props.githubClientId,
            "redirect_uri" to redirectUri("github"),
            "scope" to "read:user user:email",
            "state" to state,
        )

        else -> throw IllegalArgumentException("Unknown provider '$provider'")
    }

    /** Build a URL with all query param values percent-encoded. */
    private fun buildUrl(base: String, vararg params: Pair<String, String>): String {
        val query = params.joinToString("&") { (k, v) ->
            "$k=${URLEncoder.encode(v, StandardCharsets.UTF_8)}"
        }
        return "$base?$query"
    }

    /** Exchange the code for a token and fetch the normalized profile. */
    fun exchange(provider: String, code: String): OAuthProfile = when (provider) {
        "google" -> google(code)
        "github" -> github(code)
        else -> throw IllegalArgumentException("Unknown provider '$provider'")
    }

    private fun redirectUri(provider: String) = "${props.webOrigin}/auth/$provider/callback"

    // ---- Google -----------------------------------------------------------
    private fun google(code: String): OAuthProfile {
        val form = LinkedMultiValueMap<String, String>().apply {
            add("code", code)
            add("client_id", props.googleClientId)
            add("client_secret", props.googleClientSecret)
            add("redirect_uri", redirectUri("google"))
            add("grant_type", "authorization_code")
        }
        val token = http.post()
            .uri("https://oauth2.googleapis.com/token")
            .contentType(MediaType.APPLICATION_FORM_URLENCODED)
            .body(form)
            .retrieve()
            .body(TokenResponse::class.java)
            ?: error("Google token exchange returned no body")

        val info = http.get()
            .uri("https://openidconnect.googleapis.com/v1/userinfo")
            .header("Authorization", "Bearer ${token.accessToken}")
            .retrieve()
            .body(GoogleUserInfo::class.java)
            ?: error("Google userinfo returned no body")

        return OAuthProfile(
            provider = "google",
            providerUserId = info.sub,
            email = info.email,
            emailVerified = info.emailVerified ?: false,
            name = info.name,
            avatarUrl = info.picture,
        )
    }

    // ---- GitHub -----------------------------------------------------------
    private fun github(code: String): OAuthProfile {
        val form = LinkedMultiValueMap<String, String>().apply {
            add("code", code)
            add("client_id", props.githubClientId)
            add("client_secret", props.githubClientSecret)
            add("redirect_uri", redirectUri("github"))
        }
        val token = http.post()
            .uri("https://github.com/login/oauth/access_token")
            .contentType(MediaType.APPLICATION_FORM_URLENCODED)
            .accept(MediaType.APPLICATION_JSON)
            .body(form)
            .retrieve()
            .body(TokenResponse::class.java)
            ?: error("GitHub token exchange returned no body")

        val user = http.get()
            .uri("https://api.github.com/user")
            .header("Authorization", "Bearer ${token.accessToken}")
            .header("Accept", "application/vnd.github+json")
            .retrieve()
            .body(GitHubUser::class.java)
            ?: error("GitHub user returned no body")

        val emails = http.get()
            .uri("https://api.github.com/user/emails")
            .header("Authorization", "Bearer ${token.accessToken}")
            .header("Accept", "application/vnd.github+json")
            .retrieve()
            .body(Array<GitHubEmail>::class.java)
            ?: emptyArray()
        val primary = emails.firstOrNull { it.primary && it.verified } ?: emails.firstOrNull { it.verified }

        return OAuthProfile(
            provider = "github",
            providerUserId = user.id.toString(),
            email = primary?.email ?: user.email,
            emailVerified = primary != null,
            name = user.name ?: user.login,
            avatarUrl = user.avatarUrl,
        )
    }
}

private data class TokenResponse(
    @field:JsonProperty("access_token") val accessToken: String? = null,
)

private data class GoogleUserInfo(
    val sub: String,
    val email: String? = null,
    @field:JsonProperty("email_verified") val emailVerified: Boolean? = null,
    val name: String? = null,
    val picture: String? = null,
)

private data class GitHubUser(
    val id: Long,
    val login: String,
    val name: String? = null,
    val email: String? = null,
    @field:JsonProperty("avatar_url") val avatarUrl: String? = null,
)

private data class GitHubEmail(
    val email: String,
    val primary: Boolean = false,
    val verified: Boolean = false,
)
