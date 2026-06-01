<script lang="ts">
	import Icon, { type IconName } from './Icon.svelte';

	interface Props {
		placeholder?: string;
		value: string;
		icon?: IconName | null;
		type?: string;
		inputmode?: 'text' | 'numeric';
		oninput?: (v: string) => void;
	}
	let {
		placeholder = '',
		value = $bindable(),
		icon = null,
		type = 'text',
		inputmode = 'text',
		oninput
	}: Props = $props();
</script>

<div class="field">
	{#if icon}<Icon name={icon} size={16} color="var(--ink3)" />{/if}
	<input
		{type}
		{inputmode}
		{placeholder}
		bind:value
		autocomplete="off"
		autocapitalize="off"
		spellcheck="false"
		oninput={() => oninput?.(value)}
	/>
</div>

<style>
	.field {
		display: flex;
		align-items: center;
		gap: 8px;
		height: 38px;
		padding: 0 11px;
		background: #fff;
		border: 1px solid var(--line);
		border-radius: 9px;
	}
	.field:focus-within {
		border-color: var(--ink3);
	}
	input {
		flex: 1;
		min-width: 0;
		border: 0;
		outline: none;
		background: transparent;
		font-family: var(--sans);
		font-size: 13px;
		color: var(--ink);
	}
	input::placeholder {
		color: var(--ink3);
	}
</style>
