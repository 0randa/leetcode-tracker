import { writable } from 'svelte/store';

export const toast = writable<string | null>(null);

let timer: ReturnType<typeof setTimeout> | undefined;

export function showToast(message: string, ms = 2500) {
	toast.set(message);
	if (timer) clearTimeout(timer);
	timer = setTimeout(() => toast.set(null), ms);
}
