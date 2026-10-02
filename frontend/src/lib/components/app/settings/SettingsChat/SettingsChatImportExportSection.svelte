<script lang="ts">
  import { fText } from '$lib/i18n';
	import { Button, type ButtonVariant } from '$lib/components/ui/button';
	import { ICON_CLASS_DEFAULT } from '$lib/constants';
	import type { Component } from 'svelte';

	let {
		buttonClass,
		buttonText,
		buttonVariant,
		description,
		IconComponent,
		onclick,
		summary,
		title,
		titleClass,
		wrapperClass
	}: {
		title: string;
		description: string;
		IconComponent: Component;
		buttonText: string;
		onclick: () => void;
		titleClass?: string;
		buttonVariant?: ButtonVariant;
		buttonClass?: string;
		wrapperClass?: string;
		summary?: { show: boolean; verb: string; items: DatabaseConversation[] };
	} = $props();

	let sectionButtonClass = $derived(buttonClass ?? 'justify-start justify-self-start md:w-auto');
	let sectionButtonVariant = $derived(buttonVariant ?? 'outline');
</script>

<div class="grid gap-1 {wrapperClass ?? ''}">
	<h4 class="mt-0 mb-2 text-sm font-medium {titleClass ?? ''}">{title}</h4>

	<p class="mb-4 text-sm text-muted-foreground">{description}</p>

	<Button class={sectionButtonClass} {onclick} variant={sectionButtonVariant}>
		<IconComponent class="mr-2 {ICON_CLASS_DEFAULT}" />

		{buttonText}
	</Button>

	{#if summary && summary.show && summary.items.length > 0}
		<div class="mt-4 grid overflow-x-auto rounded-lg border border-border/50 bg-muted/30 p-4">
			<h5 class="mb-2 text-sm font-medium">
				{summary.verb}
				{summary.items.length === 1
					? fText('message5a467ff1ebec')
					: fText('message45bcab63c82b', { p0: summary.items.length })}
			</h5>

			<ul class="space-y-1 text-sm text-muted-foreground">
				{#each summary.items.slice(0, 10) as conv (conv.id)}
					<li class="truncate">• {conv.name || fText('message31d248c44579')}</li>
				{/each}

				{#if summary.items.length > 10}
					<li class="italic">{fText('messagedb5b5790514b', { p0: summary.items.length - 10 })}</li>
				{/if}
			</ul>
		</div>
	{/if}
</div>
