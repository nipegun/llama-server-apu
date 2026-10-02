<script lang="ts">
  import { fText } from '$lib/i18n';
	import { ArrowDown } from '@lucide/svelte';
	import ActionIcon from '$lib/components/app/actions/ActionIcon.svelte';
	import { ICON_CLASS_DEFAULT } from '$lib/constants';

	let { onclick }: { onclick: (e?: MouseEvent) => void } = $props();
</script>

<div class="pointer-events-auto flex justify-center relative h-0">
	<ActionIcon
		ariaLabel={fText('message6a36c1b26f1c')}
		class="h-9 w-9 rounded-full bg-muted/60 border border-border/20 shadow-sm text-accent-foreground absolute bottom-4"
		icon={ArrowDown}
		iconSize={ICON_CLASS_DEFAULT}
		{onclick}
		size="lg"
		tooltip={fText('message6a36c1b26f1c')}
	/>
</div>
