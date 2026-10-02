<script lang="ts">
  import { fText } from '$lib/i18n';
	import { RotateCcw } from '@lucide/svelte';
	import * as AlertDialog from '$lib/components/ui/alert-dialog';
	import { Button } from '$lib/components/ui/button';
	import { settingsStore } from '$lib/stores';

	interface Props {
		onReset?: () => void;
		onSave?: () => void;
	}

	let { onReset, onSave }: Props = $props();

	let showResetDialog = $state(false);

	function handleResetClick() {
		showResetDialog = true;
	}

	function handleConfirmReset() {
		settingsStore.forceSyncWithServerDefaults();
		onReset?.();

		showResetDialog = false;
	}

	function handleSave() {
		onSave?.();
	}
</script>

<div class="sticky bottom-0 mx-auto mt-4 flex w-full flex-wrap justify-between gap-2 pb-4 md:pb-0">
	<div class="flex min-w-0 max-w-full gap-2">
		<Button class="h-auto min-h-9 max-w-full shrink whitespace-normal" onclick={handleResetClick} variant="outline">
			<RotateCcw class="h-3 w-3" />

			{fText('messagebc5b45ae7b60')}
		</Button>
	</div>

	<Button class="h-auto min-h-9 max-w-full shrink whitespace-normal" onclick={handleSave}>{fText('message7f3a3b142814')}</Button>
</div>

<AlertDialog.Root bind:open={showResetDialog}>
	<AlertDialog.Content>
		<AlertDialog.Header>
			<AlertDialog.Title>{fText('message7047e493541d')}</AlertDialog.Title>

			<AlertDialog.Description>
				{fText('message395d23b1d04b')}
			</AlertDialog.Description>
		</AlertDialog.Header>

		<AlertDialog.Footer>
			<AlertDialog.Cancel>{fText('message19766ed6ccb2')}</AlertDialog.Cancel>

			<AlertDialog.Action onclick={handleConfirmReset}>{fText('messagec0334bae1053')}</AlertDialog.Action>
		</AlertDialog.Footer>
	</AlertDialog.Content>
</AlertDialog.Root>
