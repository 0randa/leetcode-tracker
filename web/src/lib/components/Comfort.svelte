<script lang="ts">
	interface Props {
		level?: number;
		size?: number;
		gap?: number;
		showLabel?: boolean;
	}
	let { level = 0, size = 7, gap = 3, showLabel = false }: Props = $props();
</script>

<!-- Comfort dots 1..5, accent-filled up to `level`. -->
<span class="comfort" style="gap:6px">
	<span class="dots" style="gap:{gap}px">
		{#each [1, 2, 3, 4, 5] as i (i)}
			<span class="dot" class:on={i <= level} style="width:{size}px;height:{size}px"></span>
		{/each}
	</span>
	{#if showLabel}<span class="lbl">{level}/5</span>{/if}
</span>

<style>
	.comfort {
		display: inline-flex;
		align-items: center;
	}
	.dots {
		display: inline-flex;
		align-items: center;
	}
	.dot {
		border-radius: 999px;
		background: var(--fill);
		border: 1px solid var(--line);
		flex: none;
	}
	.dot.on {
		background: var(--accent);
		border-color: var(--accent);
	}
	.lbl {
		font-family: var(--mono);
		font-size: 10px;
		color: var(--ink3);
	}
</style>
