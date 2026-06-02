import type { RequestEvent } from '@sveltejs/kit';

// Auth seam. The session is the opaque backend token, held in an httpOnly cookie on
// the web origin and forwarded to Spring as `Authorization: Bearer` (lib/server/api.ts).
// Identity details (email/name) come from GET /auth/me when needed.

export const SESSION_COOKIE = 'session';

export interface Session {
	/** Opaque backend session token, or null when not signed in. */
	token: string | null;
}

export function getSession(event: RequestEvent): Session {
	return { token: event.cookies.get(SESSION_COOKIE) ?? null };
}
