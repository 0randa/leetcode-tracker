<script lang="ts">
	import '../app.css';
	import { page } from '$app/stores';
	import { toast } from '$lib/stores/toast';
	import Icon from '$lib/components/Icon.svelte';
	import type { Snippet } from 'svelte';

	let { children }: { children: Snippet } = $props();

	const tabs = [
		{ href: '/', label: 'Today', icon: 'home' as const },
		{ href: '/problems', label: 'Problems', icon: 'list' as const },
		{ href: '/stats', label: 'Stats', icon: 'chart' as const }
	];

	const path = $derived($page.url.pathname);
	const showNav = $derived(!path.startsWith('/onboarding') && !path.startsWith('/signin'));

	function isActive(href: string): boolean {
		if (href === '/') return path === '/';
		return path.startsWith(href);
	}
</script>

<div class="app-frame">
	<div class="content">
		{@render children()}
	</div>

	{#if showNav}
		<nav class="bottom-nav">
			{#each tabs as t (t.href)}
				{@const on = isActive(t.href)}
				<a href={t.href} class="tab" class:on aria-current={on ? 'page' : undefined}>
					<Icon name={t.icon} size={20} color={on ? 'var(--ink)' : 'var(--ink3)'} bold={on} />
					<span>{t.label}</span>
				</a>
			{/each}
		</nav>
	{/if}

	{#if $toast}
		<div class="toast" role="status">
			<Icon name="check" size={14} color="#fff" />
			<span>{$toast}</span>
		</div>
	{/if}
</div>

<style>
	.content {
		flex: 1;
		display: flex;
		flex-direction: column;
		min-height: 0;
	}

	.bottom-nav {
		display: flex;
		background: #fff;
		border-top: 1px solid var(--line2);
		padding: 8px 0 calc(12px + env(safe-area-inset-bottom));
		position: sticky;
		bottom: 0;
		z-index: 20;
	}
	.tab {
		flex: 1;
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 3px;
		font-family: var(--sans);
		font-size: 10px;
		font-weight: 500;
		color: var(--ink3);
	}
	.tab.on {
		color: var(--ink);
		font-weight: 600;
	}

	.toast {
		position: fixed;
		left: 50%;
		bottom: calc(76px + env(safe-area-inset-bottom));
		transform: translateX(-50%);
		display: flex;
		align-items: center;
		gap: 8px;
		background: var(--ink);
		color: #fff;
		font-size: 12.5px;
		font-weight: 600;
		padding: 11px 14px;
		border-radius: 999px;
		box-shadow: 0 5px 10px rgba(20, 20, 30, 0.3);
		z-index: 50;
		white-space: nowrap;
		animation: toast-in 0.2s ease;
	}
	@keyframes toast-in {
		from {
			opacity: 0;
			transform: translate(-50%, 8px);
		}
	}
</style>
