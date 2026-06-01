import { backend } from '$lib/server/backend';
import { apiToHttp } from '$lib/server/api';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ fetch }) => {
	try {
		const analytics = await backend.analytics(fetch);
		return { analytics };
	} catch (e) {
		apiToHttp(e);
	}
};
