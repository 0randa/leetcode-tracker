import type { RequestEvent } from '@sveltejs/kit';

// Auth-later seam (spec §9). Single-user now: one hardcoded context. When real
// auth lands, this is the one place that reads a session cookie and resolves the
// user — every backend call funnels through lib/server/api.ts, which can then
// forward the identity. Do NOT scatter user logic elsewhere.

export interface Session {
	/** Matches the backend's implicit single user (user_id default = 1). */
	userId: number;
}

const SINGLE_USER: Session = { userId: 1 };

// eslint-disable-next-line @typescript-eslint/no-unused-vars
export function getSession(_event: RequestEvent): Session {
	return SINGLE_USER;
}
