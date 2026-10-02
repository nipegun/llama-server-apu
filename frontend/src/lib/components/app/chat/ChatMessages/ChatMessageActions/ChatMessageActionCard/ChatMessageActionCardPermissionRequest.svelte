<script lang="ts">
  import { fText } from '$lib/i18n';
	import { ChevronDown, ShieldQuestion } from '@lucide/svelte';
	import { ChatMessageActionCard } from '$lib/components/app';
	import { Button, buttonVariants } from '$lib/components/ui/button';
	import * as ButtonGroup from '$lib/components/ui/button-group';
	import * as DropdownMenu from '$lib/components/ui/dropdown-menu';
	import { cn } from '$lib/components/ui/utils';
	import { TOOL_SERVER_LABELS } from '$lib/constants';
	import { ToolPermissionDecision, ToolSource } from '$lib/enums';
	import { toolsStore } from '$lib/stores';

	interface Props {
		toolName: string;
		serverLabel: string;
		onDecision: (decision: ToolPermissionDecision) => void;
	}

	let { onDecision, serverLabel, toolName }: Props = $props();
</script>

<ChatMessageActionCard icon={ShieldQuestion}>
	{#snippet message()}
		{fText('message44f5e65bfcaf')} <span class="font-semibold">{toolName}</span>{#if serverLabel}
			&nbsp;{fText('message75857a458999')} <span class="font-semibold">{serverLabel}</span>{/if}?
	{/snippet}

	{#snippet actions()}
		<DropdownMenu.Root>
			<ButtonGroup.Root class="overflow-hidden rounded-md shadow-sm">
				<Button
					class="!rounded-r-none !shadow-none"
					onclick={() => onDecision(ToolPermissionDecision.ONCE)}
					size="sm"
					variant="secondary"
				>
					{fText('message168511d24d9e')}
				</Button>

				<ButtonGroup.Separator />

				<DropdownMenu.Trigger
					aria-label={fText('message5680c021458b')}
					class={cn(
						buttonVariants({ size: 'sm', variant: 'secondary' }),
						'inline-flex cursor-pointer items-center !rounded-l-none !shadow-none !px-2'
					)}
				>
					<ChevronDown class="h-3.5 w-3.5" />
				</DropdownMenu.Trigger>
			</ButtonGroup.Root>

			<DropdownMenu.Content align="start" class="min-w-[8rem]">
				<DropdownMenu.Item onclick={() => onDecision(ToolPermissionDecision.ALWAYS)}>
					{fText('message977618bd8bc7')} <pre>{toolName}</pre>
					{fText('message7c9bbe5ec9b3')}
				</DropdownMenu.Item>

				{#if serverLabel}
					<DropdownMenu.Item onclick={() => onDecision(ToolPermissionDecision.ALWAYS_SERVER)}>
						{fText('messagec3b44cb1bd9a')} {serverLabel}
					</DropdownMenu.Item>
				{:else}
					{@const source = toolsStore.getToolSource(toolName)}
					{@const providerName =
						source === ToolSource.SERVER
							? TOOL_SERVER_LABELS[ToolSource.SERVER]
							: source === ToolSource.CUSTOM
								? TOOL_SERVER_LABELS[ToolSource.CUSTOM]
								: fText('messageecd806d3c25e')}
					<DropdownMenu.Item onclick={() => onDecision(ToolPermissionDecision.ALWAYS_SERVER)}>
						{fText('message41b73824de28')} {providerName}
					</DropdownMenu.Item>
				{/if}
			</DropdownMenu.Content>
		</DropdownMenu.Root>

		<Button onclick={() => onDecision(ToolPermissionDecision.DENY)} size="sm" variant="destructive">
			{fText('message05a2d7332eb9')}
		</Button>
	{/snippet}
</ChatMessageActionCard>
