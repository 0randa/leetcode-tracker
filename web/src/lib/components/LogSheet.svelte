<script lang="ts">
	import Sheet from './Sheet.svelte';
	import Icon from './Icon.svelte';
	import Radio from './Radio.svelte';
	import Toggle from './Toggle.svelte';
	import Btn from './Btn.svelte';
	import ComplexityAccordion from './ComplexityAccordion.svelte';
	import SchedulePreview from './SchedulePreview.svelte';
	import { clientApi } from '$lib/client-api';
	import {
		outcomeLabel,
		type ProblemSummary,
		type ScheduleResult,
		type SessionOutcome,
		type LogSessionRequest
	} from '$lib/types';

	interface Props {
		problem: ProblemSummary;
		onclose: () => void;
		onlogged: () => void | Promise<void>;
	}
	let { problem, onclose, onlogged }: Props = $props();

	const OUTCOMES: SessionOutcome[] = ['SOLVED_CLEAN', 'SOLVED_HINTS', 'DIDNT_SOLVE'];

	let outcome = $state<SessionOutcome>('SOLVED_CLEAN');
	let peeked = $state(false);
	let timeText = $state('');
	let tc = $state<string | null>(null);
	let sc = $state<string | null>(null);
	let openAcc = $state<'tc' | 'sc' | null>(null);

	let preview = $state<ScheduleResult | null>(null);
	let saving = $state(false);

	function buildRequest(): LogSessionRequest {
		const t = parseInt(timeText.trim(), 10);
		return {
			outcome,
			peeked,
			timeTakenMin: Number.isFinite(t) ? t : null,
			timeComplexity: tc,
			spaceComplexity: sc
		};
	}

	// Live schedule preview — refresh whenever the inputs that affect scheduling
	// change (outcome / peeked). Mirrors the iOS .task(id:) trigger.
	$effect(() => {
		const _ = `${outcome}|${peeked}`;
		let cancelled = false;
		clientApi
			.previewSession(problem.id, buildRequest())
			.then((r) => {
				if (!cancelled) preview = r;
			})
			.catch(() => {
				if (!cancelled) preview = null;
			});
		return () => {
			cancelled = true;
		};
	});

	async function save() {
		if (saving) return;
		saving = true;
		try {
			await clientApi.logSession(problem.id, buildRequest());
			await onlogged();
			onclose();
		} catch {
			saving = false;
		}
	}
</script>

<Sheet {onclose}>
	<header class="head">
		<div>
			<div class="eyebrow">Log session</div>
			<h2>{problem.title}</h2>
		</div>
		<button type="button" class="x" aria-label="Close" onclick={onclose}>
			<Icon name="close" size={15} color="var(--ink2)" />
		</button>
	</header>

	<div class="body scroll-y">
		<div class="field">
			<span class="flabel">Outcome</span>
			<div class="outcomes">
				{#each OUTCOMES as o (o)}
					<button type="button" class="outcome" class:on={outcome === o} onclick={() => (outcome = o)}>
						<Radio on={outcome === o} />
						<span>{outcomeLabel[o]}</span>
					</button>
				{/each}
			</div>
		</div>

		<div class="peeked">
			<div>
				<div class="ptitle">Peeked at the solution?</div>
				<div class="psub">shortens the review interval</div>
			</div>
			<Toggle bind:on={peeked} />
		</div>

		<div class="field">
			<span class="flabel">Time taken</span>
			<div class="timefield">
				<Icon name="clock" size={16} color="var(--ink3)" />
				<input bind:value={timeText} inputmode="numeric" placeholder="e.g. 28" />
			</div>
		</div>

		<div class="accordions">
			<ComplexityAccordion
				label="Time complexity"
				value={tc}
				open={openAcc === 'tc'}
				ontoggle={() => (openAcc = openAcc === 'tc' ? null : 'tc')}
				onpick={(v) => {
					tc = v;
					openAcc = null;
				}}
			/>
			<ComplexityAccordion
				label="Space complexity"
				hint="usually O(1) or O(n)"
				value={sc}
				open={openAcc === 'sc'}
				ontoggle={() => (openAcc = openAcc === 'sc' ? null : 'sc')}
				onpick={(v) => {
					sc = v;
					openAcc = null;
				}}
			/>
		</div>

		<SchedulePreview {preview} {outcome} {peeked} />
	</div>

	<footer class="foot">
		<Btn title="Cancel" variant="outline" size="lg" onclick={onclose} />
		<Btn
			title={saving ? 'Saving…' : 'Save & return'}
			variant="primary"
			size="lg"
			full
			icon="check"
			disabled={saving}
			onclick={save}
		/>
	</footer>
</Sheet>

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
		gap: 16px;
		padding: 14px 16px 8px;
	}

	.field {
		display: flex;
		flex-direction: column;
		gap: 6px;
	}
	.flabel {
		font-size: 11.5px;
		font-weight: 600;
		color: var(--ink);
	}
	.outcomes {
		display: flex;
		flex-direction: column;
		gap: 8px;
	}
	.outcome {
		display: flex;
		align-items: center;
		gap: 10px;
		padding: 11px 12px;
		border: 1px solid var(--line);
		border-radius: 10px;
		background: #fff;
		text-align: left;
		font-size: 13.5px;
		font-weight: 500;
		color: var(--ink);
	}
	.outcome.on {
		border-color: var(--ink);
		background: var(--fill2);
	}

	.peeked {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 11px 13px;
		border: 1px solid var(--line);
		border-radius: 10px;
	}
	.ptitle {
		font-size: 13px;
		font-weight: 600;
		color: var(--ink);
	}
	.psub {
		font-family: var(--mono);
		font-size: 11px;
		color: var(--ink3);
	}

	.timefield {
		display: flex;
		align-items: center;
		gap: 8px;
		height: 38px;
		padding: 0 11px;
		border: 1px solid var(--line);
		border-radius: 9px;
		background: #fff;
	}
	.timefield input {
		flex: 1;
		min-width: 0;
		border: 0;
		outline: none;
		background: transparent;
		font-family: var(--sans);
		font-size: 13px;
		color: var(--ink);
	}
	.timefield input::placeholder {
		color: var(--ink3);
	}

	.accordions {
		display: flex;
		flex-direction: column;
		gap: 8px;
	}

	.foot {
		display: flex;
		gap: 9px;
		padding: 12px 16px;
		border-top: 1px solid var(--line2);
	}
</style>
