import { redirect } from '@sveltejs/kit';
import { ApiError, apiToHttp } from '$lib/server/api';
import { backend } from '$lib/server/backend';
import { SESSION_COOKIE } from '$lib/server/session';
import type { LayoutServerLoad } from './$types';

const ONBOARDING_COOKIE = 'onboardingComplete';

// Gate order mirrors the design: sign-in → onboarding → app. A "valid session" is a
// token the backend accepts (GET /auth/me). The OAuth callback/logout are +server /
// action routes and don't run this layout load.
export const load: LayoutServerLoad = async ({ cookies, url, locals, fetch }) => {
	const token = locals.session.token;
	const onSignin = url.pathname.startsWith('/signin');
	const onOnboarding = url.pathname.startsWith('/onboarding');

	let valid = false;
	if (token) {
		try {
			await backend.authMe(token, fetch);
			valid = true;
		} catch (e) {
			// 401 = bad/expired session → clear and treat as signed-out.
			// Other errors (backend down / cold start) must NOT log the user out.
			if (e instanceof ApiError && e.status === 401) {
				cookies.delete(SESSION_COOKIE, { path: '/' });
			} else {
				apiToHttp(e);
			}
		}
	}

	const onboarded = cookies.get(ONBOARDING_COOKIE) === '1';

	if (!valid) {
		if (!onSignin) throw redirect(303, '/signin');
		return { onboarded: false };
	}

	if (onSignin) throw redirect(303, onboarded ? '/' : '/onboarding');
	if (!onboarded && !onOnboarding) throw redirect(303, '/onboarding');
	if (onboarded && onOnboarding) throw redirect(303, '/');
	return { onboarded };
};
