<script lang="ts">
	import { page } from '$app/stores';
	import { invalidateAll } from '$app/navigation';
	import Icon from '$lib/components/Icon.svelte';
	import Btn from '$lib/components/Btn.svelte';

	const waking = $derived($page.status === 504);
	const title = $derived(waking ? 'Waking the server…' : 'Something went wrong');
	const message = $derived(
		$page.error?.message ?? 'The server is taking a moment. Try again shortly.'
	);
</script>

<div class="wrap">
	<div class="icon"><Icon name="inbox" size={26} color="var(--ink3)" /></div>
	<h1>{title}</h1>
	<p>{message}</p>
	{#if waking}
		<p class="hint">Free-tier hosting sleeps when idle — the first request can take up to a minute.</p>
	{/if}
	<Btn title="Try again" variant="outline" size="md" icon="back" onclick={() => invalidateAll()} />
</div>

<style>
	.wrap {
		flex: 1;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		gap: 12px;
		text-align: center;
		padding: 28px;
	}
	h1 {
		margin: 0;
		font-size: 15px;
		font-weight: 650;
		color: var(--ink);
	}
	p {
		margin: 0;
		max-width: 280px;
		font-size: 12px;
		color: var(--ink2);
		line-height: 1.5;
	}
	.hint {
		color: var(--ink3);
	}
	.icon {
		margin-bottom: 4px;
	}
</style>
