<script lang="ts">
	import type { Snippet } from 'svelte';

	interface Props {
		grabber?: boolean;
		onclose?: () => void;
		children: Snippet;
	}
	let { grabber = false, onclose, children }: Props = $props();

	function onKey(e: KeyboardEvent) {
		if (e.key === 'Escape') onclose?.();
	}
</script>

<svelte:window onkeydown={onKey} />

<div class="backdrop" role="presentation" onclick={() => onclose?.()}>
	<div
		class="sheet"
		role="dialog"
		aria-modal="true"
		tabindex="-1"
		onclick={(e) => e.stopPropagation()}
		onkeydown={() => {}}
	>
		{#if grabber}<div class="grabber"></div>{/if}
		{@render children()}
	</div>
</div>

<style>
	.backdrop {
		position: fixed;
		inset: 0;
		background: rgba(20, 22, 28, 0.34);
		display: flex;
		flex-direction: column;
		justify-content: flex-end;
		z-index: 60;
		animation: fade 0.15s ease;
	}
	.sheet {
		width: 100%;
		max-width: var(--app-max);
		margin: 0 auto;
		background: #fff;
		border-radius: 18px 18px 0 0;
		max-height: 92dvh;
		display: flex;
		flex-direction: column;
		overflow: hidden;
		animation: rise 0.22s cubic-bezier(0.2, 0.7, 0.2, 1);
		padding-bottom: env(safe-area-inset-bottom);
	}
	.grabber {
		width: 36px;
		height: 4px;
		border-radius: 999px;
		background: var(--line);
		margin: 9px auto 0;
		flex: none;
	}
	@keyframes fade {
		from {
			opacity: 0;
		}
	}
	@keyframes rise {
		from {
			transform: translateY(14px);
			opacity: 0.6;
		}
	}
</style>
