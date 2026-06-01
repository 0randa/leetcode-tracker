<script lang="ts" module>
	// Exact Big-O option set (must-have 5 + exponential + multi-variable + escape).
	export const BIGO = [
		'O(1)',
		'O(log n)',
		'O(n)',
		'O(n log n)',
		'O(n²)',
		'O(2ⁿ)',
		'O(m·n)',
		'O(V+E)',
		'O(m+n)',
		'Other'
	];
	const BIGO_LABEL: Record<string, string> = {
		'O(1)': 'constant',
		'O(log n)': 'logarithmic',
		'O(n)': 'linear',
		'O(n log n)': 'linearithmic',
		'O(n²)': 'quadratic',
		'O(2ⁿ)': 'exponential',
		'O(m·n)': 'grid / 2-D',
		'O(V+E)': 'graph',
		'O(m+n)': 'two inputs',
		Other: 'free text'
	};
	export { BIGO_LABEL };
</script>

<script lang="ts">
	import Icon from './Icon.svelte';

	interface Props {
		label: string;
		hint?: string | null;
		value: string | null;
		open: boolean;
		ontoggle: () => void;
		onpick: (v: string) => void;
	}
	let { label, hint = null, value, open, ontoggle, onpick }: Props = $props();
</script>

<!-- Expandable Big-O picker — collapsed shows the chosen value; expanded reveals
     the full grid with plain-language sublabels. -->
<div class="acc" class:open>
	<button type="button" class="head" onclick={ontoggle}>
		<span class="labels">
			<span class="title">{label}</span>
			{#if hint}<span class="hint">{hint}</span>{/if}
		</span>
		<span class="val" class:placeholder={value == null}>{value ?? 'Select…'}</span>
		<span class="chev" class:flip={open}><Icon name="chevD" size={15} color="var(--ink3)" /></span>
	</button>

	{#if open}
		<div class="grid">
			{#each BIGO as o (o)}
				{@const on = o === value}
				<button type="button" class="cell" class:on onclick={() => onpick(o)}>
					<span class="o">{o}</span>
					{#if o !== 'Other'}<span class="sub" class:on>{BIGO_LABEL[o]}</span>{/if}
				</button>
			{/each}
		</div>
	{/if}
</div>

<style>
	.acc {
		background: #fff;
		border: 1px solid var(--line);
		border-radius: 11px;
		overflow: hidden;
	}
	.acc.open {
		border-color: var(--ink);
	}
	.head {
		width: 100%;
		display: flex;
		align-items: center;
		gap: 10px;
		padding: 11px 13px;
		border: 0;
		background: transparent;
		text-align: left;
	}
	.labels {
		display: flex;
		flex-direction: column;
		gap: 2px;
		flex: 1;
	}
	.title {
		font-size: 12.5px;
		font-weight: 600;
		color: var(--ink);
	}
	.hint {
		font-family: var(--mono);
		font-size: 10.5px;
		color: var(--ink3);
	}
	.val {
		font-family: var(--mono);
		font-size: 13px;
		font-weight: 600;
		color: var(--ink);
	}
	.val.placeholder {
		color: var(--ink3);
	}
	.chev {
		display: inline-flex;
		transition: transform 0.15s ease;
	}
	.chev.flip {
		transform: rotate(180deg);
	}

	.grid {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 6px;
		padding: 10px;
		background: var(--fill2);
		border-top: 1px solid var(--line2);
	}
	.cell {
		display: flex;
		align-items: baseline;
		gap: 6px;
		padding: 8px 10px;
		border: 1px solid var(--line);
		border-radius: 8px;
		background: #fff;
		text-align: left;
	}
	.cell.on {
		background: var(--ink);
		border-color: var(--ink);
	}
	.o {
		font-family: var(--mono);
		font-size: 12.5px;
		font-weight: 600;
		color: var(--ink);
	}
	.cell.on .o {
		color: #fff;
	}
	.sub {
		font-size: 9.5px;
		color: var(--ink3);
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}
	.sub.on {
		color: rgba(255, 255, 255, 0.65);
	}
</style>
