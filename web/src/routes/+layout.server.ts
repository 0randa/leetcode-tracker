import { redirect } from '@sveltejs/kit';
import type { LayoutServerLoad } from './$types';

const ONBOARDING_COOKIE = 'onboardingComplete';

// First-run onboarding gate. The backend stores ratings as priors but exposes no
// "done" flag, so the client owns this UX gate via a cookie (mirrors the iOS
// UserDefaults flag). Everything except /onboarding redirects there until set.
export const load: LayoutServerLoad = async ({ cookies, url }) => {
	const onboarded = cookies.get(ONBOARDING_COOKIE) === '1';
	const onOnboarding = url.pathname.startsWith('/onboarding');

	if (!onboarded && !onOnboarding) {
		throw redirect(303, '/onboarding');
	}
	if (onboarded && onOnboarding) {
		throw redirect(303, '/');
	}

	return { onboarded };
};
