<script lang="ts">
	import Icon, { type IconName } from './Icon.svelte';
	import DiffBadge from './DiffBadge.svelte';
	import Badge from './Badge.svelte';
	import { primaryTopic, type ProblemSummary } from '$lib/types';

	interface Props {
		problem: ProblemSummary;
		trailing?: IconName | null;
		onpick: () => void;
	}
	let { problem, trailing = null, onpick }: Props = $props();
</script>

<!-- A search / quick-pick result row: title, difficulty + topic, optional trailing
     badge, and a chevron. Tapping selects it for confirmation. -->
<button type="button" class="row" onclick={onpick}>
	<div class="left">
		<div class="title">{problem.title}</div>
		<div class="sub">
			<DiffBadge difficulty={problem.difficulty} />
			<span class="topic">{primaryTopic(problem)}</span>
		</div>
	</div>
	{#if trailing}<Badge text="link" leadingIcon={trailing} fg="var(--ink2)" bg="var(--fill2)" bd="var(--line)" />{/if}
	<Icon name="chevR" size={16} color="var(--ink3)" />
</button>

<style>
	.row {
		width: 100%;
		display: flex;
		align-items: center;
		gap: 11px;
		padding: 11px 12px;
		border: 1px solid var(--line2);
		border-radius: 10px;
		background: #fff;
		text-align: left;
	}
	.row:hover {
		border-color: var(--line);
	}
	.left {
		flex: 1;
		min-width: 0;
		display: flex;
		flex-direction: column;
		gap: 5px;
	}
	.title {
		font-size: 13px;
		font-weight: 600;
		color: var(--ink);
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}
	.sub {
		display: flex;
		align-items: center;
		gap: 7px;
	}
	.topic {
		font-family: var(--mono);
		font-size: 11px;
		color: var(--ink3);
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}
</style>
