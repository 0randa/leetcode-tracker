package dev.lctracker.backend.security

import dev.lctracker.backend.auth.SessionService
import jakarta.servlet.http.HttpServletRequest
import org.springframework.core.MethodParameter
import org.springframework.http.HttpStatus
import org.springframework.stereotype.Component
import org.springframework.web.bind.support.WebDataBinderFactory
import org.springframework.web.context.request.NativeWebRequest
import org.springframework.web.method.support.HandlerMethodArgumentResolver
import org.springframework.web.method.support.ModelAndViewContainer
import org.springframework.web.server.ResponseStatusException
import java.time.Instant

/** Injects the authenticated user's id into a controller method parameter. */
@Target(AnnotationTarget.VALUE_PARAMETER)
@Retention(AnnotationRetention.RUNTIME)
annotation class CurrentUserId

const val USER_ID_ATTR = "userId"

/** Pull the bearer token out of an Authorization header, or null. */
fun bearerToken(header: String?): String? =
    header?.takeIf { it.startsWith("Bearer ", ignoreCase = true) }?.substring(7)?.trim()?.ifEmpty { null }

@Component
class CurrentUserIdArgumentResolver(private val sessions: SessionService) : HandlerMethodArgumentResolver {
    override fun supportsParameter(parameter: MethodParameter): Boolean =
        parameter.hasParameterAnnotation(CurrentUserId::class.java) &&
            parameter.parameterType == java.lang.Long::class.java

    override fun resolveArgument(
        parameter: MethodParameter,
        mavContainer: ModelAndViewContainer?,
        webRequest: NativeWebRequest,
        binderFactory: WebDataBinderFactory?,
    ): Any {
        val request = webRequest.getNativeRequest(HttpServletRequest::class.java)!!
        // /api/** already resolved by the interceptor.
        (request.getAttribute(USER_ID_ATTR) as? Long)?.let { return it }
        val token = bearerToken(request.getHeader("Authorization"))
        val userId = token?.let { sessions.resolve(it, Instant.now()) }
            ?: throw ResponseStatusException(HttpStatus.UNAUTHORIZED, "Not signed in")
        return userId
    }
}
