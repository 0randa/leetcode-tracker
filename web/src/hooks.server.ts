import type { Handle } from '@sveltejs/kit';
import { getSession } from '$lib/server/session';

// Resolve the (currently single-user) session once per request and stash it on
// locals. Auth-later seam — swap getSession for real auth without touching routes.
export const handle: Handle = async ({ event, resolve }) => {
	event.locals.session = getSession(event);
	return resolve(event);
};
