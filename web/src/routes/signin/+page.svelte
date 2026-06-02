<script lang="ts">
	import { enhance } from '$app/forms';

	// First-run sign-in screen ("refined", evolved from wireframe A · Minimal):
	// calm centered identity block, a soft accent wash from the top, the </> tile
	// tinted with the single signal accent, brand-correct provider buttons, and a
	// secondary "Continue as guest" path. Auth itself is a seam (see session.ts);
	// every button just marks the device signed-in and moves on to onboarding.
	let submitting = $state<string | null>(null);
</script>

<div class="signin">
	<div class="wash" aria-hidden="true"></div>

	<div class="body">
		<div class="identity">
			<div class="glyph">&lt;/&gt;</div>
			<div class="titles">
				<div class="appname">Review Tracker</div>
				<div class="tagline">Spaced repetition for LeetCode.</div>
			</div>
		</div>

		<form
			method="POST"
			class="actions"
			use:enhance={({ submitter }) => {
				submitting = submitter?.getAttribute('formaction') ?? 'pending';
				return async ({ update }) => {
					await update();
					submitting = null;
				};
			}}
		>
			<button
				class="provider google"
				formaction="?/google"
				disabled={submitting !== null}
			>
				<span class="logo">
					<svg width="18" height="18" viewBox="0 0 48 48" aria-hidden="true">
						<path
							fill="#EA4335"
							d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"
						/>
						<path
							fill="#4285F4"
							d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"
						/>
						<path
							fill="#FBBC05"
							d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"
						/>
						<path
							fill="#34A853"
							d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"
						/>
					</svg>
				</span>
				Continue with Google
			</button>

			<button
				class="provider github"
				formaction="?/github"
				disabled={submitting !== null}
			>
				<span class="logo">
					<svg width="18" height="18" viewBox="0 0 16 16" fill="#fff" aria-hidden="true">
						<path
							d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82a7.6 7.6 0 0 1 2-.27c.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0 0 16 8c0-4.42-3.58-8-8-8z"
						/>
					</svg>
				</span>
				Continue with GitHub
			</button>

			<div class="divider" aria-hidden="true">
				<span class="line"></span>
				<span class="or">OR</span>
				<span class="line"></span>
			</div>

			<button class="guest" formaction="?/guest" disabled={submitting !== null}>
				Continue as guest
			</button>
			<div class="guest-note">Guest progress saves on this device only.</div>

			<p class="legal">
				By continuing you agree to the <span class="u">Terms</span> &amp;
				<span class="u">Privacy Policy</span>.
			</p>
		</form>
	</div>
</div>

<style>
	.signin {
		flex: 1;
		display: flex;
		flex-direction: column;
		min-height: 0;
		position: relative;
		background: var(--card);
		overflow: hidden;
	}

	/* a whisper of accent washing down from the top — "some colour" without clutter */
	.wash {
		position: absolute;
		inset: 0;
		pointer-events: none;
		background: radial-gradient(
			120% 60% at 50% -8%,
			color-mix(in srgb, var(--accent) 10%, transparent) 0%,
			transparent 60%
		);
	}

	.body {
		position: relative;
		z-index: 1;
		flex: 1;
		min-height: 0;
		display: flex;
		flex-direction: column;
		padding: 0 26px;
	}

	/* centered identity block */
	.identity {
		flex: 1;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		gap: 20px;
	}
	.glyph {
		width: 62px;
		height: 62px;
		border-radius: var(--r4);
		display: grid;
		place-items: center;
		flex-shrink: 0;
		background: var(--accent);
		box-shadow: 0 10px 26px -8px color-mix(in srgb, var(--accent) 55%, transparent);
		font-family: var(--mono);
		font-size: 28px;
		font-weight: 700;
		color: #fff;
	}
	.titles {
		text-align: center;
	}
	.appname {
		font-family: var(--sans);
		font-size: 23px;
		font-weight: 700;
		color: var(--ink);
		letter-spacing: -0.02em;
	}
	.tagline {
		font-family: var(--mono);
		font-size: 13.5px;
		color: var(--ink3);
		margin-top: 7px;
	}

	/* action block pinned low */
	.actions {
		display: flex;
		flex-direction: column;
		gap: 11px;
		padding-bottom: calc(30px + env(safe-area-inset-bottom));
	}

	.provider {
		position: relative;
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 10px;
		width: 100%;
		height: 50px;
		border-radius: 12px;
		font-family: var(--sans);
		font-size: 14px;
		font-weight: 600;
		transition: transform 0.12s ease, filter 0.12s ease;
	}
	.provider .logo {
		position: absolute;
		left: 16px;
		display: flex;
	}
	.google {
		background: #fff;
		border: 1px solid var(--line);
		color: #3c4043;
	}
	.github {
		background: #1f2328;
		border: 1px solid #1f2328;
		color: #fff;
	}

	.provider:not(:disabled):hover,
	.guest:not(:disabled):hover {
		filter: brightness(0.985);
	}
	.provider:not(:disabled):active,
	.guest:not(:disabled):active {
		transform: scale(0.985);
	}
	.provider:disabled,
	.guest:disabled {
		opacity: 0.6;
		cursor: default;
	}

	/* guest path */
	.divider {
		display: flex;
		align-items: center;
		gap: 10px;
		margin: 5px 0 1px;
	}
	.divider .line {
		flex: 1;
		height: 1px;
		background: var(--line2);
	}
	.divider .or {
		font-family: var(--mono);
		font-size: 10px;
		font-weight: 500;
		color: var(--ink3);
		letter-spacing: 0.12em;
	}

	.guest {
		width: 100%;
		height: 46px;
		border-radius: 12px;
		background: transparent;
		border: 1px solid var(--line);
		color: var(--ink2);
		font-family: var(--sans);
		font-size: 14px;
		font-weight: 600;
		display: flex;
		align-items: center;
		justify-content: center;
		transition: transform 0.12s ease, filter 0.12s ease;
	}
	.guest-note {
		font-family: var(--mono);
		font-size: 10.5px;
		line-height: 1.4;
		color: var(--ink3);
		text-align: center;
		margin-top: 1px;
	}

	.legal {
		font-family: var(--mono);
		font-size: 10.5px;
		line-height: 1.5;
		color: var(--ink3);
		text-align: center;
		margin: 7px 0 0;
	}
	.legal .u {
		color: var(--ink2);
		text-decoration: underline;
	}
</style>
