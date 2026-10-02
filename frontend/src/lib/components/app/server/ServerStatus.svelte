<script lang="ts">
  import { fText, fGetLocale } from '$lib/i18n';
	import { AlertTriangle, Server } from '@lucide/svelte';
	import { Badge } from '$lib/components/ui/badge';
	import { Button } from '$lib/components/ui/button';
	import { ICON_CLASS_DEFAULT } from '$lib/constants';
	import { modelsStore, serverStore } from '$lib/stores';

	interface Props {
		class?: string;
		showActions?: boolean;
	}

	let { class: className = '', showActions = false }: Props = $props();

	let error = $derived(serverStore.error);
	let loading = $derived(serverStore.loading);
	let model = $derived(modelsStore.singleModelName);
	let serverData = $derived(serverStore.props);

	function getStatusColor() {
		if (loading) return 'bg-yellow-500';

		if (error) return 'bg-red-500';

		if (serverData) return 'bg-green-500';

		return 'bg-gray-500';
	}

	function getStatusText() {
		if (loading) return fText('message5f04ae9ed6a8');

		if (error) return fText('messageddb621f87c5c');

		if (serverData) return fText('message22965568d22a');

		return fText('messageb764cdc0eab7');
	}
</script>

<div class="flex items-center space-x-3 {className}">
	<div class="flex items-center space-x-2">
		<div class="h-2 w-2 rounded-full {getStatusColor()}"></div>

		<span class="text-sm text-muted-foreground">{getStatusText()}</span>
	</div>

	{#if serverData && !error}
		<Badge class="text-xs" variant="outline">
			<Server class="mr-1 h-3 w-3" />

			{model || fText('message3abcd81da434')}
		</Badge>

		{#if serverData?.default_generation_settings?.n_ctx}
			<Badge class="text-xs" variant="secondary">
				{fText('message051765386b25')} {serverData.default_generation_settings.n_ctx.toLocaleString(fGetLocale())}
			</Badge>
		{/if}
	{/if}

	{#if showActions && error}
		<Button class="text-destructive" size="sm" variant="outline">
			<AlertTriangle class={ICON_CLASS_DEFAULT} />

			{error}
		</Button>
	{/if}
</div>
