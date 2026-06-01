<script lang="ts">
	import { goto, invalidateAll } from '$app/navigation';
	import Icon from '$lib/components/Icon.svelte';
	import DiffBadge from '$lib/components/DiffBadge.svelte';
	import TopicTag from '$lib/components/TopicTag.svelte';
	import StatusBadge from '$lib/components/StatusBadge.svelte';
	import Comfort from '$lib/components/Comfort.svelte';
	import Btn from '$lib/components/Btn.svelte';
	import LogSheet from '$lib/components/LogSheet.svelte';
	import { shortDateFromInstant } from '$lib/format';
	import { outcomeLabel, primaryTopic, type ProblemSummary, type Session } from '$lib/types';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
	const d = $derived(data.detail);

	let showLog = $state(false);

	const dueAccent = $derived(d.nextReview?.state === 'DUE' || d.nextReview?.state === 'OVERDUE');

	function summary(): ProblemSummary {
		return {
			id: d.id,
			slug: d.slug,
			title: d.title,
			difficulty: d.difficulty,
			topics: d.topics,
			status: d.status,
			comfort: d.comfort,
			lcUrl: d.lcUrl
		};
	}

	function outcomeColor(s: Session): string {
		return s.outcome === 'SOLVED_CLEAN'
			? 'var(--ink)'
			: s.outcome === 'SOLVED_HINTS'
				? 'var(--ink2)'
				: 'var(--ink3)';
	}
</script>

<header class="head">
	<div class="topbar">
		<button type="button" class="back" onclick={() => goto('/problems')}>
			<Icon name="back" size={17} color="var(--ink2)" /><span>Back</span>
		</button>
		<span class="gear"><Icon name="gear" size={18} color="var(--ink3)" /></span>
	</div>
	<div class="titleblock">
		<h1>{d.title}</h1>
		<div class="badges">
			<DiffBadge difficulty={d.difficulty} />
			<TopicTag topic={primaryTopic(d)} />
			<StatusBadge status={d.status} />
		</div>
		<div class="openbtn">
			<Btn title="Open in LeetCode" variant="outline" size="sm" icon="ext" onclick={() => window.open(d.lcUrl, '_blank', 'noopener')} />
		</div>
	</div>
</header>

<div class="scroll-y body">
	<div class="statblock">
		<div class="comfortcard">
			<span class="eyebrow">Comfort</span>
			<div class="comfortrow">
				<span class="big">{d.comfort}</span><span class="slash">/5</span>
				<span class="spacer"></span>
				{#if d.comfortTrend.length}
					<span class="trend">
						{#each d.comfortTrend as v, i (i)}
							<span class="tcol">
								<span class="tdot" class:last={i === d.comfortTrend.length - 1}></span>
								<span class="tval">{Math.round(v)}</span>
							</span>
						{/each}
						<Icon name="trendUp" size={15} color="var(--ink2)" />
					</span>
				{/if}
			</div>
		</div>

		<div class="nextcard" class:accent={dueAccent}>
			<span class="eyebrow">Next review</span>
			<div class="nextrow">
				<Icon name="calendar" size={16} color={dueAccent ? 'var(--accent-text)' : 'var(--ink2)'} />
				<span class="nexttext" class:accent={dueAccent}>{d.nextReview?.text ?? 'Not scheduled'}</span>
			</div>
		</div>
	</div>

	{#if d.history.length === 0}
		<div class="empty">
			<div class="emptyicon"><Icon name="inbox" size={24} color="var(--ink3)" /></div>
			<div class="etitle">Not attempted yet</div>
			<p>
				No sessions logged for this one. Solve it on LeetCode, then log how it went to start its
				review schedule.
			</p>
		</div>
	{:else}
		<div class="history">
			<span class="eyebrow">History · {d.history.length} sessions</span>
			<div class="timeline">
				{#each d.history as s, i (i)}
					{@const last = i === d.history.length - 1}
					<div class="hrow">
						<div class="rail">
							<span class="rdot" style="background:{outcomeColor(s)}"></span>
							{#if !last}<span class="rline"></span>{/if}
						</div>
						<div class="hcontent" class:pad={!last}>
							<div class="hhead">
								<span class="houtcome" style="color:{outcomeColor(s)}">{outcomeLabel[s.outcome]}</span>
								<span class="hdate">{shortDateFromInstant(s.date)}</span>
							</div>
							<div class="hmeta">
								{#if s.timeTakenMin != null}<span class="hm">⏱ {s.timeTakenMin}m</span>{/if}
								{#if s.timeComplexity}<span class="hm">· {s.timeComplexity} / {s.spaceComplexity ?? '—'}</span>{/if}
								{#if s.peeked}<span class="peeked">peeked</span>{/if}
								<span class="spacer"></span>
								<Comfort level={Math.round(s.comfort ?? 0)} size={5} />
							</div>
						</div>
					</div>
				{/each}
			</div>
		</div>
	{/if}
</div>

<footer class="foot">
	<Btn title="Log a session" variant="primary" size="lg" full icon="check" onclick={() => (showLog = true)} />
</footer>

{#if showLog}
	<LogSheet
		problem={summary()}
		onclose={() => (showLog = false)}
		onlogged={() => invalidateAll()}
	/>
{/if}

<style>
	.head {
		background: #fff;
		border-bottom: 1px solid var(--line2);
	}
	.topbar {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 10px 12px 0;
	}
	.back {
		display: inline-flex;
		align-items: center;
		gap: 4px;
		border: 0;
		background: transparent;
		font-size: 12.5px;
		font-weight: 600;
		color: var(--ink2);
	}
	.gear {
		opacity: 0.4;
		display: inline-flex;
	}
	.titleblock {
		padding: 4px 16px 16px;
	}
	h1 {
		margin: 0;
		font-size: 19px;
		font-weight: 700;
		color: var(--ink);
		line-height: 1.3;
	}
	.badges {
		display: flex;
		align-items: center;
		gap: 7px;
		margin-top: 10px;
		flex-wrap: wrap;
	}
	.openbtn {
		margin-top: 12px;
		display: flex;
	}

	.body {
		display: flex;
		flex-direction: column;
		gap: 16px;
		padding: 16px;
	}

	.statblock {
		display: flex;
		gap: 10px;
	}
	.comfortcard {
		flex: 1;
		display: flex;
		flex-direction: column;
		gap: 9px;
		padding: 12px 13px;
		border: 1px solid var(--line);
		border-radius: 12px;
	}
	.comfortrow {
		display: flex;
		align-items: center;
		gap: 8px;
	}
	.big {
		font-size: 20px;
		font-weight: 700;
		color: var(--ink);
	}
	.slash {
		font-family: var(--mono);
		font-size: 11px;
		color: var(--ink3);
	}
	.spacer {
		flex: 1;
	}
	.trend {
		display: inline-flex;
		align-items: flex-end;
		gap: 5px;
	}
	.tcol {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 3px;
	}
	.tdot {
		width: 8px;
		height: 8px;
		border-radius: 999px;
		background: var(--fill);
		border: 1px solid var(--line);
	}
	.tdot.last {
		background: var(--accent);
		border-color: var(--accent);
	}
	.tval {
		font-family: var(--mono);
		font-size: 8px;
		color: var(--ink3);
	}

	.nextcard {
		width: 132px;
		display: flex;
		flex-direction: column;
		gap: 9px;
		padding: 12px 13px;
		border: 1px solid var(--line);
		border-radius: 12px;
		background: #fff;
	}
	.nextcard.accent {
		background: var(--accent-bg);
		border-color: var(--accent-line);
	}
	.nextrow {
		display: flex;
		align-items: center;
		gap: 7px;
	}
	.nexttext {
		font-size: 13px;
		font-weight: 650;
		color: var(--ink);
	}
	.nexttext.accent {
		color: var(--accent-text);
	}

	.empty {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 12px;
		text-align: center;
		padding: 36px 28px;
		border-radius: 13px;
		background: var(--fill2);
		border: 1px dashed var(--line);
	}
	.emptyicon {
		width: 50px;
		height: 50px;
		border-radius: 14px;
		background: #fff;
		border: 1px solid var(--line2);
		display: flex;
		align-items: center;
		justify-content: center;
	}
	.etitle {
		font-size: 14px;
		font-weight: 650;
		color: var(--ink);
	}
	.empty p {
		margin: 0;
		max-width: 220px;
		font-size: 12px;
		color: var(--ink2);
		line-height: 1.5;
	}

	.history {
		display: flex;
		flex-direction: column;
		gap: 12px;
	}
	.timeline {
		display: flex;
		flex-direction: column;
	}
	.hrow {
		display: flex;
		gap: 11px;
	}
	.rail {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 3px;
	}
	.rdot {
		width: 9px;
		height: 9px;
		border-radius: 999px;
		margin-top: 3px;
	}
	.rline {
		width: 1.5px;
		flex: 1;
		background: var(--line2);
	}
	.hcontent {
		flex: 1;
		display: flex;
		flex-direction: column;
		gap: 5px;
	}
	.hcontent.pad {
		padding-bottom: 16px;
	}
	.hhead {
		display: flex;
		align-items: center;
		justify-content: space-between;
	}
	.houtcome {
		font-size: 12.5px;
		font-weight: 600;
	}
	.hdate {
		font-family: var(--mono);
		font-size: 11px;
		color: var(--ink3);
	}
	.hmeta {
		display: flex;
		align-items: center;
		gap: 8px;
	}
	.hm {
		font-family: var(--mono);
		font-size: 11px;
		color: var(--ink2);
	}
	.peeked {
		font-family: var(--mono);
		font-size: 10.5px;
		font-weight: 500;
		letter-spacing: 0.21px;
		color: var(--accent-text);
		background: var(--accent-bg);
		border: 1px solid var(--accent-line);
		padding: 3px 7px;
		border-radius: 999px;
	}

	.foot {
		padding: 12px 16px calc(12px + env(safe-area-inset-bottom));
		background: #fff;
		border-top: 1px solid var(--line2);
	}
</style>
