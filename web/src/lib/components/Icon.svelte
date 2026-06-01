<script lang="ts" module>
	// Minimal 1.6px line icons (feather-style), mirroring the iOS WFIcon set.
	// currentColor + stroke so they inherit color and stay thin.
	export type IconName =
		| 'home'
		| 'list'
		| 'chart'
		| 'search'
		| 'flame'
		| 'check'
		| 'chevR'
		| 'chevD'
		| 'ext'
		| 'close'
		| 'filter'
		| 'plus'
		| 'clock'
		| 'back'
		| 'star'
		| 'link'
		| 'gear'
		| 'calendar'
		| 'trendUp'
		| 'inbox';

	const PATHS: Record<IconName, string> = {
		home: '<path d="M3 10.5 12 3l9 7.5"/><path d="M5 9.5V21h14V9.5"/>',
		list: '<path d="M8 6h13"/><path d="M8 12h13"/><path d="M8 18h13"/><path d="M3 6h.01"/><path d="M3 12h.01"/><path d="M3 18h.01"/>',
		chart: '<path d="M3 3v18h18"/><rect x="7" y="11" width="3" height="6"/><rect x="13" y="7" width="3" height="10"/>',
		search: '<circle cx="11" cy="11" r="7"/><path d="m20 20-3.2-3.2"/>',
		flame: '<path d="M12 22c4 0 6.5-2.7 6.5-6 0-3.5-3-5-3-8 0-1.5-1-3-2.5-4 .3 2.5-1 4-2.5 5.5C8 7 6.5 9 6.5 12c0 3.3 1.5 10 5.5 10Z"/>',
		check: '<path d="m5 12.5 4.5 4.5L19 6.5"/>',
		chevR: '<path d="m9 5 7 7-7 7"/>',
		chevD: '<path d="m5 9 7 7 7-7"/>',
		ext: '<path d="M7 17 17 7"/><path d="M8 7h9v9"/>',
		close: '<path d="M6 6 18 18"/><path d="M18 6 6 18"/>',
		filter: '<path d="M3 6h18"/><path d="M6 12h12"/><path d="M10 18h4"/>',
		plus: '<path d="M12 5v14"/><path d="M5 12h14"/>',
		clock: '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>',
		back: '<path d="m15 5-7 7 7 7"/>',
		star: '<path d="m12 3 2.7 5.8 6.3.7-4.7 4.3 1.3 6.2L12 17l-5.6 3 1.3-6.2L3 9.5l6.3-.7L12 3Z"/>',
		link: '<path d="M9.5 14.5 14.5 9.5"/><path d="M8 11 6 13a3.5 3.5 0 0 0 5 5l2-2"/><path d="M16 13l2-2a3.5 3.5 0 0 0-5-5l-2 2"/>',
		gear: '<circle cx="12" cy="12" r="3"/><path d="M19 12a7 7 0 0 0-.12-1.3l2-1.5-2-3.4-2.3 1a7 7 0 0 0-2.2-1.3L13.8 2h-3.6l-.4 2.5a7 7 0 0 0-2.2 1.3l-2.3-1-2 3.4 2 1.5A7 7 0 0 0 5 12c0 .44.04.87.12 1.3l-2 1.5 2 3.4 2.3-1a7 7 0 0 0 2.2 1.3l.4 2.5h3.6l.4-2.5a7 7 0 0 0 2.2-1.3l2.3 1 2-3.4-2-1.5c.08-.43.12-.86.12-1.3Z"/>',
		calendar: '<rect x="3.5" y="5" width="17" height="16" rx="2"/><path d="M3.5 9.5h17"/><path d="M8 3v4"/><path d="M16 3v4"/>',
		trendUp: '<path d="M3 17 9 11l4 4 8-8"/><path d="M16 7h5v5"/>',
		inbox: '<path d="M3 13h5l1.5 3h5L16 13h5"/><path d="M4.5 13 6 5h12l1.5 8v5a1.5 1.5 0 0 1-1.5 1.5H6A1.5 1.5 0 0 1 4.5 18Z"/>'
	};
</script>

<script lang="ts">
	interface Props {
		name: IconName;
		size?: number;
		color?: string;
		bold?: boolean;
	}
	let { name, size = 18, color = 'var(--ink2)', bold = false }: Props = $props();
</script>

<svg
	width={size}
	height={size}
	viewBox="0 0 24 24"
	fill="none"
	stroke={color}
	stroke-width={bold ? 2.1 : 1.7}
	stroke-linecap="round"
	stroke-linejoin="round"
	aria-hidden="true"
	style="display:block;flex:none"
>
	{@html PATHS[name]}
</svg>
