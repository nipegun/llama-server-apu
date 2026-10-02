<script lang="ts">
  import { fText } from '$lib/i18n';
	import { Check, ChevronDown, ChevronRight, Info, Loader2, PencilRuler } from '@lucide/svelte';
	import { Checkbox } from '$lib/components/ui/checkbox';
	import * as Collapsible from '$lib/components/ui/collapsible';
	import * as DropdownMenu from '$lib/components/ui/dropdown-menu';
	import * as Tooltip from '$lib/components/ui/tooltip';
	import { CLI_FLAGS, ICON_CLASS_DEFAULT } from '$lib/constants';
	import { useToolsPanel } from '$lib/hooks/use-tools-panel.svelte';
	import { mcpStore, toolsStore } from '$lib/stores';
	import type { ToolGroup } from '$lib/types';

	const toolsPanel = useToolsPanel();
	const hasMcpServersAvailable = $derived(mcpStore.getServers().length > 0);
</script>

<DropdownMenu.Sub onOpenChange={(open) => open && toolsPanel.handleOpen()}>
	<DropdownMenu.SubTrigger class="flex cursor-pointer items-center gap-2">
		<PencilRuler class={ICON_CLASS_DEFAULT} />

		<span>{fText('messageea93d6a262ec')}</span>
	</DropdownMenu.SubTrigger>

	<DropdownMenu.SubContent class="w-72 p-0">
		{#if toolsPanel.totalToolCount === 0}
			{#if toolsStore.loading}
				<div class="px-3 py-4 text-center text-sm text-muted-foreground">
					<Loader2 class="mx-auto mb-1 {ICON_CLASS_DEFAULT} animate-spin" />

					{fText('messageefc190cd4ce7')}
				</div>
			{:else if toolsStore.isToolsEndpointUnreachable}
				<div class="grid gap-2.5 px-3 py-4 text-sm text-muted-foreground">
					<span class="flex gap-2">
						<Info class="mt-0.5 {ICON_CLASS_DEFAULT} shrink-0" />

						<span>
							{fText('message9b5e82028f67')} <code>{CLI_FLAGS.TOOLS}</code> {fText('message534e6d6e87c7')}

							<strong>{fText('messagee3ac1ee0f8b3')}</strong>.
						</span>
					</span>

					<span class="flex gap-2">
						<Info class="mt-0.5 {ICON_CLASS_DEFAULT} shrink-0" />

						<span>
							{hasMcpServersAvailable ? fText('message5342e09f2729') : fText('message9fd728c66c9a')}
							{fText('message35302548c7fd')}

							<strong>{fText('messageecd806d3c25e')}</strong>.
						</span>
					</span>
				</div>
			{:else if toolsStore.error}
				<div class="px-3 py-4 text-center text-sm text-muted-foreground">{fText('message5ceb12c7da97')}</div>
			{:else if toolsPanel.noToolsInfoMessage}
				<div class="flex gap-2 px-3 py-4 text-sm text-muted-foreground">
					<Info class="mt-0.5 {ICON_CLASS_DEFAULT} shrink-0" />

					<span>{toolsPanel.noToolsInfoMessage}</span>
				</div>
			{:else}
				<div class="px-3 py-4 text-center text-sm text-muted-foreground">{fText('message0ec9813e343b')}</div>
			{/if}
		{:else}
			<div class="max-h-80 overflow-y-auto p-2 pr-1">
				{#each toolsPanel.categoryGroups as group (group.key)}
					{@render groupRow(group)}
				{/each}

				{#each toolsPanel.mcpGroups as group (group.key)}
					{@render groupRow(group)}
				{/each}
			</div>
		{/if}
	</DropdownMenu.SubContent>
</DropdownMenu.Sub>

{#snippet groupRow(group: ToolGroup)}
	{@const isExpanded = toolsPanel.expandedGroups.has(group.key)}
	{@const checkState = toolsPanel.getGroupCheckState(group)}
	{@const favicon = toolsPanel.getFavicon(group)}
	{@const groupDisabled = toolsPanel.isGroupDisabled(group)}

	<Collapsible.Root
		onOpenChange={() => toolsPanel.toggleGroupExpanded(group.key)}
		open={isExpanded}
	>
		<div class="flex items-center gap-1 {groupDisabled ? 'pointer-events-none opacity-50' : ''}">
			<Collapsible.Trigger
				class="flex min-w-0 flex-1 items-center gap-2 rounded px-2 py-1.5 text-sm hover:bg-muted/50"
			>
				{#if isExpanded}
					<ChevronDown class="h-3.5 w-3.5 shrink-0" />
				{:else}
					<ChevronRight class="h-3.5 w-3.5 shrink-0" />
				{/if}

				<span class="inline-flex min-w-0 items-center gap-1.5 font-medium">
					{#if favicon}
						<img
							alt=""
							class="{ICON_CLASS_DEFAULT} shrink-0 rounded-sm"
							onerror={(e) => {
								(e.currentTarget as HTMLImageElement).style.display = 'none';
							}}
							src={favicon}
						/>
					{/if}

					<span class="truncate">{group.label}</span>
				</span>

				<span class="ml-auto shrink-0 text-xs text-muted-foreground">
					{toolsPanel.getEnabledToolCount(group)}/{group.tools.length}
				</span>
			</Collapsible.Trigger>

			<Tooltip.Root>
				<Tooltip.Trigger>
					{#snippet child({ props })}
						<Checkbox
							{...props}
							checked={checkState.checked}
							class="mr-2 {ICON_CLASS_DEFAULT} shrink-0"
							indeterminate={checkState.indeterminate}
							onCheckedChange={() => toolsPanel.toggleGroupByKey(group.key)}
						/>
					{/snippet}
				</Tooltip.Trigger>

				<Tooltip.Content side="right">
					<p>
						{checkState.checked ? fText('messageb7e3e4aa4257') : fText('message5342e09f2729')}
						{group.tools.length === 1
							? fText('message8a50a9b59265', { p0: group.tools.length })
							: fText('messagef0d89224783b', { p0: group.tools.length })}
					</p>
				</Tooltip.Content>
			</Tooltip.Root>
		</div>

		<Collapsible.Content>
			<div class="ml-4 flex flex-col gap-0.5 border-l border-border/50 pl-2">
				{#each group.tools as entry (entry.key)}
					{@const enabled = toolsPanel.isToolEnabled(entry)}
					{@const parentDisabled = toolsPanel.isToolParentDisabled(entry)}
					<button
						class="flex w-full items-center gap-2 rounded px-2 py-1.5 text-left text-sm transition-colors hover:bg-muted/50 {parentDisabled
							? 'opacity-50'
							: ''}"
						onclick={() => toolsPanel.toggleTool(entry)}
						type="button"
					>
						<span
							class="flex size-4 shrink-0 items-center justify-center rounded-[4px] border border-input data-[state=checked]:border-primary data-[state=checked]:bg-primary data-[state=checked]:text-primary-foreground"
							data-slot="checkbox"
							data-state={enabled ? 'checked' : 'unchecked'}
						>
							{#if enabled}
								<Check class="size-3.5" />
							{/if}
						</span>

						<span class="min-w-0 flex-1 truncate font-mono text-[12px]">
							{entry.definition.function.name}
						</span>
					</button>
				{/each}
			</div>
		</Collapsible.Content>
	</Collapsible.Root>
{/snippet}
