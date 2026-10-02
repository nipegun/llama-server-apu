<script lang="ts">
  import { fText } from '$lib/i18n';
	import * as AlertDialog from '$lib/components/ui/alert-dialog';

	interface Props {
		open: boolean;
		displayName: string;
		onOpenChange: (open: boolean) => void;
		onConfirm: () => void;
	}

	let { displayName, onConfirm, onOpenChange, open = $bindable() }: Props = $props();
</script>

<AlertDialog.Root bind:open {onOpenChange}>
	<AlertDialog.Content>
		<AlertDialog.Header>
			<AlertDialog.Title>{fText('message056e6a5f6594')}</AlertDialog.Title>

			<AlertDialog.Description>
				{fText('message3a57bb9fb3bf')} <strong>{displayName}</strong>{fText('message30f98589bee4')}
			</AlertDialog.Description>
		</AlertDialog.Header>

		<AlertDialog.Footer>
			<AlertDialog.Cancel>{fText('message19766ed6ccb2')}</AlertDialog.Cancel>

			<AlertDialog.Action
				class="text-destructive-foreground bg-destructive hover:bg-destructive/90"
				onclick={onConfirm}
			>
				{fText('messagee2d0a54968ea')}
			</AlertDialog.Action>
		</AlertDialog.Footer>
	</AlertDialog.Content>
</AlertDialog.Root>
