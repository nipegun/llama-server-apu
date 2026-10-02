<script lang="ts">
  import { fText } from '$lib/i18n';
	import { parseReadMediaMeta } from './parsers/read-media';
	import ToolCallBlock from './ToolCallBlock.svelte';
	import { ATTACHMENT_SAVED_REGEX } from '$lib/constants/agentic.constants';
	import { AttachmentType, MimeTypeAudio } from '$lib/enums';
	import type { DatabaseMessageExtraAudioFile, DatabaseMessageExtraImageFile } from '$lib/types';
	import type { AgenticSection } from '$lib/types';
	import { createBase64DataUrl } from '$lib/utils/data-url';

	interface Props {
		section: AgenticSection;
		open: boolean;
		isStreaming: boolean;
		onToggle?: () => void;
	}

	let { isStreaming, onToggle, open, section }: Props = $props();

	const readMediaMeta = $derived(parseReadMediaMeta(section));

	// extractBase64Attachments swapped the data URI line for [Attachment saved: name]
	// and moved the bytes to the message extras, so the name is the only link back
	const mediaAttachment = $derived.by(() => {
		const extras = section.toolResultExtras;

		if (!extras || extras.length === 0) return null;

		const match = section.toolResult?.match(ATTACHMENT_SAVED_REGEX);

		if (!match) return null;

		const attachmentName = match[1];

		return (
			extras.find(
				(e): e is DatabaseMessageExtraImageFile | DatabaseMessageExtraAudioFile =>
					(e.type === AttachmentType.IMAGE || e.type === AttachmentType.AUDIO) &&
					e.name === attachmentName
			) ?? null
		);
	});

	const audioMimeType = $derived(readMediaMeta?.mimeType ?? MimeTypeAudio.MP3_MPEG);
</script>

<ToolCallBlock {isStreaming} meta={readMediaMeta} {onToggle} {open} {section}>
	{#snippet titleSnippet()}
		<span class="flex min-w-0 flex-wrap items-baseline gap-x-1">
			<span class="shrink-0 text-muted-foreground">{fText('messageaa4c7701ac82')}</span>

			<span class="min-w-0 overflow-x-auto font-mono">{readMediaMeta?.fileName}</span>
		</span>
	{/snippet}

	{#snippet children(_meta, _ctx)}
		{#if section.toolResult}
			{#if !mediaAttachment}
				<div class="rounded bg-muted/20 p-2 text-xs text-muted-foreground/70 italic">
					{fText('message1b5ee78006e8')}
				</div>
			{:else if mediaAttachment.type === AttachmentType.AUDIO}
				<div class="mt-2">
					<audio class="w-full rounded-lg" controls>
						<source
							src={createBase64DataUrl(audioMimeType, mediaAttachment.base64Data)}
							type={audioMimeType}
						/>
						{fText('messagea21b58ba4c2f')}
					</audio>
				</div>
			{:else}
				<div class="mt-2">
					<img
						alt={readMediaMeta?.fileName ?? fText('message721c9525ade2')}
						class="max-h-[60vh] max-w-full rounded-lg object-contain shadow-lg"
						loading="lazy"
						src={mediaAttachment.base64Url}
					/>
				</div>
			{/if}

			{#if readMediaMeta?.sizeBytes || readMediaMeta?.mimeType}
				<div class="mt-2 flex gap-4 text-xs text-muted-foreground">
					{#if readMediaMeta?.sizeBytes}
						<span>{fText('message094322787127', { p0: readMediaMeta.sizeBytes })}</span>
					{/if}

					{#if readMediaMeta?.mimeType}
						<span>MIME: {readMediaMeta.mimeType}</span>
					{/if}
				</div>
			{/if}

			{#if readMediaMeta?.path}
				<div class="mt-1 font-mono text-xs text-muted-foreground/60">{readMediaMeta.path}</div>
			{/if}
		{:else}
			<div class="rounded bg-muted/20 p-2 text-xs text-muted-foreground/70 italic">
				{fText('messaged226fe2dd9b7')}
			</div>
		{/if}
	{/snippet}
</ToolCallBlock>
