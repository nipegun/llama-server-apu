<script lang="ts">
  import { fText } from '$lib/i18n';
	import ChatMessageActionCard from './ChatMessageActionCard.svelte';
	import { RotateCw } from '@lucide/svelte';
	import { Button } from '$lib/components/ui/button';

	interface Props {
		onDecision: (shouldContinue: boolean) => void;
	}

	let { onDecision }: Props = $props();
</script>

<ChatMessageActionCard icon={RotateCw}>
	{#snippet message()}
		{fText('message8e578ac4f04b')}
	{/snippet}

	{#snippet actions()}
		<Button onclick={() => onDecision(true)} size="sm">{fText('message31fbef162594')}</Button>

		<Button
			class="text-destructive hover:text-destructive"
			onclick={() => onDecision(false)}
			size="sm"
			variant="destructive"
		>
			{fText('messagecae7d57bc067')}
		</Button>
	{/snippet}
</ChatMessageActionCard>
