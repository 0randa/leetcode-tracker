package dev.lctracker.backend.auth

import java.security.MessageDigest
import java.security.SecureRandom
import java.time.Duration
import java.time.Instant
import java.util.Base64
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

/**
 * Signs/verifies the OAuth `state` parameter (CSRF). State carries the provider, an
 * expiry, and a random nonce, HMAC-SHA256 signed with the shared secret. Stateless —
 * nothing is stored server-side; the BFF also binds it to the browser via a cookie.
 *
 * Format: base64url(payload) + "." + base64url(hmac(payload)), payload = "provider:exp:nonce".
 */
class StateCodec(secret: String) {
    private val key = SecretKeySpec(secret.toByteArray(Charsets.UTF_8), "HmacSHA256")
    private val random = SecureRandom()
    private val enc = Base64.getUrlEncoder().withoutPadding()
    private val dec = Base64.getUrlDecoder()

    fun sign(provider: String, now: Instant, ttl: Duration = Duration.ofMinutes(10)): String {
        val nonceBytes = ByteArray(16).also(random::nextBytes)
        val nonce = enc.encodeToString(nonceBytes)
        val payload = "$provider:${now.plus(ttl).epochSecond}:$nonce"
        val p = enc.encodeToString(payload.toByteArray(Charsets.UTF_8))
        return "$p.${enc.encodeToString(hmac(payload))}"
    }

    fun verify(state: String, provider: String, now: Instant): Boolean {
        return try {
            val dot = state.indexOf('.')
            if (dot <= 0) return false
            val payloadB64 = state.substring(0, dot)
            val sigB64 = state.substring(dot + 1)
            val payload = String(dec.decode(payloadB64), Charsets.UTF_8)
            if (!constantTimeEquals(dec.decode(sigB64), hmac(payload))) return false
            val parts = payload.split(":")
            if (parts.size != 3) return false
            if (parts[0] != provider) return false
            val exp = parts[1].toLongOrNull() ?: return false
            exp > now.epochSecond
        } catch (_: Exception) {
            false
        }
    }

    private fun hmac(payload: String): ByteArray =
        Mac.getInstance("HmacSHA256").apply { init(key) }.doFinal(payload.toByteArray(Charsets.UTF_8))

    private fun constantTimeEquals(a: ByteArray, b: ByteArray): Boolean =
        MessageDigest.isEqual(a, b)
}
