import { backend } from '$lib/server/backend';
import { apiToHttp } from '$lib/server/api';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ fetch, locals }) => {
	try {
		const analytics = await backend.analytics(locals.session.token, fetch);
		return { analytics };
	} catch (e) {
		apiToHttp(e);
	}
};
