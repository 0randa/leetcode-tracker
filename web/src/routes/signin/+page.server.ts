import { redirect } from '@sveltejs/kit';
import { dev } from '$app/environment';
import { backend } from '$lib/server/backend';
import type { Actions } from './$types';

// Real OAuth: each provider action asks the backend to build the consent URL, stores
// the signed state in an httpOnly cookie (CSRF binding), and redirects the browser to
// the provider. The provider returns to /auth/{provider}/callback.
const STATE_COOKIE = 'oauth_state';

async function start(
	provider: 'google' | 'github',
	cookies: Parameters<Actions[string]>[0]['cookies'],
	fetch: typeof globalThis.fetch
): Promise<never> {
	const { authorizeUrl, state } = await backend.authStart(provider, fetch);
	cookies.set(STATE_COOKIE, state, {
		path: '/',
		maxAge: 600,
		httpOnly: true,
		sameSite: 'lax',
		secure: !dev
	});
	throw redirect(303, authorizeUrl);
}

export const actions: Actions = {
	google: ({ cookies, fetch }) => start('google', cookies, fetch),
	github: ({ cookies, fetch }) => start('github', cookies, fetch)
};
