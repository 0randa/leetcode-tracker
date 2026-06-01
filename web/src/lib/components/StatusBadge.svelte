<script lang="ts">
	import Badge from './Badge.svelte';
	import { statusLabel, type ProgressStatus } from '$lib/types';

	interface Props {
		status: ProgressStatus;
	}
	let { status }: Props = $props();
</script>

{#if status === 'TODO'}
	<Badge text={statusLabel.TODO} fg="var(--ink2)" bg="var(--fill2)" bd="var(--line)" />
{:else if status === 'REVIEW'}
	<Badge text={statusLabel.REVIEW} fg="var(--accent-text)" bg="var(--accent-bg)" bd="var(--accent-line)" />
{:else}
	<Badge text={statusLabel.MASTERED} fg="#fff" bg="var(--ink)" bd="var(--ink)" />
{/if}
