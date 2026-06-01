<script lang="ts">
	import { invalidateAll, goto } from '$app/navigation';
	import { headerDate } from '$lib/format';
	import { showToast } from '$lib/stores/toast';
	import ProgressStrip from '$lib/components/ProgressStrip.svelte';
	import ProblemCard from '$lib/components/ProblemCard.svelte';
	import Icon from '$lib/components/Icon.svelte';
	import LogFab from '$lib/components/LogFab.svelte';
	import LogSheet from '$lib/components/LogSheet.svelte';
	import OffScriptSheet from '$lib/components/OffScriptSheet.svelte';
	import type { ProblemSummary, TodayCard } from '$lib/types';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
	const today = $derived(data.today);

	// Ephemeral per-session UI state — which cards were opened on LeetCode and
	// which were logged this session (mirrors the iOS AppStore opened/logged sets).
	let opened = $state<Set<number>>(new Set());
	let logged = $state<Set<number>>(new Set());

	let filter = $state<'Review' | 'New' | null>(null);
	let logTarget = $state<ProblemSummary | null>(null);
	let showFind = $state(false);

	const firstRun = $derived(today.totalSolved === 0 && today.streak === 0);
	const allNew = $derived(today.reviewCount === 0);
	const cards = $derived(filter === null ? today.set : today.set.filter((c) => c.kind === filter));
	const doneCount = $derived(today.set.filter((c) => logged.has(c.problem.id)).length);
	const nudge = $derived(
		today.set.find((c) => opened.has(c.problem.id) && !logged.has(c.problem.id)) ?? null
	);

	function openProblem(p: ProblemSummary) {
		window.open(p.lcUrl, '_blank', 'noopener');
		opened = new Set(opened).add(p.id);
	}

	async function afterLog(id: number) {
		logged = new Set(logged).add(id);
		const o = new Set(opened);
		o.delete(id);
		opened = o;
		await invalidateAll();
	}

	function toggle(k: 'Review' | 'New') {
		filter = filter === k ? null : k;
	}
</script>

<ProgressStrip streak={today.streak} solved={today.totalSolved} done={doneCount} total={today.set.length} />

<div class="scroll-y">
	{#if firstRun}
		<div class="welcome">
			<Icon name="flame" size={15} color="var(--ink3)" />
			<p>
				<b>Welcome!</b> No reviews yet — here’s your first all-new set. Reviews start appearing once
				you’ve logged a few.
			</p>
		</div>
	{:else if nudge}
		<button type="button" class="nudge" onclick={() => (logTarget = nudge.problem)}>
			<span class="ndot"></span>
			<span class="ntext">You opened <b>{nudge.problem.title}</b> — how did it go?</span>
			<span class="nlink">Log result →</span>
		</button>
	{/if}

	<div class="titlerow">
		<h1>Today</h1>
		<span class="date">{headerDate(today.date)}</span>
	</div>

	<div class="stats">
		{#if allNew}
			<div class="chiprow">
				{@render statChip(`${today.newCount}`, 'New', { isNew: true })}
				{@render statChip(`~${today.estimatedMinutes}`, 'min', {})}
			</div>
			<p class="statnote">Nothing due for review — fresh problems to build your queue.</p>
		{:else}
			<div class="chiprow">
				{@render statChip(`${today.reviewCount}`, 'Review', {
					selectable: true,
					key: 'Review'
				})}
				{@render statChip(`${today.newCount}`, 'New', {
					isNew: true,
					selectable: true,
					key: 'New'
				})}
				{@render statChip(`~${today.estimatedMinutes}`, 'min', {})}
			</div>
		{/if}
	</div>

	<div class="cards">
		{#each cards as card (card.problem.id)}
			<ProblemCard
				{card}
				opened={opened.has(card.problem.id)}
				logged={logged.has(card.problem.id)}
				onopen={() => openProblem(card.problem)}
				onlog={() => (logTarget = card.problem)}
				ondetail={() => goto(`/problems/${card.problem.id}`)}
			/>
		{/each}
	</div>
</div>

<LogFab onclick={() => (showFind = true)} />

{#if logTarget}
	<LogSheet
		problem={logTarget}
		onclose={() => (logTarget = null)}
		onlogged={() => afterLog(logTarget!.id)}
	/>
{/if}

{#if showFind}
	<OffScriptSheet
		onclose={() => (showFind = false)}
		onlogged={async (title) => {
			await invalidateAll();
			showToast(`Logged ${title}`);
		}}
	/>
{/if}

{#snippet statChip(
	n: string,
	label: string,
	opts: { isNew?: boolean; selectable?: boolean; key?: 'Review' | 'New' }
)}
	{@const selected = opts.key != null && filter === opts.key}
	{@const dim = opts.key != null && filter !== null && filter !== opts.key}
	<svelte:element
		this={opts.selectable ? 'button' : 'div'}
		class="chip"
		class:isnew={opts.isNew}
		class:selected
		class:dim
		role={opts.selectable ? 'button' : undefined}
		onclick={opts.selectable ? () => toggle(opts.key!) : undefined}
	>
		<b>{n}</b><span class="clabel">{label}</span>
	</svelte:element>
{/snippet}

<style>
	.welcome {
		display: flex;
		align-items: flex-start;
		gap: 9px;
		margin: 14px 16px 0;
		padding: 11px 13px;
		border-radius: 11px;
		background: var(--fill2);
		border: 1px solid var(--line2);
	}
	.welcome p {
		margin: 0;
		font-size: 11.5px;
		color: var(--ink2);
		line-height: 1.45;
	}
	.welcome b {
		color: var(--ink);
		font-weight: 700;
	}

	.nudge {
		display: flex;
		align-items: center;
		gap: 9px;
		width: calc(100% - 32px);
		margin: 14px 16px 0;
		padding: 10px 12px;
		border-radius: 11px;
		background: var(--accent-bg);
		border: 1px solid var(--accent-line);
		text-align: left;
	}
	.ndot {
		width: 6px;
		height: 6px;
		border-radius: 999px;
		background: var(--accent);
		flex: none;
	}
	.ntext {
		flex: 1;
		font-size: 12px;
		color: var(--accent-text);
	}
	.ntext b {
		font-weight: 700;
	}
	.nlink {
		font-size: 12px;
		font-weight: 600;
		color: var(--accent-text);
		white-space: nowrap;
	}

	.titlerow {
		display: flex;
		align-items: baseline;
		justify-content: space-between;
		padding: 16px 16px 2px;
	}
	h1 {
		margin: 0;
		font-size: 22px;
		font-weight: 700;
		color: var(--ink);
	}
	.date {
		font-family: var(--mono);
		font-size: 11.5px;
		font-weight: 500;
		color: var(--ink3);
	}

	.stats {
		padding: 10px 16px 12px;
	}
	.chiprow {
		display: flex;
		gap: 8px;
	}
	.chip {
		flex: 1;
		display: flex;
		align-items: baseline;
		gap: 5px;
		padding: 9px 12px;
		border-radius: 11px;
		background: #fff;
		border: 1px solid var(--line);
		text-align: left;
	}
	.chip b {
		font-size: 17px;
		font-weight: 700;
		color: var(--ink);
	}
	.clabel {
		font-size: 11.5px;
		font-weight: 500;
		color: var(--ink2);
	}
	.chip.isnew {
		background: var(--accent-bg);
		border-color: var(--accent-line);
	}
	.chip.isnew b,
	.chip.isnew .clabel {
		color: var(--accent-text);
	}
	.chip.selected {
		border-width: 2px;
		border-color: var(--ink);
		padding: 8px 11px;
	}
	.chip.isnew.selected {
		border-color: var(--accent);
	}
	.chip.dim {
		opacity: 0.45;
	}
	.statnote {
		margin: 9px 0 0;
		font-size: 11.5px;
		color: var(--ink2);
	}

	.cards {
		display: flex;
		flex-direction: column;
		gap: 12px;
		padding: 0 16px 16px;
	}
</style>
