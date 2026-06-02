package dev.lctracker.backend.auth

import kotlin.test.Test
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

class OAuthClientTest {
    private val props = AuthProperties(
        googleClientId = "g-client",
        githubClientId = "h-client",
        webOrigin = "http://localhost:5173",
    )
    private val client = OAuthClient(props)

    @Test fun `google authorize url targets google with the right params`() {
        val url = client.authorizeUrl("google", "STATE123")
        assertTrue(url.startsWith("https://accounts.google.com/o/oauth2/v2/auth"))
        assertTrue(url.contains("client_id=g-client"))
        assertTrue(url.contains("state=STATE123"))
        assertTrue(url.contains("redirect_uri=http%3A%2F%2Flocalhost%3A5173%2Fauth%2Fgoogle%2Fcallback"))
        assertTrue(url.contains("scope=openid"))
    }

    @Test fun `github authorize url targets github with the right params`() {
        val url = client.authorizeUrl("github", "STATE123")
        assertTrue(url.startsWith("https://github.com/login/oauth/authorize"))
        assertTrue(url.contains("client_id=h-client"))
        assertTrue(url.contains("redirect_uri=http%3A%2F%2Flocalhost%3A5173%2Fauth%2Fgithub%2Fcallback"))
    }

    @Test fun `unknown provider is rejected`() {
        assertFailsWith<IllegalArgumentException> { client.authorizeUrl("twitter", "S") }
    }
}
