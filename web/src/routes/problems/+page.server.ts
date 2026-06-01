import { backend } from '$lib/server/backend';
import { apiToHttp } from '$lib/server/api';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = async ({ url, fetch }) => {
	const filters = {
		search: url.searchParams.get('search') ?? undefined,
		topic: url.searchParams.get('topic') ?? undefined,
		difficulty: url.searchParams.get('difficulty') ?? undefined,
		status: url.searchParams.get('status') ?? undefined
	};
	try {
		const [items, topics] = await Promise.all([
			backend.problems(filters, fetch),
			backend.topics(fetch)
		]);
		return { items, topics, filters };
	} catch (e) {
		apiToHttp(e);
	}
};
