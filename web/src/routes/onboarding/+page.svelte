<script lang="ts">
	import { enhance } from '$app/forms';
	import Segmented from '$lib/components/Segmented.svelte';
	import Btn from '$lib/components/Btn.svelte';
	import { ratingLabel } from '$lib/types';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();

	const options = [ratingLabel.COMFORTABLE, ratingLabel.SHAKY, ratingLabel.NOT_TRIED];

	let ratings = $state<Record<string, string>>({});
	let submitting = $state(false);

	const count = $derived(Object.values(ratings).filter((v) => v).length);
	const total = $derived(data.topics.length);
</script>

<div class="screen">
	<header class="head">
		<div class="brand">
			<span class="logo">&lt;/&gt;</span>
			<span class="bname">Review Tracker</span>
		</div>
		<h1>Where do you stand?</h1>
		<p class="lede">
			We pick your daily problems for you. Rate each topic so the first sets land at the right
			level.
		</p>
	</header>

	<form
		method="POST"
		class="formwrap"
		use:enhance={() => {
			submitting = true;
			return async ({ update }) => {
				await update();
				submitting = false;
			};
		}}
	>
		<div class="scroll-y list">
			{#each data.topics as cat (cat)}
				<div class="rowitem">
					<span class="cat">{cat}</span>
					<Segmented options={options} bind:value={ratings[cat]} small />
					<input type="hidden" name={cat} value={ratings[cat] ?? ''} />
				</div>
			{/each}
		</div>

		<footer class="foot">
			<div class="bar">
				<div
					class="barfill"
					style="width:{total ? (count / total) * 100 : 0}%"
				></div>
			</div>
			<Btn
				title={submitting ? 'Saving…' : 'Continue'}
				variant="primary"
				size="lg"
				full
				icon="check"
				type="submit"
				disabled={submitting}
			/>
			<p class="counter">{count}/{total} rated · you can change these later</p>
		</footer>
	</form>
</div>

<style>
	.screen {
		display: flex;
		flex-direction: column;
		flex: 1;
		min-height: 0;
		background: #fff;
	}
	.head {
		padding: 18px 16px 14px;
	}
	.brand {
		display: flex;
		align-items: center;
		gap: 9px;
		margin-bottom: 14px;
	}
	.logo {
		font-family: var(--mono);
		font-size: 13px;
		font-weight: 700;
		color: #fff;
		background: var(--ink);
		width: 26px;
		height: 26px;
		border-radius: 7px;
		display: flex;
		align-items: center;
		justify-content: center;
	}
	.bname {
		font-size: 14px;
		font-weight: 700;
		color: var(--ink);
	}
	h1 {
		margin: 0;
		font-size: 20px;
		font-weight: 700;
		color: var(--ink);
	}
	.lede {
		margin: 7px 0 0;
		font-size: 13px;
		color: var(--ink2);
		line-height: 1.45;
	}

	.formwrap {
		display: flex;
		flex-direction: column;
		flex: 1;
		min-height: 0;
	}
	.list {
		display: flex;
		flex-direction: column;
		gap: 10px;
		padding: 4px 16px 8px;
	}
	.rowitem {
		display: flex;
		flex-direction: column;
		gap: 7px;
	}
	.cat {
		font-size: 13px;
		font-weight: 600;
		color: var(--ink);
	}

	.foot {
		padding: 12px 16px calc(16px + env(safe-area-inset-bottom));
		border-top: 1px solid var(--line2);
		background: #fff;
	}
	.bar {
		height: 4px;
		border-radius: 999px;
		background: var(--fill);
		overflow: hidden;
		margin-bottom: 10px;
	}
	.barfill {
		height: 100%;
		background: var(--accent);
		border-radius: 999px;
		transition: width 0.2s ease;
	}
	.counter {
		margin: 8px 0 0;
		text-align: center;
		font-family: var(--mono);
		font-size: 10.5px;
		color: var(--ink3);
	}
</style>
