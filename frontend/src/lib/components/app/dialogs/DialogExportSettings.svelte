<script lang="ts">
  import { fText } from '$lib/i18n';
	import { Shield, ShieldOff } from '@lucide/svelte';
	import * as AlertDialog from '$lib/components/ui/alert-dialog';
	import { Checkbox } from '$lib/components/ui/checkbox';
	import Label from '$lib/components/ui/label/label.svelte';

	let {
		includeSensitiveData = $bindable(false),
		onCancel,
		onConfirm,
		open = $bindable()
	}: {
		open: boolean;
		includeSensitiveData: boolean;
		onCancel: () => void;
		onConfirm: () => void;
	} = $props();

	function handleOpenChange(newOpen: boolean) {
		if (!newOpen) {
			onCancel();
		}
	}
</script>

<AlertDialog.Root onOpenChange={handleOpenChange} {open}>
	<AlertDialog.Content>
		<AlertDialog.Header>
			<AlertDialog.Title class="flex items-center gap-2">
				{#if includeSensitiveData}
					<ShieldOff class="h-5 w-5 text-destructive" />
				{:else}
					<Shield class="h-5 w-5 text-destructive" />
				{/if}
				{fText('message653fc2d4487b')}
			</AlertDialog.Title>

			<AlertDialog.Description>
				{#if includeSensitiveData}
					<p class="text-amber-500">
						{fText('message2128979a60fe')}
					</p>
				{:else}
					<p>
						{fText('message2a84957e75b8')}
					</p>
				{/if}
			</AlertDialog.Description>
		</AlertDialog.Header>

		<div class="flex items-center gap-2 py-2">
			<Checkbox bind:checked={includeSensitiveData} id="include-sensitive" />

			<Label
				class="text-sm leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
				for="include-sensitive"
			>
				{#if includeSensitiveData}
					<span class="text-destructive">{fText('messagee62045a726cd')}</span>
				{:else}
					<span>{fText('message56edd55de767')}</span>
				{/if}
			</Label>
		</div>

		<AlertDialog.Footer>
			<AlertDialog.Cancel onclick={onCancel}>{fText('message19766ed6ccb2')}</AlertDialog.Cancel>

			<AlertDialog.Action
				class="bg-destructive text-white hover:bg-destructive/80"
				onclick={onConfirm}
			>
				{#if includeSensitiveData}
					{fText('message2e0e2b8be2ff')}
				{:else}
					{fText('message41c9da198e89')}
				{/if}
			</AlertDialog.Action>
		</AlertDialog.Footer>
	</AlertDialog.Content>
</AlertDialog.Root>
