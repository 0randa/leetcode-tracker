import type { LogSessionRequest, ResolveResponse, ScheduleResult } from './types';

// Client-side calls that need to be interactive (live as the user types/toggles)
// go through the same-origin BFF proxy at /api/... — never to Spring directly.

async function proxyGet<T>(path: string, query?: Record<string, string>): Promise<T> {
	const url = new URL(path, location.origin);
	if (query) for (const [k, v] of Object.entries(query)) url.searchParams.set(k, v);
	const res = await fetch(url);
	if (!res.ok) throw new Error(`Request failed (${res.status})`);
	return res.json();
}

async function proxyPost<T>(path: string, body: unknown): Promise<T> {
	const res = await fetch(path, {
		method: 'POST',
		headers: { 'content-type': 'application/json' },
		body: JSON.stringify(body)
	});
	if (!res.ok) throw new Error(`Request failed (${res.status})`);
	return res.json();
}

export const clientApi = {
	resolve: (query: string) => proxyGet<ResolveResponse>('/api/resolve', { query }),

	previewSession: (id: number, body: LogSessionRequest) =>
		proxyPost<ScheduleResult>(`/api/problems/${id}/sessions/preview`, body),

	logSession: (id: number, body: LogSessionRequest) =>
		proxyPost<ScheduleResult>(`/api/problems/${id}/sessions`, body)
};
