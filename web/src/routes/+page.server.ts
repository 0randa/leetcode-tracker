import { backend } from '$lib/server/backend';
import { apiToHttp } from '$lib/server/api';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ fetch }) => {
	try {
		const today = await backend.today(fetch);
		return { today };
	} catch (e) {
		apiToHttp(e);
	}
};
