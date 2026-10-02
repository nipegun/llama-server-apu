<script lang="ts">
  import { fText } from '$lib/i18n';
	import { Eye } from '@lucide/svelte';
	import { ActionIcon, ActionIconCopyToClipboard } from '$lib/components/app';
	import { FileTypeText } from '$lib/enums';

	interface Props {
		code: string;
		language: string;
		disabled?: boolean;
		onPreview?: (code: string, language: string) => void;
	}

	let { code, disabled = false, language, onPreview }: Props = $props();

	const showPreview = $derived(language?.toLowerCase() === FileTypeText.HTML);
</script>

<div class="code-block-actions">
	<ActionIconCopyToClipboard
		ariaLabel={disabled ? fText('messageea6d26c39694') : fText('message49a0053f3b0d')}
		canCopy={!disabled}
		text={code}
	/>

	{#if showPreview}
		<ActionIcon
			{disabled}
			icon={Eye}
			onclick={() => onPreview!(code, language)}
			tooltip={disabled ? fText('messageea6d26c39694') : fText('message7e8611fc24e8')}
		/>
	{/if}
</div>
