<script lang="ts">
  import { fText } from '$lib/i18n';
	interface Props {
		isLoading: boolean;
	}

	let { isLoading }: Props = $props();
</script>

<div class="py-4 text-center text-sm text-muted-foreground">
	{#if isLoading}
		{fText('messagef851843d3fed')}
	{:else}
		{fText('message1e2ad76694e1')}
	{/if}
</div>
