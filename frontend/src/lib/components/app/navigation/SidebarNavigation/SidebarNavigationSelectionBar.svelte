<script lang="ts">
  import { fText } from '$lib/i18n';
	import { Download, Pin, PinOff, Trash2, X } from '@lucide/svelte';
	import { ActionIcon, DialogConfirmation } from '$lib/components/app';
	import { Checkbox } from '$lib/components/ui/checkbox';
	import { TooltipSide } from '$lib/enums';

	interface Props {
		class?: string;
		selectedCount: number;
		visibleCount: number;
		allVisibleSelected: boolean;
		someVisibleSelected: boolean;
		someSelectedPinned: boolean;
		pinStateIsMixed: boolean;
		onSelectAllToggle: () => void;
		onBulkPinToggle: () => void;
		onBulkExport: () => void;
		onBulkDelete: () => void;
		onClose: () => void;
	}

	let {
		allVisibleSelected,
		class: className = '',
		onBulkDelete,
		onBulkExport,
		onBulkPinToggle,
		onClose,
		onSelectAllToggle,
		pinStateIsMixed,
		selectedCount,
		someSelectedPinned,
		someVisibleSelected,
		visibleCount
	}: Props = $props();

	let showDeleteDialog = $state(false);

	function handleDeleteClick() {
		showDeleteDialog = true;
	}

	function handleDeleteConfirm() {
		showDeleteDialog = false;
		onBulkDelete();
	}

	function handleDeleteCancel() {
		showDeleteDialog = false;
	}

	const hasSelection = $derived(selectedCount > 0);
	const isMasterChecked = $derived(allVisibleSelected);
	const isMasterIndeterminate = $derived(!allVisibleSelected && someVisibleSelected);

	const pinTooltip = $derived(
		hasSelection
			? pinStateIsMixed
				? fText('message4a59b87acd7e')
				: someSelectedPinned
					? selectedCount === 1
						? fText('messageee3c71613054')
						: fText('messagebb444562d616')
					: selectedCount === 1
						? fText('messageff1cee744146')
						: fText('message81f50d740fb5')
			: fText('messageff1cee744146')
	);

	const pinDisabled = $derived(!hasSelection || pinStateIsMixed);
</script>

<div
	aria-label={fText('message5667f96ffb3d')}
	class="flex items-center gap-1.5 rounded-xl border border-border/50 bg-background/50 px-2 py-1.5 shadow-sm backdrop-blur-xl {className}"
	role="toolbar"
>
	<label class="flex min-w-0 cursor-pointer items-center gap-2">
		<Checkbox
			aria-label={isMasterChecked ? fText('message967549497036') : fText('message1fc9a387654d')}
			checked={isMasterChecked}
			indeterminate={isMasterIndeterminate}
			onCheckedChange={onSelectAllToggle}
		/>

		<span class="truncate text-xs font-medium text-muted-foreground">
			{selectedCount} / {visibleCount} {fText('messaged7cbbb688b2e')}
		</span>
	</label>

	<div class="ml-auto flex items-center gap-0.75">
		<ActionIcon
			ariaLabel={pinTooltip}
			class="h-7 w-7 rounded-md bg-transparent backdrop-blur-none hover:bg-accent! {pinDisabled
				? 'cursor-not-allowed'
				: ''} {!pinDisabled ? 'opacity-100' : 'opacity-40'}"
			disabled={pinDisabled}
			icon={someSelectedPinned ? PinOff : Pin}
			iconSize="h-3.5 w-3.5"
			onclick={onBulkPinToggle}
			size="sm"
			tooltip={pinTooltip}
			tooltipSide={TooltipSide.TOP}
		/>

		<ActionIcon
			ariaLabel={fText('messageac909944b8b3')}
			class="h-7 w-7 rounded-md bg-transparent backdrop-blur-none hover:bg-accent! {hasSelection
				? 'opacity-100'
				: 'opacity-40'}"
			disabled={!hasSelection}
			icon={Download}
			iconSize="h-3.5 w-3.5"
			onclick={onBulkExport}
			size="sm"
			tooltip={hasSelection ? fText('message3664895579f0') : fText('message3664895579f0')}
			tooltipSide={TooltipSide.TOP}
		/>

		<ActionIcon
			ariaLabel={fText('messaged2ab5d46fed4')}
			class="h-7 w-7 rounded-md bg-transparent backdrop-blur-none hover:bg-destructive/10! dark:hover:bg-destructive/20! disabled:hover:bg-transparent {hasSelection
				? 'opacity-100'
				: 'opacity-40'}"
			disabled={!hasSelection}
			icon={Trash2}
			iconSize="h-3.5 w-3.5 text-destructive"
			onclick={handleDeleteClick}
			size="sm"
			tooltip={fText('messaged2ab5d46fed4')}
			tooltipSide={TooltipSide.TOP}
		/>

		<div aria-hidden="true" class="mx-1 h-4 w-px bg-border"></div>

		<ActionIcon
			ariaLabel={fText('message0a6603b65249')}
			class="h-7 w-7 rounded-md bg-transparent backdrop-blur-none hover:bg-accent!"
			icon={X}
			iconSize="h-3.5 w-3.5"
			onclick={onClose}
			size="sm"
			tooltip={fText('message0a6603b65249')}
			tooltipSide={TooltipSide.TOP}
		/>
	</div>
</div>

<DialogConfirmation
	bind:open={showDeleteDialog}
	cancelText={fText('message19766ed6ccb2')}
	confirmText={selectedCount === 1 ? fText('messagee2d0a54968ea') : fText('message0ae262c71c03', { p0: selectedCount })}
	description={selectedCount === 1
		? fText('message81148466184c')
		: fText('messagefb478a1bdb8e')}
	icon={Trash2}
	onCancel={handleDeleteCancel}
	onConfirm={handleDeleteConfirm}
	title={selectedCount === 1
		? fText('message58af88f54012')
		: fText('messagee21fd5da1b55', { p0: selectedCount })}
	variant="destructive"
/>
