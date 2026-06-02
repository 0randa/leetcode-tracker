import { redirect } from '@sveltejs/kit';
import type { Actions } from './$types';

// First-run sign-in is a UX gate, not real auth (auth is a seam — see
// lib/server/session.ts). Each path just marks the device signed-in via a
// cookie (mirroring the onboarding gate) and hands off to onboarding. When real
// auth lands, these actions are where the OAuth/guest handshake plugs in.
const SIGNIN_COOKIE = 'signedIn';
const METHOD_COOKIE = 'authMethod';

function signIn(
	cookies: Parameters<Actions[string]>[0]['cookies'],
	method: 'google' | 'github' | 'guest'
): never {
	const opts = {
		path: '/',
		maxAge: 60 * 60 * 24 * 365,
		httpOnly: true,
		sameSite: 'lax'
	} as const;
	cookies.set(SIGNIN_COOKIE, '1', opts);
	cookies.set(METHOD_COOKIE, method, opts);
	throw redirect(303, '/onboarding');
}

export const actions: Actions = {
	google: async ({ cookies }) => signIn(cookies, 'google'),
	github: async ({ cookies }) => signIn(cookies, 'github'),
	guest: async ({ cookies }) => signIn(cookies, 'guest')
};
