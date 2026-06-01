<script lang="ts">
	import Icon from './Icon.svelte';
	import { monthDayFromLocal, fmtComfort } from '$lib/format';
	import type { ScheduleResult, SessionOutcome } from '$lib/types';

	interface Props {
		preview: ScheduleResult | null;
		outcome: SessionOutcome;
		peeked: boolean;
	}
	let { preview, outcome, peeked }: Props = $props();

	function dots(level: number) {
		return Math.round(level);
	}

	const note = $derived.by(() => {
		const pv = preview;
		if (!pv) return '';
		if (outcome === 'DIDNT_SOLVE') return 'Reset to the short interval — back in rotation soon.';
		if (peeked && pv.slipped) return 'Peeking slipped it back a step.';
		if (peeked) return 'Peeking holds it at this interval.';
		if (outcome === 'SOLVED_HINTS') return 'Hints — held at the current interval.';
		return 'Clean solve — advances to the next interval.';
	});
</script>

<!-- Live "What this schedules" card — next review + comfort move from the backend. -->
<div class="card">
	<div class="top">
		<span class="eyebrow">What this schedules</span>
		<Icon name="calendar" size={15} color="var(--accent-text)" />
	</div>

	{#if preview}
		<div class="row">
			<span class="lbl">Next review</span>
			<span class="trailing">
				<span class="date">{monthDayFromLocal(preview.reviewDate)}</span>
				<span class="in">· in {preview.intervalDays}d</span>
			</span>
		</div>

		<div class="row">
			<span class="lbl">Comfort</span>
			<span class="trailing comfort">
				{@render dotrow(dots(preview.comfortFrom), true)}
				<span class="arrow">→</span>
				{@render dotrow(dots(preview.comfortTo), false)}
				<span class="cval">{fmtComfort(preview.comfortFrom)} → {fmtComfort(preview.comfortTo)}</span>
			</span>
		</div>

		<hr class="div" />
		<p class="note">{note}</p>
	{:else}
		<p class="empty">Pick an outcome to preview the schedule.</p>
	{/if}
</div>

{#snippet dotrow(n: number, dim: boolean)}
	<span class="dots">
		{#each [1, 2, 3, 4, 5] as i (i)}
			<span class="d" class:on={i <= n} class:dim={dim && i <= n}></span>
		{/each}
	</span>
{/snippet}

<style>
	.card {
		display: flex;
		flex-direction: column;
		gap: 10px;
		padding: 12px 13px;
		border-radius: 12px;
		background: var(--accent-bg);
		border: 1px solid var(--accent-line);
	}
	.top {
		display: flex;
		align-items: center;
		justify-content: space-between;
	}
	.eyebrow {
		font-family: var(--mono);
		font-size: 10.5px;
		font-weight: 600;
		letter-spacing: 0.84px;
		text-transform: uppercase;
		color: var(--ink3);
	}
	.row {
		display: flex;
		align-items: center;
		justify-content: space-between;
	}
	.lbl {
		font-size: 12px;
		color: var(--ink2);
	}
	.trailing {
		display: inline-flex;
		align-items: center;
		gap: 4px;
	}
	.date {
		font-size: 13px;
		font-weight: 600;
		color: var(--ink);
	}
	.in {
		font-family: var(--mono);
		font-size: 11px;
		color: var(--accent-text);
	}
	.comfort {
		gap: 8px;
	}
	.dots {
		display: inline-flex;
		gap: 3px;
	}
	.d {
		width: 6px;
		height: 6px;
		border-radius: 999px;
		background: var(--fill);
		border: 1px solid var(--line);
	}
	.d.on {
		background: var(--accent);
		border-color: var(--accent);
	}
	.d.dim {
		background: var(--accent-mute);
		border-color: var(--accent-mute);
	}
	.arrow {
		font-family: var(--mono);
		font-size: 11px;
		color: var(--ink3);
	}
	.cval {
		font-family: var(--mono);
		font-size: 11px;
		font-weight: 600;
		color: var(--ink2);
	}
	.div {
		height: 1px;
		border: 0;
		background: var(--accent-line);
		margin: 0;
	}
	.note {
		margin: 0;
		font-size: 11px;
		color: var(--ink2);
	}
	.empty {
		margin: 0;
		font-size: 11px;
		color: var(--ink3);
	}
</style>
