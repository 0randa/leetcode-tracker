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

export const backend = {
	today: (f?: typeof fetch) => api.request<Today>('/api/today', { fetchFn: f }),

	problems: (filters: ProblemFilters = {}, f?: typeof fetch) =>
		api.request<ProblemSummary[]>('/api/problems', { query: filters, fetchFn: f }),

	detail: (id: number, f?: typeof fetch) =>
		api.request<ProblemDetail>(`/api/problems/${id}`, { fetchFn: f }),

	topics: (f?: typeof fetch) => api.request<string[]>('/api/topics', { fetchFn: f }),

	analytics: (f?: typeof fetch) => api.request<Analytics>('/api/analytics', { fetchFn: f }),

	resolve: (query: string, f?: typeof fetch) =>
		api.request<ResolveResponse>('/api/resolve', { query: { query }, fetchFn: f }),

	logSession: (id: number, body: LogSessionRequest, f?: typeof fetch) =>
		api.request<ScheduleResult>(`/api/problems/${id}/sessions`, {
			method: 'POST',
			body,
			fetchFn: f
		}),

	previewSession: (id: number, body: LogSessionRequest, f?: typeof fetch) =>
		api.request<ScheduleResult>(`/api/problems/${id}/sessions/preview`, {
			method: 'POST',
			body,
			fetchFn: f
		}),

	submitOnboarding: (body: OnboardingRequest, f?: typeof fetch) =>
		api.request<void>('/api/onboarding', { method: 'POST', body, fetchFn: f })
};
