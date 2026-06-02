package dev.lctracker.backend.security

import dev.lctracker.backend.auth.SessionService
import jakarta.servlet.http.HttpServletRequest
import jakarta.servlet.http.HttpServletResponse
import org.springframework.stereotype.Component
import org.springframework.web.servlet.HandlerInterceptor
import java.time.Instant

// Guards /api/** paths: resolves the bearer token to a userId or 401s. Stashes it for the resolver.
@Component
class AuthInterceptor(private val sessions: SessionService) : HandlerInterceptor {
    override fun preHandle(request: HttpServletRequest, response: HttpServletResponse, handler: Any): Boolean {
        val token = bearerToken(request.getHeader("Authorization"))
        val userId = token?.let { sessions.resolve(it, Instant.now()) }
        if (userId == null) {
            response.status = HttpServletResponse.SC_UNAUTHORIZED
            return false
        }
        request.setAttribute(USER_ID_ATTR, userId)
        return true
    }
}
