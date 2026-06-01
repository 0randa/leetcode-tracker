import { redirect } from '@sveltejs/kit';
import { backend } from '$lib/server/backend';
import { apiToHttp } from '$lib/server/api';
import { ratingFromLabel, type TopicRatingDTO } from '$lib/types';
import type { Actions, PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ fetch }) => {
	try {
		const topics = await backend.topics(fetch);
		return { topics };
	} catch (e) {
		apiToHttp(e);
	}
};

export const actions: Actions = {
	default: async ({ request, fetch, cookies }) => {
		const form = await request.formData();
		const ratings: TopicRatingDTO[] = [];
		for (const [category, value] of form.entries()) {
			const rating = ratingFromLabel[String(value)];
			if (rating) ratings.push({ category, rating });
		}

		// Priors are an optimization — proceed into the app even if submit fails
		// (mirrors the iOS try? behavior).
		try {
			await backend.submitOnboarding({ ratings }, fetch);
		} catch {
			/* ignore — still let the user in */
		}

		// Owns the first-run gate (the backend has no "done" flag).
		cookies.set('onboardingComplete', '1', {
			path: '/',
			maxAge: 60 * 60 * 24 * 365,
			httpOnly: true,
			sameSite: 'lax'
		});

		throw redirect(303, '/');
	}
};
