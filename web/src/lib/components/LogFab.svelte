<script lang="ts">
	import Icon from './Icon.svelte';
	interface Props {
		onclick: () => void;
	}
	let { onclick }: Props = $props();
</script>

<button type="button" class="fab" aria-label="Log a problem" {onclick}>
	<Icon name="plus" size={24} color="#fff" />
</button>

<style>
	.fab {
		position: absolute;
		right: 16px;
		bottom: 16px;
		width: 52px;
		height: 52px;
		border-radius: 16px;
		border: 0;
		background: var(--ink);
		display: flex;
		align-items: center;
		justify-content: center;
		box-shadow: 0 8px 11px rgba(20, 20, 30, 0.4);
		z-index: 15;
	}
</style>
