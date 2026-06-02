package dev.lctracker.backend.auth

import java.time.Instant
import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class StateCodecTest {
    private val codec = StateCodec("test-secret-key")
    private val now = Instant.parse("2026-06-02T10:00:00Z")

    @Test fun `a freshly signed state verifies`() {
        val state = codec.sign("google", now)
        assertTrue(codec.verify(state, "google", now))
    }

    @Test fun `a tampered state fails`() {
        val state = codec.sign("google", now)
        assertFalse(codec.verify(state + "x", "google", now))
    }

    @Test fun `tampering the payload half fails`() {
        val state = codec.sign("google", now)
        val (payload, sig) = state.split(".")
        assertFalse(codec.verify("${payload}x.$sig", "google", now))
    }

    @Test fun `a state signed for one provider fails for another`() {
        val state = codec.sign("google", now)
        assertFalse(codec.verify(state, "github", now))
    }

    @Test fun `an expired state fails`() {
        val state = codec.sign("google", now)
        assertFalse(codec.verify(state, "google", now.plusSeconds(601)))
    }

    @Test fun `a state is invalid at exactly its expiry instant`() {
        val state = codec.sign("google", now)
        assertFalse(codec.verify(state, "google", now.plusSeconds(600)))
    }

    @Test fun `a state signed with a different secret fails`() {
        val state = StateCodec("other-secret").sign("google", now)
        assertFalse(codec.verify(state, "google", now))
    }

    @Test fun `garbage input fails without throwing`() {
        assertFalse(codec.verify("not-a-valid-state", "google", now))
        assertFalse(codec.verify("", "google", now))
    }
}
