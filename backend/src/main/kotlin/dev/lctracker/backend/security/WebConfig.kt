package dev.lctracker.backend.security

import dev.lctracker.backend.auth.AuthProperties
import dev.lctracker.backend.auth.StateCodec
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.web.method.support.HandlerMethodArgumentResolver
import org.springframework.web.servlet.config.annotation.InterceptorRegistry
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer

@Configuration
class WebConfig(
    private val authInterceptor: AuthInterceptor,
    private val currentUserIdResolver: CurrentUserIdArgumentResolver,
    private val authProperties: AuthProperties,
) : WebMvcConfigurer {
    override fun addInterceptors(registry: InterceptorRegistry) {
        registry.addInterceptor(authInterceptor).addPathPatterns("/api/**")
    }

    override fun addArgumentResolvers(resolvers: MutableList<HandlerMethodArgumentResolver>) {
        resolvers.add(currentUserIdResolver)
    }

    @Bean
    fun stateCodec(): StateCodec = StateCodec(authProperties.sessionSecret)
}
