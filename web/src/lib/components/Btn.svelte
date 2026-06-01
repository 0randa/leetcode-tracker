<script lang="ts">
	import Icon, { type IconName } from './Icon.svelte';

	type Variant = 'primary' | 'outline' | 'ghost' | 'subtle';
	type Size = 'sm' | 'md' | 'lg';

	interface Props {
		title: string;
		variant?: Variant;
		size?: Size;
		full?: boolean;
		icon?: IconName | null;
		disabled?: boolean;
		type?: 'button' | 'submit';
		onclick?: () => void;
	}
	let {
		title,
		variant = 'primary',
		size = 'md',
		full = false,
		icon = null,
		disabled = false,
		type = 'button',
		onclick
	}: Props = $props();

	const fg = $derived(
		variant === 'primary' ? '#fff' : variant === 'ghost' ? 'var(--ink2)' : 'var(--ink)'
	);
	const iconSize = $derived(size === 'sm' ? 14 : 16);
</script>

<button
	{type}
	{disabled}
	class="btn {variant} {size}"
	class:full
	{onclick}
>
	{#if icon}<Icon name={icon} size={iconSize} color={fg} />{/if}
	<span>{title}</span>
</button>

<style>
	.btn {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		gap: 7px;
		border-radius: 9px;
		border: 1px solid transparent;
		font-family: var(--sans);
		font-weight: 600;
		line-height: 1.2;
		transition: filter 0.12s ease, background 0.12s ease;
	}
	.btn:disabled {
		opacity: 0.55;
		cursor: default;
	}
	.btn.full {
		width: 100%;
		flex: 1;
	}

	.sm {
		font-size: 12px;
		padding: 7px 11px;
	}
	.md {
		font-size: 13.5px;
		padding: 10px 14px;
	}
	.lg {
		font-size: 14.5px;
		padding: 13px 16px;
	}

	.primary {
		background: var(--ink);
		border-color: var(--ink);
		color: #fff;
	}
	.outline {
		background: #fff;
		border-color: var(--line);
		color: var(--ink);
	}
	.ghost {
		background: transparent;
		color: var(--ink2);
	}
	.subtle {
		background: var(--fill2);
		border-color: var(--line2);
		color: var(--ink);
	}

	.btn:not(:disabled):hover {
		filter: brightness(0.97);
	}
	.outline:not(:disabled):hover {
		background: var(--fill2);
		filter: none;
	}
</style>
