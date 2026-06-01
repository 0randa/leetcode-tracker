// TypeScript mirrors of the backend DTOs (dev.lctracker.backend.web.Dtos.kt),
// reproduced from the verified iOS Models.swift. Enum-like fields use the exact
// Kotlin constant names Jackson serializes. Date fields stay as raw server
// strings (LocalDate "2026-06-01", Instant ISO-8601) and are formatted for
// display in the view layer.

export type Difficulty = 'EASY' | 'MEDIUM' | 'HARD';
export type ProgressStatus = 'TODO' | 'REVIEW' | 'MASTERED';
export type TopicRating = 'COMFORTABLE' | 'SHAKY' | 'NOT_TRIED';
export type SessionOutcome = 'SOLVED_CLEAN' | 'SOLVED_HINTS' | 'DIDNT_SOLVE';
export type DueState = 'OVERDUE' | 'DUE' | 'SOON' | 'SCHEDULED';

export interface DueInfo {
	state: DueState;
	days: number;
	text: string;
}

export interface ProblemSummary {
	id: number;
	slug: string;
	title: string;
	difficulty: Difficulty;
	topics: string[];
	status: ProgressStatus;
	comfort: number;
	lcUrl: string;
}

export interface TodayCard {
	kind: 'Review' | 'New';
	due: DueInfo | null;
	problem: ProblemSummary;
}

export interface Today {
	date: string;
	reviewCount: number;
	newCount: number;
	estimatedMinutes: number;
	streak: number;
	totalSolved: number;
	set: TodayCard[];
}

export interface Session {
	date: string;
	outcome: SessionOutcome;
	peeked: boolean;
	timeTakenMin: number | null;
	timeComplexity: string | null;
	spaceComplexity: string | null;
	comfort: number | null;
}

export interface ProblemDetail {
	id: number;
	slug: string;
	title: string;
	difficulty: Difficulty;
	topics: string[];
	status: ProgressStatus;
	comfort: number;
	comfortTrend: number[];
	nextReview: DueInfo | null;
	lcUrl: string;
	history: Session[];
}

export interface ScheduleResult {
	stageFrom: number;
	stageTo: number;
	comfortFrom: number;
	comfortTo: number;
	intervalDays: number;
	reviewDate: string;
	dueText: string;
	status: ProgressStatus;
	advanced: boolean;
	slipped: boolean;
}

export interface LogSessionRequest {
	outcome: SessionOutcome;
	peeked?: boolean;
	timeTakenMin?: number | null;
	timeComplexity?: string | null;
	spaceComplexity?: string | null;
}

export interface TopicRatingDTO {
	category: string;
	rating: TopicRating;
}

export interface OnboardingRequest {
	ratings: TopicRatingDTO[];
}

export interface ResolveResponse {
	found: boolean;
	matches: ProblemSummary[];
	note: string | null;
}

export interface TopicComfort {
	topic: string;
	score: number;
	count: number;
}

export interface Analytics {
	streak: number;
	totalSolved: number;
	topics: TopicComfort[];
	weekly: number[];
}

// ---- Display label helpers (mirror the iOS enum `.label` extensions) ----

export const difficultyLabel: Record<Difficulty, string> = {
	EASY: 'Easy',
	MEDIUM: 'Medium',
	HARD: 'Hard'
};

/** Grayscale ordinal: filled segments out of three. */
export const difficultyLevel: Record<Difficulty, number> = {
	EASY: 1,
	MEDIUM: 2,
	HARD: 3
};

export const statusLabel: Record<ProgressStatus, string> = {
	TODO: 'To do',
	REVIEW: 'In review',
	MASTERED: 'Mastered'
};

export const ratingLabel: Record<TopicRating, string> = {
	COMFORTABLE: 'Comfortable',
	SHAKY: 'Shaky',
	NOT_TRIED: 'Not tried'
};

export const ratingFromLabel: Record<string, TopicRating> = {
	Comfortable: 'COMFORTABLE',
	Shaky: 'SHAKY',
	'Not tried': 'NOT_TRIED'
};

export const outcomeLabel: Record<SessionOutcome, string> = {
	SOLVED_CLEAN: 'Solved cleanly',
	SOLVED_HINTS: 'Solved with hints',
	DIDNT_SOLVE: "Didn't solve"
};

export const outcomeFromLabel: Record<string, SessionOutcome> = {
	'Solved cleanly': 'SOLVED_CLEAN',
	'Solved with hints': 'SOLVED_HINTS',
	"Didn't solve": 'DIDNT_SOLVE',
	'Didn’t solve': 'DIDNT_SOLVE'
};

export const ALL_DIFFICULTIES: Difficulty[] = ['EASY', 'MEDIUM', 'HARD'];
export const ALL_STATUSES: ProgressStatus[] = ['TODO', 'REVIEW', 'MASTERED'];

/** Primary topic tag shown on cards/rows. */
export function primaryTopic(p: { topics: string[] }): string {
	return p.topics[0] ?? '';
}
