package dev.lctracker.backend.auth

import org.springframework.boot.context.properties.ConfigurationProperties

/** OAuth + session config, bound from the `auth.*` env/yaml keys. */
@ConfigurationProperties("auth")
data class AuthProperties(
    val googleClientId: String = "",
    val googleClientSecret: String = "",
    val githubClientId: String = "",
    val githubClientSecret: String = "",
    val sessionSecret: String = "dev-insecure-secret-change-me",
    val webOrigin: String = "http://localhost:5173",
)
