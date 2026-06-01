<script lang="ts">
	import Icon, { type IconName } from './Icon.svelte';
	import type { Snippet } from 'svelte';

	interface Props {
		text?: string;
		fg?: string;
		bg?: string;
		bd?: string;
		mono?: boolean;
		leadingIcon?: IconName | null;
		children?: Snippet;
	}
	let {
		text = '',
		fg = 'var(--ink2)',
		bg = 'var(--fill2)',
		bd = 'var(--line)',
		mono = true,
		leadingIcon = null,
		children
	}: Props = $props();
</script>

<span
	class="badge"
	class:mono
	style="color:{fg};background:{bg};border-color:{bd}"
>
	{#if leadingIcon}<Icon name={leadingIcon} size={11} color={fg} />{/if}
	{#if children}{@render children()}{:else}{text}{/if}
</span>

<style>
	.badge {
		display: inline-flex;
		align-items: center;
		gap: 4px;
		padding: 3px 7px;
		border-radius: 999px;
		border: 1px solid;
		font-family: var(--sans);
		font-size: 10.5px;
		font-weight: 500;
		letter-spacing: 0.21px;
		line-height: 1.2;
		white-space: nowrap;
	}
	.badge.mono {
		font-family: var(--mono);
	}
</style>
