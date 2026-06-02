import { backend } from '$lib/server/backend';
import { apiToHttp } from '$lib/server/api';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ fetch, locals }) => {
	try {
		const today = await backend.today(locals.session.token, fetch);
		return { today };
	} catch (e) {
		apiToHttp(e);
	}
};
