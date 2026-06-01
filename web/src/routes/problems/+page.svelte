<script lang="ts">
	import { untrack } from 'svelte';
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import Icon from '$lib/components/Icon.svelte';
	import DiffBadge from '$lib/components/DiffBadge.svelte';
	import StatusBadge from '$lib/components/StatusBadge.svelte';
	import Comfort from '$lib/components/Comfort.svelte';
	import {
		ALL_DIFFICULTIES,
		ALL_STATUSES,
		difficultyLabel,
		statusLabel,
		primaryTopic
	} from '$lib/types';
	import type { PageData } from './$types';

	let { data }: { data: PageData } = $props();

	let search = $state(untrack(() => data.filters.search ?? ''));
	let debounce: ReturnType<typeof setTimeout> | undefined;

	function applyParam(key: string, value: string | undefined) {
		const params = new URLSearchParams($page.url.searchParams);
		if (value) params.set(key, value);
		else params.delete(key);
		goto(`/problems?${params.toString()}`, { keepFocus: true, noScroll: true, replaceState: true });
	}

	function onSearch() {
		clearTimeout(debounce);
		debounce = setTimeout(() => applyParam('search', search.trim() || undefined), 250);
	}
</script>

<div class="head">
	<div class="titlerow">
		<h1>All problems</h1>
		<span class="count">{data.items.length} total</span>
		<span class="gear"><Icon name="gear" size={18} color="var(--ink3)" /></span>
	</div>

	<div class="searchfield">
		<Icon name="search" size={16} color="var(--ink3)" />
		<input
			placeholder="Search problems…"
			bind:value={search}
			oninput={onSearch}
			autocomplete="off"
			spellcheck="false"
		/>
	</div>

	<div class="filters">
		<div class="select" class:active={!!data.filters.topic}>
			<select
				value={data.filters.topic ?? ''}
				onchange={(e) => applyParam('topic', e.currentTarget.value || undefined)}
			>
				<option value="">Topic</option>
				{#each data.topics as t (t)}<option value={t}>{t}</option>{/each}
			</select>
			<Icon name="chevD" size={13} color="var(--ink3)" />
		</div>

		<div class="select" class:active={!!data.filters.difficulty}>
			<select
				value={data.filters.difficulty ?? ''}
				onchange={(e) => applyParam('difficulty', e.currentTarget.value || undefined)}
			>
				<option value="">Difficulty</option>
				{#each ALL_DIFFICULTIES as d (d)}<option value={d}>{difficultyLabel[d]}</option>{/each}
			</select>
			<Icon name="chevD" size={13} color="var(--ink3)" />
		</div>

		<div class="select" class:active={!!data.filters.status}>
			<select
				value={data.filters.status ?? ''}
				onchange={(e) => applyParam('status', e.currentTarget.value || undefined)}
			>
				<option value="">Status</option>
				{#each ALL_STATUSES as s (s)}<option value={s}>{statusLabel[s]}</option>{/each}
			</select>
			<Icon name="chevD" size={13} color="var(--ink3)" />
		</div>
	</div>
</div>

<div class="scroll-y list">
	{#each data.items as p (p.id)}
		<a class="row" href="/problems/{p.id}">
			<div class="left">
				<div class="title">{p.title}</div>
				<div class="sub">
					<DiffBadge difficulty={p.difficulty} />
					<span class="topic">{primaryTopic(p)}</span>
				</div>
			</div>
			<div class="right">
				<StatusBadge status={p.status} />
				<Comfort level={p.comfort} size={6} showLabel />
			</div>
		</a>
	{:else}
		<div class="empty">No problems match those filters.</div>
	{/each}
</div>

<style>
	.head {
		padding: 14px 16px 12px;
		background: #fff;
		border-bottom: 1px solid var(--line2);
		display: flex;
		flex-direction: column;
		gap: 9px;
	}
	.titlerow {
		display: flex;
		align-items: baseline;
		gap: 10px;
	}
	h1 {
		margin: 0;
		font-size: 19px;
		font-weight: 700;
		color: var(--ink);
		flex: 1;
	}
	.count {
		font-family: var(--mono);
		font-size: 11.5px;
		font-weight: 500;
		color: var(--ink3);
	}
	.gear {
		opacity: 0.4;
		display: inline-flex;
	}

	.searchfield {
		display: flex;
		align-items: center;
		gap: 8px;
		height: 38px;
		padding: 0 11px;
		border: 1px solid var(--line);
		border-radius: 9px;
		background: #fff;
	}
	.searchfield:focus-within {
		border-color: var(--ink3);
	}
	.searchfield input {
		flex: 1;
		min-width: 0;
		border: 0;
		outline: none;
		background: transparent;
		font-family: var(--sans);
		font-size: 13px;
		color: var(--ink);
	}
	.searchfield input::placeholder {
		color: var(--ink3);
	}

	.filters {
		display: flex;
		gap: 7px;
	}
	.select {
		position: relative;
		flex: 1;
		height: 31px;
		border: 1px solid var(--line);
		border-radius: 8px;
		background: #fff;
		display: flex;
		align-items: center;
	}
	.select.active {
		border-color: var(--ink);
	}
	.select select {
		appearance: none;
		-webkit-appearance: none;
		border: 0;
		outline: none;
		background: transparent;
		width: 100%;
		height: 100%;
		padding: 0 24px 0 10px;
		font-family: var(--sans);
		font-size: 11.5px;
		font-weight: 500;
		color: var(--ink2);
		cursor: pointer;
	}
	.select.active select {
		color: var(--ink);
		font-weight: 600;
	}
	.select :global(svg) {
		position: absolute;
		right: 7px;
		pointer-events: none;
	}

	.list {
		display: flex;
		flex-direction: column;
	}
	.row {
		display: flex;
		align-items: center;
		gap: 11px;
		padding: 12px 16px;
		background: #fff;
		border-bottom: 1px solid var(--line2);
	}
	.row:hover {
		background: var(--fill2);
	}
	.left {
		flex: 1;
		min-width: 0;
		display: flex;
		flex-direction: column;
		gap: 6px;
	}
	.title {
		font-size: 13.5px;
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
	.right {
		display: flex;
		flex-direction: column;
		align-items: flex-end;
		gap: 6px;
	}
	.empty {
		padding: 40px 16px;
		text-align: center;
		font-size: 13px;
		color: var(--ink3);
	}
</style>
