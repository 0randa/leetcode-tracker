<script lang="ts">
	import Badge from './Badge.svelte';
	import type { DueInfo } from '$lib/types';

	interface Props {
		info?: DueInfo | null;
		isNew?: boolean;
	}
	let { info = null, isNew = false }: Props = $props();
</script>

<!-- The single accent's urgency ramp: neutral (later) → accent text (due) →
     solid accent fill (overdue). "New" cards show a soft accent "New today" chip. -->
{#if isNew}
	<Badge text="New today" fg="var(--accent-text)" bg="var(--accent-bg)" bd="var(--accent-line)" />
{:else if info}
	{#if info.state === 'OVERDUE'}
		<span class="chip overdue">{info.text}</span>
	{:else if info.state === 'DUE'}
		<span class="chip due"><span class="dot"></span>{info.text}</span>
	{:else}
		<Badge text={info.text} fg="var(--ink3)" bg="var(--fill2)" bd="var(--line2)" />
	{/if}
{/if}

<style>
	.chip {
		display: inline-flex;
		align-items: center;
		gap: 5px;
		font-family: var(--mono);
		font-size: 10.5px;
		font-weight: 600;
		letter-spacing: 0.21px;
		padding: 3px 8px;
		border-radius: 999px;
		white-space: nowrap;
		line-height: 1.2;
	}
	.overdue {
		color: #fff;
		background: var(--accent);
	}
	.due {
		color: var(--accent-text);
		background: var(--accent-bg);
		border: 1px solid var(--accent-line);
	}
	.dot {
		width: 5px;
		height: 5px;
		border-radius: 999px;
		background: var(--accent);
	}
</style>
