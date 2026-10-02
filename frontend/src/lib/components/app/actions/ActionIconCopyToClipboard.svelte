<script lang="ts">
  import { fText } from '$lib/i18n';
	import ActionIcon from './ActionIcon.svelte';
	import { Copy } from '@lucide/svelte';
	import { ICON_CLASS_DEFAULT } from '$lib/constants';
	import { copyToClipboard } from '$lib/utils';

	export let ariaLabel: string = fText('messageb749e205302c');
	export let canCopy: boolean = true;
	export let text: string;
</script>

<ActionIcon
	disabled={!canCopy}
	icon={Copy}
	iconSize={ICON_CLASS_DEFAULT}
	onclick={() => canCopy && copyToClipboard(text)}
	tooltip={ariaLabel}
/>
