<script lang="ts">
  import { fText } from '$lib/i18n';
	import { Eye, FileText, Info } from '@lucide/svelte';
	import { SyntaxHighlightedCode } from '$lib/components/app';
	import * as Alert from '$lib/components/ui/alert';
	import { Button } from '$lib/components/ui/button';
	import { ICON_CLASS_DEFAULT } from '$lib/constants';
	import { PdfViewMode } from '$lib/enums';
	import type { ChatAttachmentDisplayItem } from '$lib/types';
	import { getLanguageFromFilename } from '$lib/utils';
	import { convertPDFToImage } from '$lib/utils/browser-only';

	interface Props {
		currentItem: ChatAttachmentDisplayItem | null;
		displayName: string;
		displayTextContent: string | undefined;
		hasVisionModality: boolean;
		activeModelId?: string;
	}

	let { activeModelId, currentItem, displayName, displayTextContent, hasVisionModality }: Props =
		$props();

	let pdfViewMode = $state<PdfViewMode>(PdfViewMode.PAGES);
	let pdfImages = $state<string[]>([]);
	let pdfImagesLoading = $state(false);
	let pdfImagesError = $state<string | null>(null);

	let language = $derived(getLanguageFromFilename(displayName));

	async function loadPdfImages() {
		if (pdfImages.length > 0 || pdfImagesLoading || !currentItem) return;

		pdfImagesLoading = true;
		pdfImagesError = null;

		try {
			let file: File | null = null;

			if (currentItem.uploadedFile?.file) {
				file = currentItem.uploadedFile.file;
			} else if (currentItem.attachment) {
				// Check if we have pre-processed images
				if (
					'images' in currentItem.attachment &&
					currentItem.attachment.images &&
					Array.isArray(currentItem.attachment.images) &&
					currentItem.attachment.images.length > 0
				) {
					pdfImages = currentItem.attachment.images;

					return;
				}

				// Convert base64 back to File for processing
				if ('base64Data' in currentItem.attachment && currentItem.attachment.base64Data) {
					const base64Data = currentItem.attachment.base64Data;
					const byteCharacters = atob(base64Data);
					const byteNumbers = new Array(byteCharacters.length);

					for (let i = 0; i < byteCharacters.length; i++) {
						byteNumbers[i] = byteCharacters.charCodeAt(i);
					}
					const byteArray = new Uint8Array(byteNumbers);

					file = new File([byteArray], displayName, { type: 'application/pdf' });
				}
			}

			if (file) {
				pdfImages = await convertPDFToImage(file);
			} else {
				throw new Error(fText('message4291e9544b36'));
			}
		} catch (error) {
			pdfImagesError = error instanceof Error ? error.message : fText('messagee6728ce51717');
		} finally {
			pdfImagesLoading = false;
		}
	}

	$effect(() => {
		if (pdfViewMode === PdfViewMode.PAGES) {
			loadPdfImages();
		}
	});
</script>

<div class="mb-4 flex items-center justify-end gap-2">
	<Button
		disabled={pdfImagesLoading}
		onclick={() => (pdfViewMode = PdfViewMode.TEXT)}
		size="sm"
		variant={pdfViewMode === PdfViewMode.TEXT ? 'default' : 'outline'}
	>
		<FileText class="mr-1 {ICON_CLASS_DEFAULT}" />
		{fText('message71988c4d8e08')}
	</Button>

	<Button
		disabled={pdfImagesLoading}
		onclick={() => (pdfViewMode = PdfViewMode.PAGES)}
		size="sm"
		variant={pdfViewMode === PdfViewMode.PAGES ? 'default' : 'outline'}
	>
		{#if pdfImagesLoading}
			<div
				class="mr-1 {ICON_CLASS_DEFAULT} animate-spin rounded-full border-2 border-current border-t-transparent"
			></div>
		{:else}
			<Eye class="mr-1 {ICON_CLASS_DEFAULT}" />
		{/if}
		{fText('message9046da16aea9')}
	</Button>
</div>

{#if !hasVisionModality && activeModelId && currentItem}
	<Alert.Root class="mb-4 max-w-4xl">
		<Info class={ICON_CLASS_DEFAULT} />

		<Alert.Title>{fText('message3673f9c181ba')}</Alert.Title>

		<Alert.Description>
			<span class="inline-flex">
				{fText('message7d2b2a1b79ad')}
				<!-- svelte-ignore a11y_click_events_have_key_events -->
				<!-- svelte-ignore a11y_no_static_element_interactions -->
				<span
					class="mx-1 cursor-pointer underline"
					onclick={() => (pdfViewMode = PdfViewMode.TEXT)}
				>
					{fText('message982d9e3eb996')}
				</span>
				{fText('message030cfd60beee')}
			</span>
		</Alert.Description>
	</Alert.Root>
{/if}

{#if pdfImagesLoading}
	<div class="flex flex-1 items-center justify-center p-8">
		<div class="text-center">
			<div
				class="mx-auto mb-4 h-8 w-8 animate-spin rounded-full border-4 border-white border-t-transparent"
			></div>

			<p class="text-white/70">{fText('messagecef551a7cb0f')}</p>
		</div>
	</div>
{:else if pdfImagesError}
	<div class="flex flex-1 items-center justify-center p-8">
		<div class="text-center">
			<FileText class="mx-auto mb-4 h-16 w-16 text-white/50" />

			<p class="mb-4 text-white/70">{fText('messagee6728ce51717')}</p>

			<p class="text-sm text-white/50">{pdfImagesError}</p>
		</div>
	</div>
{:else if pdfImages.length > 0}
	{#each pdfImages as image, index (image)}
		<p class="mb-2 text-sm text-white/50">{fText('messagedfeb8707a5c4', { p0: index + 1 })}</p>

		<img
			alt={fText('message6ff607e169d0', { p0: index + 1 })}
			class="mx-auto max-w-[85vw] rounded-lg shadow-lg"
			src={image}
		/>

		<div class="h-4"></div>
	{/each}
{:else}
	<div class="flex flex-1 items-center justify-center p-8">
		<div class="text-center">
			<FileText class="mx-auto mb-4 h-16 w-16 text-white/50" />

			<p class="text-white/70">{fText('message35ccf4acfc40')}</p>
		</div>
	</div>
{/if}

{#if pdfViewMode === PdfViewMode.TEXT && displayTextContent}
	<div class="px-4 pb-4">
		<SyntaxHighlightedCode
			class="max-w-4xl"
			code={displayTextContent}
			{language}
			maxHeight="none"
		/>
	</div>
{/if}
