<script lang="ts">
	interface Props {
		on: boolean;
		onchange?: (v: boolean) => void;
	}
	let { on = $bindable(), onchange }: Props = $props();
	function toggle() {
		on = !on;
		onchange?.(on);
	}
</script>

<button type="button" class="toggle" class:on aria-pressed={on} aria-label="Peeked at the solution" onclick={toggle}>
	<span class="knob"></span>
</button>

<style>
	.toggle {
		width: 40px;
		height: 23px;
		border-radius: 999px;
		background: var(--fill);
		border: 1px solid var(--line);
		padding: 0 2px;
		display: flex;
		align-items: center;
		justify-content: flex-start;
		transition: background 0.15s ease, border-color 0.15s ease;
	}
	.toggle.on {
		background: var(--ink);
		border-color: var(--ink);
		justify-content: flex-end;
	}
	.knob {
		width: 17px;
		height: 17px;
		border-radius: 999px;
		background: #fff;
		box-shadow: 0 1px 1px rgba(0, 0, 0, 0.2);
	}
</style>
