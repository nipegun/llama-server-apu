<script lang="ts">
  import { fText } from '$lib/i18n';
	import { FileX } from '@lucide/svelte';
	import * as AlertDialog from '$lib/components/ui/alert-dialog';

	interface Props {
		open: boolean;
		emptyFiles: string[];
		onOpenChange?: (open: boolean) => void;
	}

	let { emptyFiles, onOpenChange, open = $bindable() }: Props = $props();

	function handleOpenChange(newOpen: boolean) {
		open = newOpen;
		onOpenChange?.(newOpen);
	}
</script>

<AlertDialog.Root onOpenChange={handleOpenChange} {open}>
	<AlertDialog.Content>
		<AlertDialog.Header>
			<AlertDialog.Title class="flex items-center gap-2">
				<FileX class="h-5 w-5 text-destructive" />

				{fText('messaged482e9733562')}
			</AlertDialog.Title>

			<AlertDialog.Description>
				{fText('message2b3fb3f06e10')}
			</AlertDialog.Description>
		</AlertDialog.Header>

		<div class="space-y-3 text-sm">
			<div class="rounded-lg bg-muted p-3">
				<div class="mb-2 font-medium">{fText('messagea9484458301b')}</div>

				<ul class="list-inside list-disc space-y-1 text-muted-foreground">
					{#each emptyFiles as fileName (fileName)}
						<li class="font-mono text-sm">{fileName}</li>
					{/each}
				</ul>
			</div>

			<div>
				<div class="mb-2 font-medium">{fText('message8981f39cac60')}</div>

				<ul class="list-inside list-disc space-y-1 text-muted-foreground">
					<li>{fText('message3a7594ed9269')}</li>

					<li>{fText('message27ce175a9dbc')}</li>

					<li>{fText('message238412919030')}</li>
				</ul>
			</div>
		</div>

		<AlertDialog.Footer>
			<AlertDialog.Action onclick={() => handleOpenChange(false)}>{fText('message5ad3dbd1242a')}</AlertDialog.Action>
		</AlertDialog.Footer>
	</AlertDialog.Content>
</AlertDialog.Root>
