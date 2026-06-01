<script lang="ts">
	interface Props {
		on: boolean;
	}
	let { on }: Props = $props();
</script>

<span class="radio" class:on>{#if on}<span class="inner"></span>{/if}</span>

<style>
	.radio {
		width: 17px;
		height: 17px;
		border-radius: 999px;
		background: #fff;
		border: 1px solid var(--line);
		display: inline-flex;
		align-items: center;
		justify-content: center;
		flex: none;
	}
	.radio.on {
		background: var(--ink);
		border-color: var(--ink);
	}
	.inner {
		width: 6px;
		height: 6px;
		border-radius: 999px;
		background: #fff;
	}
</style>
