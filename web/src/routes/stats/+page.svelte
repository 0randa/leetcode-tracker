<script lang="ts">
	import Icon from '$lib/components/Icon.svelte';
	import { lastNWeekdayInitials } from '$lib/format';
	import type { TopicComfort } from '$lib/types';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();
	const a = $derived(data.analytics);

	const hasData = $derived(a.totalSolved > 0 || a.topics.length > 0 || a.weekly.some((v) => v > 0));
	const maxV = $derived(Math.max(...a.weekly, 1));
	const labels = $derived(lastNWeekdayInitials(a.weekly.length));

	// With few topics, one ranked list says it all; only split into strong/weak
	// once the two slices wouldn't overlap (mirror iOS threshold of >4).
	const split = $derived(a.topics.length > 4);
	const strongest = $derived(a.topics.slice(0, 4));
	const needsWork = $derived(a.topics.slice(-4).reverse());
</script>

<header class="head">
	<h1>Your stats</h1>
	<span class="gear"><Icon name="gear" size={18} color="var(--ink3)" /></span>
</header>

{#if hasData}
	<div class="scroll-y body">
		<div class="summary">
			<div class="scard">
				<Icon name="flame" size={16} color="var(--ink2)" />
				<span class="sval">{a.streak}</span><span class="sunit">day streak</span>
			</div>
			<div class="scard">
				<Icon name="check" size={16} color="var(--ink2)" />
				<span class="sval">{a.totalSolved}</span><span class="sunit">solved</span>
			</div>
		</div>

		<section class="chart">
			<div class="charthead">
				<span class="eyebrow">Problems solved</span>
				<span class="range">Last 7 days</span>
			</div>
			<div class="bars">
				{#each a.weekly as v, i (i)}
					<div class="barcol">
						<div class="barwrap">
							<div
								class="bar"
								class:pos={v > 0}
								style="height:{Math.max((v / maxV) * 86, v > 0 ? 8 : 3)}px"
							></div>
						</div>
						<span class="blabel">{labels[i] ?? ''}</span>
					</div>
				{/each}
			</div>
		</section>

		{#if a.topics.length}
			{#if split}
				{@render topicSection('Strongest topics', strongest)}
				{@render topicSection('Needs work', needsWork)}
			{:else}
				{@render topicSection('Topics by comfort', a.topics)}
			{/if}
		{/if}
	</div>
{:else}
	<div class="emptywrap">
		<div class="emptyicon"><Icon name="chart" size={26} color="var(--ink3)" /></div>
		<div class="etitle">No stats yet</div>
		<p>
			Solve a few problems and your strong and weak topics — and your trend over time — will show up
			here.
		</p>
	</div>
{/if}

{#snippet topicSection(title: string, topics: TopicComfort[])}
	<section class="topics">
		<span class="eyebrow">{title}</span>
		<div class="bars-v">
			{#each topics as t (t.topic)}
				<div class="trow">
					<span class="tname">{t.topic}</span>
					<div class="track"><div class="fill" style="width:{Math.min(t.score / 5, 1) * 100}%"></div></div>
					<span class="tscore">{t.score.toFixed(1)}</span>
				</div>
			{/each}
		</div>
	</section>
{/snippet}

<style>
	.head {
		display: flex;
		align-items: baseline;
		justify-content: space-between;
		padding: 16px 16px 6px;
	}
	h1 {
		margin: 0;
		font-size: 19px;
		font-weight: 700;
		color: var(--ink);
	}
	.gear {
		opacity: 0.4;
		display: inline-flex;
	}

	.body {
		display: flex;
		flex-direction: column;
		gap: 20px;
		padding: 8px 16px 16px;
	}

	.summary {
		display: flex;
		gap: 10px;
	}
	.scard {
		flex: 1;
		display: flex;
		align-items: baseline;
		gap: 9px;
		padding: 12px 13px;
		border: 1px solid var(--line);
		border-radius: 12px;
		background: #fff;
	}
	.scard :global(svg) {
		align-self: center;
	}
	.sval {
		font-size: 20px;
		font-weight: 700;
		color: var(--ink);
	}
	.sunit {
		font-size: 11.5px;
		font-weight: 500;
		color: var(--ink3);
	}

	.chart {
		display: flex;
		flex-direction: column;
	}
	.charthead {
		display: flex;
		justify-content: space-between;
		align-items: baseline;
		margin-bottom: 12px;
	}
	.range {
		font-family: var(--mono);
		font-size: 10.5px;
		font-weight: 500;
		color: var(--ink3);
	}
	.bars {
		display: flex;
		align-items: flex-end;
		gap: 6px;
		height: 110px;
		border-bottom: 1px solid var(--line);
		padding-bottom: 0;
	}
	.barcol {
		flex: 1;
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 6px;
		height: 100%;
		justify-content: flex-end;
	}
	.barwrap {
		flex: 1;
		width: 100%;
		display: flex;
		align-items: flex-end;
	}
	.bar {
		width: 100%;
		border-radius: 4px;
		background: var(--fill);
		border: 1px solid var(--line);
	}
	.bar.pos {
		background: var(--accent-bg);
		border-color: var(--accent-line);
	}
	.blabel {
		font-family: var(--mono);
		font-size: 9px;
		font-weight: 500;
		color: var(--ink3);
	}

	.topics {
		display: flex;
		flex-direction: column;
		gap: 11px;
	}
	.bars-v {
		display: flex;
		flex-direction: column;
		gap: 9px;
	}
	.trow {
		display: flex;
		align-items: center;
		gap: 10px;
	}
	.tname {
		width: 118px;
		font-size: 12px;
		font-weight: 500;
		color: var(--ink);
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}
	.track {
		flex: 1;
		height: 7px;
		border-radius: 999px;
		background: var(--fill);
		overflow: hidden;
	}
	.fill {
		height: 100%;
		background: var(--accent);
		border-radius: 999px;
	}
	.tscore {
		width: 26px;
		text-align: right;
		font-family: var(--mono);
		font-size: 11px;
		font-weight: 600;
		color: var(--ink2);
	}

	.emptywrap {
		flex: 1;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		gap: 14px;
		text-align: center;
		padding: 0 28px 40px;
	}
	.emptyicon {
		width: 56px;
		height: 56px;
		border-radius: 16px;
		background: var(--fill2);
		border: 1px solid var(--line2);
		display: flex;
		align-items: center;
		justify-content: center;
	}
	.etitle {
		font-size: 15px;
		font-weight: 650;
		color: var(--ink);
	}
	.emptywrap p {
		margin: 0;
		max-width: 240px;
		font-size: 12.5px;
		color: var(--ink2);
		line-height: 1.5;
	}
</style>
