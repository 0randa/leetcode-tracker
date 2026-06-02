import { error } from '@sveltejs/kit';
import { backend } from '$lib/server/backend';
import { apiToHttp } from '$lib/server/api';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ params, fetch, locals }) => {
	const id = Number(params.id);
	if (!Number.isFinite(id)) throw error(404, 'Not found');
	try {
		const detail = await backend.detail(locals.session.token, id, fetch);
		return { detail };
	} catch (e) {
		apiToHttp(e);
	}
};
