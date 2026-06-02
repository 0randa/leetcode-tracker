import { json } from '@sveltejs/kit';
import { ApiError, api } from '$lib/server/api';
import type { RequestHandler } from './$types';

// BFF passthrough for interactive client-side fetches (off-script live search,
// log preview). The browser hits same-origin `/api/...`; only this server route
// knows the Spring base URL. Reuses the typed wrapper (90s timeout, auth seam).

async function proxy(event: Parameters<RequestHandler>[0]) {
	const { params, url, request } = event;
	const method = request.method;
	const path = '/api/' + params.path + (url.search ?? '');

	let body: unknown = undefined;
	if (method !== 'GET' && method !== 'HEAD') {
		const text = await request.text();
		if (text) {
			try {
				body = JSON.parse(text);
			} catch {
				body = undefined;
			}
		}
	}

	try {
		const data = await api.request<unknown>(path, {
			method,
			body,
			token: event.locals.session.token
		});
		return json(data ?? null);
	} catch (e) {
		const status = e instanceof ApiError ? e.status : 502;
		const message = e instanceof Error ? e.message : 'Proxy error';
		return json({ error: message }, { status });
	}
}

export const GET: RequestHandler = proxy;
export const POST: RequestHandler = proxy;
