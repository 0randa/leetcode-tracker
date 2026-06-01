import { env } from '$env/dynamic/private';
import { error } from '@sveltejs/kit';

// The single typed wrapper around the Spring backend. The browser never calls
// Spring directly — only this server module knows SPRING_API_BASE. When auth
// lands, inject the user/session header HERE (one file to change — spec §9).

const BASE = (env.SPRING_API_BASE ?? 'http://localhost:8080').replace(/\/$/, '');

// Cold-start tolerant: Render's free tier sleeps after ~15 min idle and the
// first request can take ~30–60s (measured 69s once). The iOS client's 60s was
// too short — do not repeat that.
const TIMEOUT_MS = 90_000;

export class ApiError extends Error {
	constructor(
		public status: number,
		message: string
	) {
		super(message);
		this.name = 'ApiError';
	}
}

interface ApiOptions {
	method?: string;
	query?: Record<string, string | number | undefined | null>;
	body?: unknown;
	/** Pass through a SvelteKit load/action fetch if you want it tracked. */
	fetchFn?: typeof fetch;
}

async function request<T>(path: string, opts: ApiOptions = {}): Promise<T> {
	const f = opts.fetchFn ?? fetch;
	const url = new URL(BASE + path);
	if (opts.query) {
		for (const [k, v] of Object.entries(opts.query)) {
			if (v !== undefined && v !== null && v !== '') url.searchParams.set(k, String(v));
		}
	}

	const controller = new AbortController();
	const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);

	let res: Response;
	try {
		res = await f(url, {
			method: opts.method ?? 'GET',
			headers: opts.body !== undefined ? { 'content-type': 'application/json' } : undefined,
			body: opts.body !== undefined ? JSON.stringify(opts.body) : undefined,
			signal: controller.signal
		});
	} catch (e) {
		clearTimeout(timer);
		if (e instanceof DOMException && e.name === 'AbortError') {
			throw new ApiError(504, 'The server is waking up — try again in a moment.');
		}
		throw new ApiError(502, 'Could not reach the server.');
	}
	clearTimeout(timer);

	if (!res.ok) {
		throw new ApiError(res.status, `Server returned ${res.status}.`);
	}

	const text = await res.text();
	if (!text) return undefined as T;
	try {
		return JSON.parse(text) as T;
	} catch {
		throw new ApiError(502, "Couldn't read the server response.");
	}
}

/** Turn an ApiError into a SvelteKit `error()` for load() functions. */
export function apiToHttp(e: unknown): never {
	if (e instanceof ApiError) throw error(e.status >= 500 ? e.status : 502, e.message);
	throw error(502, 'Unexpected server error.');
}

export const api = { request };
