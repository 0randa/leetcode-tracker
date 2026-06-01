<script lang="ts">
	import { difficultyLabel, difficultyLevel, type Difficulty } from '$lib/types';

	interface Props {
		difficulty: Difficulty;
		small?: boolean;
	}
	let { difficulty, small = false }: Props = $props();
	const lvl = $derived(difficultyLevel[difficulty]);
</script>

<!-- Difficulty as a grayscale ordinal: mono label + N-of-3 filled segments. -->
<span class="diff">
	<span class="bars">
		{#each [1, 2, 3] as i (i)}
			<span class="bar" class:on={i <= lvl}></span>
		{/each}
	</span>
	<span class="label" class:hard={lvl === 3} style={small ? 'font-size:10px' : ''}>
		{difficultyLabel[difficulty]}
	</span>
</span>

<style>
	.diff {
		display: inline-flex;
		align-items: center;
		gap: 6px;
		padding: 3px 7px 3px 6px;
		border-radius: 999px;
		background: var(--fill2);
		border: 1px solid var(--line);
		white-space: nowrap;
	}
	.bars {
		display: inline-flex;
		gap: 2px;
		align-items: center;
	}
	.bar {
		width: 3px;
		height: 9px;
		border-radius: 1px;
		background: var(--fill);
		border: 1px solid var(--line);
	}
	.bar.on {
		background: var(--ink);
		border-color: var(--ink);
	}
	.label {
		font-family: var(--mono);
		font-size: 10.5px;
		font-weight: 600;
		letter-spacing: 0.21px;
		color: var(--ink2);
	}
	.label.hard {
		color: var(--ink);
	}
</style>
