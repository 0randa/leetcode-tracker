<script lang="ts">
	import Icon from './Icon.svelte';

	interface Props {
		streak: number;
		solved: number;
		done: number;
		total: number;
	}
	let { streak, solved, done, total }: Props = $props();
	const pct = $derived(total > 0 ? done / total : 0);
</script>

<!-- Streak · total solved · progress through today's set, + reserved gear slot. -->
<div class="strip">
	<div class="stat">
		<Icon name="flame" size={15} color="var(--ink2)" />
		<b>{streak}</b><span class="muted">day</span>
	</div>
	<div class="sep"></div>
	<div class="stat"><b>{solved}</b><span class="muted">solved</span></div>
	<div class="spacer"></div>
	<div class="progress">
		<div class="track"><div class="fill" style="width:{pct * 100}%"></div></div>
		<span class="frac">{done}/{total}</span>
	</div>
	<!-- Reserved Settings slot — temporary Sign out until a Settings screen exists. -->
	<form method="POST" action="/auth/logout" class="gear-form">
		<button class="gear" type="submit" aria-label="Sign out">
			<Icon name="gear" size={18} color="var(--ink3)" />
		</button>
	</form>
</div>

<style>
	.strip {
		display: flex;
		align-items: center;
		gap: 14px;
		padding: 12px 16px;
		border-bottom: 1px solid var(--line2);
	}
	.stat {
		display: flex;
		align-items: center;
		gap: 6px;
	}
	.stat b {
		font-size: 14px;
		font-weight: 700;
		color: var(--ink);
	}
	.muted {
		font-size: 11px;
		color: var(--ink3);
	}
	.sep {
		width: 1px;
		height: 18px;
		background: var(--line2);
	}
	.spacer {
		flex: 1;
	}
	.progress {
		display: flex;
		align-items: center;
		gap: 8px;
	}
	.track {
		width: 48px;
		height: 6px;
		border-radius: 999px;
		background: var(--fill);
		overflow: hidden;
	}
	.fill {
		height: 100%;
		background: var(--ink);
		border-radius: 999px;
		transition: width 0.25s ease;
	}
	.frac {
		font-family: var(--mono);
		font-size: 11px;
		font-weight: 600;
		color: var(--ink2);
	}
	.gear-form {
		display: inline-flex;
	}
	.gear {
		opacity: 0.4;
		display: inline-flex;
		background: none;
		border: none;
		padding: 0;
		cursor: pointer;
		transition: opacity 0.12s ease;
	}
	.gear:hover {
		opacity: 0.75;
	}
</style>
