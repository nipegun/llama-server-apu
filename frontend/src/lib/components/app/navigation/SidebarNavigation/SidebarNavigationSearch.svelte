<script lang="ts">
  import { fText } from '$lib/i18n';
	import { SearchInput } from '$lib/components/app';

	interface Props {
		value?: string;
		placeholder?: string;
		onInput?: (value: string) => void;
		class?: string;
	}

	let {
		class: className,
		onInput,
		placeholder = fText('messagee90dd0173105'),
		value = $bindable('')
	}: Props = $props();
</script>

<div class="mb-4 px-2 {className}">
	<SearchInput bind:value {onInput} {placeholder} />
</div>
