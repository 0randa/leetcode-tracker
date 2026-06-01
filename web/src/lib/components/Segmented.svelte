<script lang="ts">
	interface Props {
		options: string[];
		value: string;
		small?: boolean;
		onchange?: (v: string) => void;
	}
	let { options, value = $bindable(), small = false, onchange }: Props = $props();

	function pick(o: string) {
		value = o;
		onchange?.(o);
	}
</script>

<!-- N-way segmented control (Onboarding rows, Log outcome). -->
<div class="seg" class:small>
	{#each options as o (o)}
		<button type="button" class="opt" class:on={o === value} onclick={() => pick(o)}>
			{o}
		</button>
	{/each}
</div>

<style>
	.seg {
		display: flex;
		gap: 2px;
		padding: 2px;
		border-radius: 9px;
		background: var(--fill2);
		border: 1px solid var(--line2);
	}
	.opt {
		flex: 1;
		border: 0;
		background: transparent;
		border-radius: 7px;
		padding: 7px 8px;
		font-family: var(--sans);
		font-size: 12.5px;
		font-weight: 500;
		color: var(--ink2);
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}
	.small .opt {
		font-size: 11px;
		padding: 5px 6px;
	}
	.opt.on {
		background: #fff;
		color: var(--ink);
		font-weight: 600;
		box-shadow: 0 1px 1px rgba(0, 0, 0, 0.06);
	}
</style>
