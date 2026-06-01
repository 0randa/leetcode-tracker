<script lang="ts">
	import Icon from './Icon.svelte';
	import DiffBadge from './DiffBadge.svelte';
	import TopicTag from './TopicTag.svelte';
	import DueChip from './DueChip.svelte';
	import Comfort from './Comfort.svelte';
	import Btn from './Btn.svelte';
	import { primaryTopic, type TodayCard } from '$lib/types';

	interface Props {
		card: TodayCard;
		opened: boolean;
		logged: boolean;
		onopen: () => void;
		onlog: () => void;
		ondetail: () => void;
	}
	let { card, opened, logged, onopen, onlog, ondetail }: Props = $props();

	const p = $derived(card.problem);
	const isNew = $derived(card.kind === 'New');
	const inProgress = $derived(opened && !logged);
</script>

<!-- A single Today card (variant A — stacked). Opening on LeetCode flips it to
     in-progress; it isn't done until logged. -->
<article class="card" class:logged class:inprogress={inProgress}>
	<div
		class="header"
		role="button"
		tabindex="0"
		onclick={ondetail}
		onkeydown={(e) => (e.key === 'Enter' ? ondetail() : null)}
	>
		<div class="hleft">
			<div class="kindrow">
				<span class="kind" class:new={isNew}>{isNew ? 'NEW' : 'REVIEW'}</span>
				<DueChip info={card.due} {isNew} />
				{#if inProgress}
					<span class="inprog"><span class="dot"></span>In progress</span>
				{/if}
			</div>
			<h3>{p.title}</h3>
		</div>
		{#if logged}
			<Icon name="check" size={20} color="var(--ink)" />
		{:else}
			<Icon name="chevR" size={17} color="var(--ink3)" />
		{/if}
	</div>

	<div class="meta">
		<DiffBadge difficulty={p.difficulty} />
		<TopicTag topic={primaryTopic(p)} />
		<span class="spacer"></span>
		<Comfort level={p.comfort} showLabel />
	</div>

	<div class="actions">
		{#if logged}
			<Btn title="Logged ✓" variant="subtle" size="sm" full />
		{:else if inProgress}
			<Btn title="Log result" variant="primary" size="sm" full icon="check" onclick={onlog} />
			<Btn title="Reopen" variant="outline" size="sm" icon="ext" onclick={onopen} />
		{:else}
			<Btn title="Open in LeetCode" variant="primary" size="sm" full icon="ext" onclick={onopen} />
			<Btn title="Log" variant="outline" size="sm" onclick={onlog} />
		{/if}
	</div>
</article>

<style>
	.card {
		display: flex;
		flex-direction: column;
		gap: 11px;
		padding: 14px;
		border-radius: 14px;
		background: #fff;
		border: 1px solid var(--line);
		box-shadow: 0 1px 1px rgba(20, 22, 28, 0.04);
	}
	.card.inprogress {
		border-color: var(--accent-line);
	}
	.card.logged {
		background: var(--fill2);
		border-color: var(--line2);
		box-shadow: none;
		opacity: 0.66;
	}

	.header {
		display: flex;
		align-items: flex-start;
		gap: 10px;
		cursor: pointer;
	}
	.hleft {
		display: flex;
		flex-direction: column;
		gap: 8px;
		flex: 1;
		min-width: 0;
	}
	.kindrow {
		display: flex;
		align-items: center;
		gap: 6px;
		flex-wrap: wrap;
	}
	.kind {
		font-family: var(--mono);
		font-size: 10px;
		font-weight: 600;
		letter-spacing: 0.6px;
		color: var(--ink3);
	}
	.kind.new {
		color: var(--accent-text);
	}
	.inprog {
		display: inline-flex;
		align-items: center;
		gap: 5px;
		font-family: var(--mono);
		font-size: 10.5px;
		font-weight: 600;
		color: var(--accent-text);
		background: var(--accent-bg);
		border: 1px solid var(--accent-line);
		padding: 3px 8px;
		border-radius: 999px;
	}
	.inprog .dot {
		width: 5px;
		height: 5px;
		border-radius: 999px;
		background: var(--accent);
	}
	h3 {
		margin: 0;
		font-size: 15.5px;
		font-weight: 650;
		line-height: 1.32;
		color: var(--ink);
	}

	.meta {
		display: flex;
		align-items: center;
		gap: 7px;
	}
	.spacer {
		flex: 1;
	}

	.actions {
		display: flex;
		gap: 8px;
	}
</style>
