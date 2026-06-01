<script lang="ts">
	import Sheet from './Sheet.svelte';
	import Icon from './Icon.svelte';
	import Input from './Input.svelte';
	import Btn from './Btn.svelte';
	import Badge from './Badge.svelte';
	import DiffBadge from './DiffBadge.svelte';
	import TopicTag from './TopicTag.svelte';
	import StatusBadge from './StatusBadge.svelte';
	import ResultRow from './ResultRow.svelte';
	import LogSheet from './LogSheet.svelte';
	import { clientApi } from '$lib/client-api';
	import { primaryTopic, type ProblemSummary } from '$lib/types';

	interface Props {
		onclose: () => void;
		onlogged: (title: string) => void | Promise<void>;
	}
	let { onclose, onlogged }: Props = $props();

	let query = $state('');
	let matches = $state<ProblemSummary[]>([]);
	let note = $state<string | null>(null);
	let searching = $state(false);
	let quickPicks = $state<ProblemSummary[]>([]);

	let chosen = $state<ProblemSummary | null>(null);
	let fromUrl = $state(false);
	let logTarget = $state<ProblemSummary | null>(null);

	const typed = $derived(query.trim().length > 0);
	const looksLikeUrl = $derived(/leetcode\.com\/problems\//.test(query));
	const notFound = $derived(typed && !searching && matches.length === 0);

	// Debounced live search (mirrors iOS .task(id: query) + 280ms sleep).
	$effect(() => {
		const q = query.trim();
		if (!q) {
			matches = [];
			note = null;
			return;
		}
		let cancelled = false;
		searching = true;
		const t = setTimeout(async () => {
			try {
				const r = await clientApi.resolve(q);
				if (cancelled) return;
				matches = r.matches;
				note = r.note;
			} catch {
				if (!cancelled) {
					matches = [];
					note = null;
				}
			} finally {
				if (!cancelled) searching = false;
			}
		}, 280);
		return () => {
			cancelled = true;
			clearTimeout(t);
		};
	});

	$effect(() => {
		loadQuickPicks();
	});

	async function loadQuickPicks() {
		if (quickPicks.length) return;
		const titles = ['Two Sum', 'Valid Parentheses', 'Merge Intervals'];
		const picks: ProblemSummary[] = [];
		for (const t of titles) {
			try {
				const m = (await clientApi.resolve(t)).matches[0];
				if (m) picks.push(m);
			} catch {
				/* ignore */
			}
		}
		quickPicks = picks;
	}

	function choose(p: ProblemSummary, url: boolean) {
		fromUrl = url;
		chosen = p;
	}

	function statusNote(p: ProblemSummary): string {
		switch (p.status) {
			case 'REVIEW':
				return 'In review — logging now reschedules it from today.';
			case 'MASTERED':
				return 'Already mastered — a struggling outcome can pull it back into rotation.';
			default:
				return 'Not tracked yet — logging starts its review schedule.';
		}
	}
</script>

<Sheet grabber {onclose}>
	<header class="head">
		<div>
			<div class="eyebrow">{chosen ? 'Confirm problem' : 'Log a problem'}</div>
			<h2>{chosen ? 'Is this the one?' : 'Find a problem'}</h2>
		</div>
		<button type="button" class="x" aria-label="Close" onclick={onclose}>
			<Icon name="close" size={15} color="var(--ink2)" />
		</button>
	</header>

	<div class="body scroll-y">
		{#if chosen}
			<div class="confirm">
				<div class="ccard">
					{#if fromUrl}
						<Badge text="Resolved from link" leadingIcon="link" mono={false} fg="var(--ink2)" bg="var(--fill2)" bd="var(--line)" />
					{/if}
					<h3>{chosen.title}</h3>
					<div class="crow">
						<DiffBadge difficulty={chosen.difficulty} />
						<TopicTag topic={primaryTopic(chosen)} />
						<span class="spacer"></span>
						<StatusBadge status={chosen.status} />
					</div>
					<div class="cnote">
						<Icon name="clock" size={14} color="var(--ink3)" />
						<span>{statusNote(chosen)}</span>
					</div>
				</div>
				<div class="cactions">
					<Btn title="Not this one" variant="outline" size="lg" onclick={() => (chosen = null)} />
					<Btn title="Log this" variant="primary" size="lg" full icon="check" onclick={() => (logTarget = chosen)} />
				</div>
			</div>
		{:else}
			<Input
				placeholder="Paste a LeetCode link or search by name"
				bind:value={query}
				icon={looksLikeUrl ? 'link' : 'search'}
			/>

			{#if looksLikeUrl && matches[0]}
				<div class="resolved">
					<span class="eyebrow">Resolved from link</span>
					<ResultRow problem={matches[0]} trailing="link" onpick={() => choose(matches[0], true)} />
				</div>
			{:else if matches.length}
				<div class="results">
					{#each matches as m (m.id)}
						<ResultRow problem={m} onpick={() => choose(m, false)} />
					{/each}
				</div>
			{/if}

			{#if notFound}
				<div class="notfound">
					<div class="nftitle">Couldn’t find that one</div>
					<p>{note ?? 'Check the link or spelling. Brand-new problems sync in later — try again then.'}</p>
					<Btn title="Try again" variant="outline" size="sm" icon="back" onclick={() => (query = '')} />
				</div>
			{:else if !typed}
				<div class="hint">
					<div class="hintbox">
						<Icon name="search" size={14} color="var(--ink3)" />
						<span>Paste a LeetCode link or search by name — log anything you solved, even if it wasn’t in today’s set.</span>
					</div>
					{#if quickPicks.length}
						<div class="picks">
							<span class="eyebrow">Quick picks</span>
							{#each quickPicks as p (p.id)}
								<ResultRow problem={p} onpick={() => choose(p, false)} />
							{/each}
						</div>
					{/if}
				</div>
			{/if}
		{/if}
	</div>
</Sheet>

{#if logTarget}
	<LogSheet
		problem={logTarget}
		onclose={() => (logTarget = null)}
		onlogged={async () => {
			await onlogged(logTarget!.title);
			onclose();
		}}
	/>
{/if}

<style>
	.head {
		display: flex;
		align-items: flex-start;
		justify-content: space-between;
		padding: 12px 16px 0;
	}
	.eyebrow {
		font-family: var(--mono);
		font-size: 10.5px;
		font-weight: 600;
		letter-spacing: 0.84px;
		text-transform: uppercase;
		color: var(--ink3);
	}
	h2 {
		margin: 4px 0 0;
		font-size: 17px;
		font-weight: 700;
		color: var(--ink);
	}
	.x {
		width: 28px;
		height: 28px;
		border: 0;
		border-radius: 8px;
		background: var(--fill2);
		display: flex;
		align-items: center;
		justify-content: center;
		flex: none;
	}

	.body {
		display: flex;
		flex-direction: column;
		gap: 14px;
		padding: 14px 16px 18px;
	}

	.results,
	.resolved,
	.picks {
		display: flex;
		flex-direction: column;
		gap: 8px;
	}

	.notfound {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 6px;
		text-align: center;
		padding: 16px 14px;
		border-radius: 11px;
		background: var(--fill2);
		border: 1px dashed var(--line);
	}
	.nftitle {
		font-size: 13px;
		font-weight: 600;
		color: var(--ink);
	}
	.notfound p {
		margin: 0 0 4px;
		font-size: 11.5px;
		color: var(--ink2);
		line-height: 1.5;
	}

	.hint {
		display: flex;
		flex-direction: column;
		gap: 12px;
	}
	.hintbox {
		display: flex;
		align-items: flex-start;
		gap: 8px;
		padding: 10px 12px;
		border-radius: 9px;
		background: var(--fill2);
		border: 1px solid var(--line2);
		font-size: 11.5px;
		color: var(--ink2);
		line-height: 1.5;
	}

	.confirm {
		display: flex;
		flex-direction: column;
		gap: 14px;
	}
	.ccard {
		display: flex;
		flex-direction: column;
		gap: 11px;
		padding: 15px;
		border-radius: 13px;
		background: #fff;
		border: 1px solid var(--line);
	}
	.ccard h3 {
		margin: 0;
		font-size: 16px;
		font-weight: 700;
		color: var(--ink);
	}
	.crow {
		display: flex;
		align-items: center;
		gap: 7px;
	}
	.spacer {
		flex: 1;
	}
	.cnote {
		display: flex;
		align-items: flex-start;
		gap: 8px;
		padding: 9px 11px;
		border-radius: 9px;
		background: var(--fill2);
		border: 1px solid var(--line2);
		font-size: 11.5px;
		color: var(--ink2);
		line-height: 1.5;
	}
	.cactions {
		display: flex;
		gap: 9px;
	}
</style>
