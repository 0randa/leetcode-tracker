<script lang="ts">
	import Badge from './Badge.svelte';
	interface Props {
		topic: string;
	}
	let { topic }: Props = $props();
</script>

<Badge text={topic} fg="var(--ink2)" bg="var(--fill2)" bd="var(--line2)" mono={false} />
