import { api } from './api';
import type {
	Analytics,
	LogSessionRequest,
	OnboardingRequest,
	ProblemDetail,
	ProblemSummary,
	ResolveResponse,
	ScheduleResult,
	Today
} from '$lib/types';

// Typed surface over the backend `/api`. Every read/write funnels through here →
// lib/server/api.ts (the one auth-injection seam). `fetchFn` lets load()/actions
// pass SvelteKit's tracked fetch.

export interface ProblemFilters {
	search?: string;
	topic?: string;
	difficulty?: string;
	status?: string;
	[key: string]: string | undefined;
}

export interface AuthStart {
	authorizeUrl: string;
	state: string;
}
export interface AuthCallbackResult {
	token: string;
	expiresAt: string;
	isNewUser: boolean;
}
export interface AuthMe {
	userId: number;
	email: string | null;
	name: string | null;
	avatarUrl: string | null;
}

export const backend = {
	today: (token: string | null, f?: typeof fetch) =>
		api.request<Today>('/api/today', { token, fetchFn: f }),

	problems: (token: string | null, filters: ProblemFilters = {}, f?: typeof fetch) =>
		api.request<ProblemSummary[]>('/api/problems', { query: filters, token, fetchFn: f }),

	detail: (token: string | null, id: number, f?: typeof fetch) =>
		api.request<ProblemDetail>(`/api/problems/${id}`, { token, fetchFn: f }),

	topics: (token: string | null, f?: typeof fetch) =>
		api.request<string[]>('/api/topics', { token, fetchFn: f }),

	analytics: (token: string | null, f?: typeof fetch) =>
		api.request<Analytics>('/api/analytics', { token, fetchFn: f }),

	resolve: (token: string | null, query: string, f?: typeof fetch) =>
		api.request<ResolveResponse>('/api/resolve', { query: { query }, token, fetchFn: f }),

	logSession: (token: string | null, id: number, body: LogSessionRequest, f?: typeof fetch) =>
		api.request<ScheduleResult>(`/api/problems/${id}/sessions`, { method: 'POST', body, token, fetchFn: f }),

	previewSession: (token: string | null, id: number, body: LogSessionRequest, f?: typeof fetch) =>
		api.request<ScheduleResult>(`/api/problems/${id}/sessions/preview`, { method: 'POST', body, token, fetchFn: f }),

	submitOnboarding: (token: string | null, body: OnboardingRequest, f?: typeof fetch) =>
		api.request<void>('/api/onboarding', { method: 'POST', body, token, fetchFn: f }),

	// ---- auth (no bearer needed for start/callback) ----
	authStart: (provider: string, f?: typeof fetch) =>
		api.request<AuthStart>(`/auth/${provider}/start`, { fetchFn: f }),

	authCallback: (provider: string, code: string, state: string, f?: typeof fetch) =>
		api.request<AuthCallbackResult>(`/auth/${provider}/callback`, {
			method: 'POST',
			body: { code, state },
			fetchFn: f
		}),

	authMe: (token: string, f?: typeof fetch) => api.request<AuthMe>('/auth/me', { token, fetchFn: f }),

	authLogout: (token: string, f?: typeof fetch) =>
		api.request<void>('/auth/logout', { method: 'POST', token, fetchFn: f })
};
