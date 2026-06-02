import { redirect } from '@sveltejs/kit';
import { backend } from '$lib/server/backend';
import { SESSION_COOKIE } from '$lib/server/session';
import type { Actions } from './$types';

export const actions: Actions = {
	default: async ({ cookies, fetch }) => {
		const token = cookies.get(SESSION_COOKIE);
		if (token) {
			try {
				await backend.authLogout(token, fetch);
			} catch {
				/* best-effort server-side revoke */
			}
		}
		cookies.delete(SESSION_COOKIE, { path: '/' });
		throw redirect(303, '/signin');
	}
};
