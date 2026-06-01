package dev.lctracker.backend.domain

/**
 * The single implicit user for the MVP. Auth is out of scope; per-user tables
 * carry this so multi-user/auth can be layered on later without a migration.
 */
const val DEFAULT_USER_ID: Long = 1
