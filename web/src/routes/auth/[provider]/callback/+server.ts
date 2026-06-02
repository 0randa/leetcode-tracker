import { error, redirect } from '@sveltejs/kit';
import { dev } from '$app/environment';
import { backend } from '$lib/server/backend';
import { SESSION_COOKIE } from '$lib/server/session';
import type { RequestHandler } from './$types';

const STATE_COOKIE = 'oauth_state';

export const GET: RequestHandler = async ({ params, url, cookies, fetch }) => {
	const provider = params.provider;
	if (provider !== 'google' && provider !== 'github') throw error(404, 'Unknown provider');

	const code = url.searchParams.get('code');
	const state = url.searchParams.get('state');
	const saved = cookies.get(STATE_COOKIE);
	cookies.delete(STATE_COOKIE, { path: '/' });

	if (!code || !state || !saved || state !== saved) {
		throw error(400, 'Sign-in could not be verified. Please try again.');
	}

	let result;
	try {
		result = await backend.authCallback(provider, code, state, fetch);
	} catch {
		throw error(502, 'Sign-in failed. Please try again.');
	}

	cookies.set(SESSION_COOKIE, result.token, {
		path: '/',
		httpOnly: true,
		sameSite: 'lax',
		secure: !dev,
		maxAge: 60 * 60 * 24 * 30
	});

	throw redirect(303, result.isNewUser ? '/onboarding' : '/');
};
