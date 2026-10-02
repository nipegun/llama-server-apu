<script lang="ts">
  import { fText, fGetLocale } from '$lib/i18n';
	import { AlertTriangle, TimerOff } from '@lucide/svelte';
	import * as AlertDialog from '$lib/components/ui/alert-dialog';
	import { ErrorDialogType } from '$lib/enums';

	interface Props {
		open: boolean;
		type: ErrorDialogType;
		message: string;
		contextInfo?: { n_prompt_tokens: number; n_ctx: number };
		onOpenChange?: (open: boolean) => void;
	}

	let { contextInfo, message, onOpenChange, open = $bindable(), type }: Props = $props();

	const isTimeout = $derived(type === ErrorDialogType.TIMEOUT);
	const title = $derived(isTimeout ? fText('messageb0c2637f6a9d') : fText('message1e2a5d69cec7'));
	const description = $derived(
		isTimeout
			? fText('message6cf7c7451458')
			: fText('message8766dcd6d3b6')
	);
	const iconClass = $derived(isTimeout ? 'text-destructive' : 'text-amber-500');
	const badgeClass = $derived(
		isTimeout
			? 'border-destructive/40 bg-destructive/10 text-destructive'
			: 'border-amber-500/40 bg-amber-500/10 text-amber-600 dark:text-amber-400'
	);

	function handleOpenChange(newOpen: boolean) {
		open = newOpen;
		onOpenChange?.(newOpen);
	}
</script>

<AlertDialog.Root onOpenChange={handleOpenChange} {open}>
	<AlertDialog.Content>
		<AlertDialog.Header>
			<AlertDialog.Title class="flex items-center gap-2">
				{#if isTimeout}
					<TimerOff class={`h-5 w-5 ${iconClass}`} />
				{:else}
					<AlertTriangle class={`h-5 w-5 ${iconClass}`} />
				{/if}

				{title}
			</AlertDialog.Title>

			<AlertDialog.Description>
				{description}
			</AlertDialog.Description>
		</AlertDialog.Header>

		<div class={`rounded-lg border px-4 py-3 text-sm ${badgeClass}`}>
			<p class="font-medium">{message}</p>

			{#if contextInfo}
				<div class="mt-2 space-y-1 text-xs opacity-80">
					<p>
						<span class="font-medium">{fText('message8dc0accba0c3')}</span>

						{contextInfo.n_prompt_tokens.toLocaleString(fGetLocale())}
					</p>

					{#if contextInfo.n_ctx}
						<p>
							<span class="font-medium">{fText('message4c16417781c9')}</span>

							{contextInfo.n_ctx.toLocaleString(fGetLocale())}
						</p>
					{/if}
				</div>
			{/if}
		</div>

		<AlertDialog.Footer>
			<AlertDialog.Action onclick={() => handleOpenChange(false)}>{fText('message7d9eb7acb13e')}</AlertDialog.Action>
		</AlertDialog.Footer>
	</AlertDialog.Content>
</AlertDialog.Root>
