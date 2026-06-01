// Parsing/formatting for the raw date strings the backend returns (LocalDate
// "2026-06-01", Instant ISO-8601). All display is in UTC to match the backend's
// start-of-day scheduling. Mirrors the iOS Formatting.swift.

const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const WEEKDAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/** Parse a LocalDate "yyyy-MM-dd" as a UTC Date (noon avoids TZ edge slips). */
export function parseLocalDate(s: string): Date | null {
	const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(s);
	if (!m) return null;
	return new Date(Date.UTC(+m[1], +m[2] - 1, +m[3], 12));
}

export function parseInstant(s: string): Date | null {
	const d = new Date(s);
	return isNaN(d.getTime()) ? null : d;
}

/** "Mon" weekday. */
export function weekday(d: Date): string {
	return WEEKDAYS[d.getUTCDay()];
}

/** "Jun 1". */
export function monthDay(d: Date): string {
	return `${MONTHS[d.getUTCMonth()]} ${d.getUTCDate()}`;
}

/** "Jun 1" from an Instant string (history rows). */
export function shortDateFromInstant(s: string): string {
	const d = parseInstant(s);
	return d ? monthDay(d) : '';
}

/** "Mon · Jun 1" header line from a LocalDate string. */
export function headerDate(s: string): string {
	const d = parseLocalDate(s);
	return d ? `${weekday(d)} · ${monthDay(d)}` : '';
}

export function monthDayFromLocal(s: string): string {
	const d = parseLocalDate(s);
	return d ? monthDay(d) : '';
}

/** Single-letter weekday initials for the last n UTC days, oldest → newest
 *  ending today — matching the backend's weekly window order. */
export function lastNWeekdayInitials(n: number): string[] {
	if (n <= 0) return [];
	const today = new Date();
	const out: string[] = [];
	for (let back = n - 1; back >= 0; back--) {
		const d = new Date(Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate() - back));
		out.push(WEEKDAYS[d.getUTCDay()].charAt(0));
	}
	return out;
}

/** Comfort numbers: integer shown bare, else one decimal (mirror iOS fmt). */
export function fmtComfort(v: number): string {
	return v === Math.round(v) ? String(Math.round(v)) : v.toFixed(1);
}
