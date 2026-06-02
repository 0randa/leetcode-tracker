import { redirect } from '@sveltejs/kit';
import type { LayoutServerLoad } from './$types';

const SIGNIN_COOKIE = 'signedIn';
const ONBOARDING_COOKIE = 'onboardingComplete';

// First-run gates, owned client-side via cookies (the backend has no auth or
// "onboarding done" flag). The order mirrors the design: sign-in → onboarding →
// app. Everything funnels to /signin until signed-in, then to /onboarding until
// rated, then into the app.
export const load: LayoutServerLoad = async ({ cookies, url }) => {
	const signedIn = cookies.get(SIGNIN_COOKIE) === '1';
	const onboarded = cookies.get(ONBOARDING_COOKIE) === '1';
	const onSignin = url.pathname.startsWith('/signin');
	const onOnboarding = url.pathname.startsWith('/onboarding');

	if (!signedIn) {
		if (!onSignin) throw redirect(303, '/signin');
		return { onboarded };
	}

	// Signed in: keep the sign-in screen out of reach.
	if (onSignin) {
		throw redirect(303, onboarded ? '/' : '/onboarding');
	}

	if (!onboarded && !onOnboarding) {
		throw redirect(303, '/onboarding');
	}
	if (onboarded && onOnboarding) {
		throw redirect(303, '/');
	}

	return { onboarded };
};
