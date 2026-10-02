<script lang="ts">
  import { fText } from '$lib/i18n';
	import { AlertCircle, Download, FileText, Loader2 } from '@lucide/svelte';
	import { ActionIconCopyToClipboard } from '$lib/components/app';
	import { Button } from '$lib/components/ui/button';
	import { ICON_CLASS_DEFAULT } from '$lib/constants';
	import { MimeTypeApplication, MimeTypeText } from '$lib/enums';
	import { mcpStore } from '$lib/stores';
	import type { MCPResourceContent, MCPResourceInfo } from '$lib/types';
	import {
		createBase64DataUrl,
		downloadResourceContent,
		getResourceBlobContent,
		getResourceTextContent,
		isImageMimeType
	} from '$lib/utils';

	interface Props {
		resource: MCPResourceInfo | null;
		/** Pre-loaded content (e.g., from template resolution). Skips store fetch when provided. */
		preloadedContent?: MCPResourceContent[] | null;
		class?: string;
	}

	let { class: className, preloadedContent, resource }: Props = $props();

	let content = $state<MCPResourceContent[] | null>(null);
	let isLoading = $state(false);
	let error = $state<string | null>(null);

	$effect(() => {
		if (resource) {
			if (preloadedContent) {
				content = preloadedContent;
				isLoading = false;
				error = null;
			} else {
				loadContent(resource.uri);
			}
		} else {
			content = null;
			error = null;
		}
	});

	async function loadContent(uri: string) {
		isLoading = true;
		error = null;

		try {
			const result = await mcpStore.readResource(uri);

			if (result) {
				content = result;
			} else {
				error = fText('message10768df2d448');
			}
		} catch (e) {
			error = e instanceof Error ? e.message : fText('message27c2ccd962c2');
		} finally {
			isLoading = false;
		}
	}

	function handleDownload() {
		const text = getResourceTextContent(content);

		if (!text || !resource) return;

		downloadResourceContent(
			text,
			resource.mimeType || MimeTypeText.PLAIN,
			resource.name || 'resource.txt'
		);
	}
</script>

<div class={['flex flex-col gap-3', className]}>
	{#if !resource}
		<div class="flex flex-col items-center justify-center gap-2 py-8 text-muted-foreground">
			<FileText class="h-8 w-8 opacity-50" />

			<span class="text-sm">{fText('messagea09ca1a10c95')}</span>
		</div>
	{:else}
		<div class="flex items-start justify-between gap-2">
			<div class="min-w-0 flex-1">
				<h3 class="truncate font-medium">{resource.title || resource.name}</h3>

				<p class="truncate text-xs text-muted-foreground">{resource.uri}</p>

				{#if resource.description}
					<p class="mt-1 text-sm text-muted-foreground">{resource.description}</p>
				{/if}
			</div>

			<div class="flex items-center gap-1">
				<ActionIconCopyToClipboard
					ariaLabel={fText('message4ad7ba818148')}
					canCopy={!isLoading && !!getResourceTextContent(content)}
					text={getResourceTextContent(content)}
				/>

				<Button
					class="h-7 w-7 p-0"
					disabled={isLoading || !getResourceTextContent(content)}
					onclick={handleDownload}
					size="sm"
					title={fText('message6eca010826ea')}
					variant="ghost"
				>
					<Download class="h-3.5 w-3.5" />
				</Button>
			</div>
		</div>

		<div class="min-h-[200px] overflow-auto rounded-md border bg-muted/30 p-3 break-all">
			{#if isLoading}
				<div class="flex items-center justify-center py-8">
					<Loader2 class="h-6 w-6 animate-spin text-muted-foreground" />
				</div>
			{:else if error}
				<div class="flex flex-col items-center justify-center gap-2 py-8 text-red-500">
					<AlertCircle class="h-6 w-6" />

					<span class="text-sm">{error}</span>
				</div>
			{:else if content}
				{@const textContent = getResourceTextContent(content)}
				{@const blobContent = getResourceBlobContent(content)}

				{#if textContent}
					<pre class="font-mono text-xs break-words whitespace-pre-wrap">{textContent}</pre>
				{/if}

				{#each blobContent as blob (blob.uri)}
					{#if isImageMimeType(blob.mimeType ?? MimeTypeApplication.OCTET_STREAM)}
						<img
							alt={fText('message5c80d1708bf1')}
							class="max-w-full rounded"
							src={createBase64DataUrl(
								blob.mimeType ?? MimeTypeApplication.OCTET_STREAM,
								blob.blob
							)}
						/>
					{:else}
						<div class="flex items-center gap-2 rounded bg-muted p-2 text-sm text-muted-foreground">
							<FileText class={ICON_CLASS_DEFAULT} />

							<span>{fText('messagefcc7d62699b2', { p0: blob.mimeType || fText('message0fb6c17f32d3') })}</span>
						</div>
					{/if}
				{/each}

				{#if !textContent && blobContent.length === 0}
					<div class="py-4 text-center text-sm text-muted-foreground">{fText('messagea7c49ff5b9e2')}</div>
				{/if}
			{/if}
		</div>

		{#if resource.mimeType || resource.annotations}
			<div class="flex flex-wrap gap-2 text-xs text-muted-foreground">
				{#if resource.mimeType}
					<span class="rounded bg-muted px-1.5 py-0.5">{resource.mimeType}</span>
				{/if}

				{#if resource.annotations?.priority !== undefined}
					<span class="rounded bg-muted px-1.5 py-0.5">
						{fText('message34574af1e694')} {resource.annotations.priority}
					</span>
				{/if}

				<span class="rounded bg-muted px-1.5 py-0.5">
					{fText('message087fbe073393')} {resource.serverName}
				</span>
			</div>
		{/if}
	{/if}
</div>
