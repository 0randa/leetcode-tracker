package dev.lctracker.backend.auth

import kotlin.test.Test
import kotlin.test.assertEquals

class AccountResolverTest {
    @Test fun `existing identity wins, even if an email match also exists`() {
        val r = AccountResolver.resolve(byIdentity = 1000L, byEmail = 2000L, emailVerified = true)
        assertEquals(AccountResolution.Existing(1000L), r)
    }

    @Test fun `verified email with no identity links to that user`() {
        val r = AccountResolver.resolve(byIdentity = null, byEmail = 2000L, emailVerified = true)
        assertEquals(AccountResolution.Link(2000L), r)
    }

    @Test fun `unverified email does not link, creates new`() {
        val r = AccountResolver.resolve(byIdentity = null, byEmail = 2000L, emailVerified = false)
        assertEquals(AccountResolution.New, r)
    }

    @Test fun `no identity and no email match creates new`() {
        val r = AccountResolver.resolve(byIdentity = null, byEmail = null, emailVerified = true)
        assertEquals(AccountResolution.New, r)
    }
}
