<script lang="ts">
  import { fText } from '$lib/i18n';
	import ModelId from './ModelId.svelte';
	import { Package } from '@lucide/svelte';
	import { ActionIconCopyToClipboard, BadgeInfo } from '$lib/components/app';
	import * as Tooltip from '$lib/components/ui/tooltip';
	import { modelsStore, serverStore } from '$lib/stores';

	interface Props {
		class?: string;
		model?: string;
		onclick?: () => void;
		showCopyIcon?: boolean;
		showTooltip?: boolean;
	}

	let {
		class: className = '',
		model: modelProp,
		onclick,
		showCopyIcon = false,
		showTooltip = false
	}: Props = $props();

	let model = $derived(modelProp || modelsStore.singleModelName);
	let isModelMode = $derived(serverStore.isModelMode);
	let shouldShow = $derived(model && (modelProp !== undefined || isModelMode));
</script>

{#snippet badgeContent(triggerProps?: Record<string, unknown>)}
	<BadgeInfo {...triggerProps ?? {}} class={className} {onclick}>
		{#snippet icon()}
			<Package class="h-3 w-3" />
		{/snippet}

		{#if model}
			<ModelId modelId={model} />
		{/if}

		{#if showCopyIcon}
			<ActionIconCopyToClipboard ariaLabel={fText('message136e93e3d54b')} text={model || ''} />
		{/if}
	</BadgeInfo>
{/snippet}

{#if shouldShow}
	{#if showTooltip}
		<Tooltip.Root>
			<Tooltip.Trigger>
				<!-- prevent another nested button element -->
				{#snippet child({ props })}
					{@render badgeContent(props)}
				{/snippet}
			</Tooltip.Trigger>

			<Tooltip.Content>
				{onclick ? fText('message4d44206fe9e5') : model}
			</Tooltip.Content>
		</Tooltip.Root>
	{:else}
		{@render badgeContent()}
	{/if}
{/if}
