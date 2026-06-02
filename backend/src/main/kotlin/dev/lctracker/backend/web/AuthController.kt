package dev.lctracker.backend.web

import dev.lctracker.backend.auth.AuthService
import dev.lctracker.backend.auth.OAuthClient
import dev.lctracker.backend.auth.SessionService
import dev.lctracker.backend.auth.StateCodec
import dev.lctracker.backend.security.CurrentUserId
import dev.lctracker.backend.security.bearerToken
import org.springframework.http.HttpStatus
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestHeader
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController
import org.springframework.web.server.ResponseStatusException
import java.time.Instant

data class StartResponse(val authorizeUrl: String, val state: String)
data class CallbackRequest(val code: String, val state: String)
data class CallbackResponse(val token: String, val expiresAt: Instant, val isNewUser: Boolean)
data class MeResponse(val userId: Long, val email: String?, val name: String?, val avatarUrl: String?)

@RestController
@RequestMapping("/auth")
class AuthController(
    private val oauth: OAuthClient,
    private val stateCodec: StateCodec,
    private val auth: AuthService,
    private val sessions: SessionService,
) {
    @GetMapping("/{provider}/start")
    fun start(@PathVariable provider: String): StartResponse {
        requireProvider(provider)
        val state = stateCodec.sign(provider, Instant.now())
        return StartResponse(oauth.authorizeUrl(provider, state), state)
    }

    @PostMapping("/{provider}/callback")
    fun callback(@PathVariable provider: String, @RequestBody req: CallbackRequest): CallbackResponse {
        requireProvider(provider)
        if (!stateCodec.verify(req.state, provider, Instant.now())) {
            throw ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid state")
        }
        val profile = try {
            oauth.exchange(provider, req.code)
        } catch (e: Exception) {
            // Provider/network failure during the code exchange — surface a clean 502
            // (the web BFF maps this to a friendly "sign-in failed" rather than leaking a 500).
            throw ResponseStatusException(HttpStatus.BAD_GATEWAY, "Sign-in failed during token exchange")
        }
        val result = auth.upsert(profile)
        val session = sessions.create(result.userId, Instant.now())
        return CallbackResponse(session.token, session.expiresAt, result.isNew)
    }

    @PostMapping("/logout")
    fun logout(@RequestHeader(value = "Authorization", required = false) authz: String?) {
        bearerToken(authz)?.let { sessions.delete(it) }
    }

    @GetMapping("/me")
    fun me(@CurrentUserId userId: Long): MeResponse {
        val u = auth.user(userId) ?: throw ResponseStatusException(HttpStatus.UNAUTHORIZED, "Not signed in")
        return MeResponse(u.id, u.email, u.name, u.avatarUrl)
    }

    private fun requireProvider(provider: String) {
        if (provider != "google" && provider != "github") {
            throw ResponseStatusException(HttpStatus.NOT_FOUND, "Unknown provider")
        }
    }
}
