<script lang="ts">
  import { fText } from '$lib/i18n';
	import { ConversationSelection } from '$lib/components/app';
	import * as Dialog from '$lib/components/ui/dialog';

	interface Props {
		conversations: DatabaseConversation[];
		messageCountMap?: Map<string, number>;
		mode: 'export' | 'import';
		onCancel: () => void;
		onConfirm: (selectedConversations: DatabaseConversation[]) => void;
		open?: boolean;
	}

	let {
		conversations,
		messageCountMap = new Map(),
		mode,
		onCancel,
		onConfirm,
		open = $bindable(false)
	}: Props = $props();

	let conversationSelectionRef: ConversationSelection | undefined = $state();

	let previousOpen = $state(false);

	$effect(() => {
		if (open && !previousOpen && conversationSelectionRef) {
			conversationSelectionRef.reset();
		} else if (!open && previousOpen) {
			onCancel();
		}

		previousOpen = open;
	});
</script>

<Dialog.Root bind:open>
	<Dialog.Portal>
		<Dialog.Overlay class="z-1000000" />

		<Dialog.Content class="z-1000001 max-w-2xl">
			<Dialog.Header>
				<Dialog.Title>
					{fText('message950fdc1e46c2')} {mode === 'export' ? fText('message3664895579f0') : fText('message2cff9baabf56')}
				</Dialog.Title>

				<Dialog.Description>
					{#if mode === 'export'}
						{fText('message2ae6f6a0cc95')}
					{:else}
						{fText('message22d3a722a92b')}
					{/if}
				</Dialog.Description>
			</Dialog.Header>

			<ConversationSelection
				bind:this={conversationSelectionRef}
				{conversations}
				isOpen={open}
				{messageCountMap}
				{mode}
				{onCancel}
				{onConfirm}
			/>
		</Dialog.Content>
	</Dialog.Portal>
</Dialog.Root>
