<script lang="ts">
  import { fText } from '$lib/i18n';
	import { Music } from '@lucide/svelte';

	interface Props {
		currentItem: { name?: string } | null;
		audioSrc: string | null;
	}

	let { audioSrc, currentItem }: Props = $props();
</script>

<div class="flex flex-1 items-center justify-center p-8">
	<div class="w-full max-w-md text-center">
		<Music class="mx-auto mb-4 h-16 w-16 text-white/50" />

		{#if audioSrc}
			<audio class="mb-4 w-full" controls src={audioSrc}>
				{fText('messagea21b58ba4c2f')}
			</audio>
		{:else}
			<p class="mb-4 text-white/70">{fText('messageb4fa97f78aa1')}</p>
		{/if}

		<p class="text-sm text-white/50">{currentItem?.name || fText('messagebc1b88907d3b')}</p>
	</div>
</div>
