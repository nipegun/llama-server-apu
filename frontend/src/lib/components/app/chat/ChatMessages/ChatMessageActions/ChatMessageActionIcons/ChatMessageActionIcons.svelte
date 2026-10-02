<script lang="ts">
  import { fText } from '$lib/i18n';
	import { ArrowRight, Copy, Edit, GitBranch, RefreshCw, Trash2 } from '@lucide/svelte';
	import {
		ActionIcon,
		ChatMessageActionIconsBranchingControls,
		DialogConfirmation
	} from '$lib/components/app';
	import { Checkbox } from '$lib/components/ui/checkbox';
	import Input from '$lib/components/ui/input/input.svelte';
	import Label from '$lib/components/ui/label/label.svelte';
	import { Switch } from '$lib/components/ui/switch';
	import { getChatMessageActionsContext, getChatMessageEditContext } from '$lib/contexts';
	import { MessageRole } from '$lib/enums';
	import { conversationsStore } from '$lib/stores';

	interface Props {
		role: MessageRole.USER | MessageRole.ASSISTANT;
		justify: 'start' | 'end';
		actionsPosition: 'left' | 'right';
		onRegenerate?: () => void;
		onContinue?: () => void;
		showRawOutputSwitch?: boolean;
		rawOutputEnabled?: boolean;
		onRawOutputToggle?: (enabled: boolean) => void;
	}

	let {
		actionsPosition,
		justify,
		onContinue,
		onRawOutputToggle,
		onRegenerate,
		rawOutputEnabled = false,
		role,
		showRawOutputSwitch = false
	}: Props = $props();

	const messageActions = getChatMessageActionsContext();
	const editCtx = getChatMessageEditContext();

	let showForkDialog = $state(false);
	let forkName = $state('');
	let forkIncludeAttachments = $state(true);

	function handleConfirmDelete() {
		messageActions.confirmDelete();
		messageActions.setShowDeleteDialog(false);
	}

	function handleOpenForkDialog() {
		const conv = conversationsStore.activeConversation;

		forkName = fText('message205e60607abc', { p0: conv?.name ?? fText('messageccca18175753') });
		forkIncludeAttachments = true;
		showForkDialog = true;
	}

	function handleConfirmFork() {
		messageActions.forkConversation?.({
			includeAttachments: forkIncludeAttachments,
			name: forkName.trim()
		});
		showForkDialog = false;
	}
</script>

<div class="relative {justify === 'start' ? 'mt-2' : ''} flex h-6 items-center justify-between">
	<div
		class="{actionsPosition === 'left'
			? 'left-0'
			: 'right-0'} flex items-center gap-2 opacity-100 transition-opacity"
	>
		{#if messageActions.siblingInfo && messageActions.siblingInfo.totalSiblings > 1}
			<ChatMessageActionIconsBranchingControls />
		{/if}

		<div
			class="pointer-events-auto inset-0 flex items-center gap-1 opacity-100 transition-all duration-150"
		>
			<ActionIcon icon={Copy} onclick={messageActions.copy} tooltip={fText('messagee21f935f11d7')} />

			<ActionIcon icon={Edit} onclick={editCtx.startEdit} tooltip={fText('message464c4ffd019e')} />

			{#if role === MessageRole.ASSISTANT && onRegenerate}
				<ActionIcon icon={RefreshCw} onclick={() => onRegenerate()} tooltip={fText('message1651031bf58d')} />
			{/if}

			{#if role === MessageRole.ASSISTANT && onContinue}
				<ActionIcon icon={ArrowRight} onclick={onContinue} tooltip={fText('message31fbef162594')} />
			{/if}

			{#if messageActions.forkConversation}
				<ActionIcon icon={GitBranch} onclick={handleOpenForkDialog} tooltip={fText('message0e5f7f6732e0')} />
			{/if}

			<ActionIcon icon={Trash2} onclick={messageActions.requestDelete} tooltip={fText('messagee2d0a54968ea')} />
		</div>
	</div>

	{#if showRawOutputSwitch}
		<div class="flex items-center gap-2">
			<span class="text-xs text-muted-foreground">{fText('message31d5cb1cf038')}</span>

			<Switch
				checked={rawOutputEnabled}
				onCheckedChange={(checked) => onRawOutputToggle?.(checked)}
			/>
		</div>
	{/if}
</div>

<DialogConfirmation
	cancelText={fText('message19766ed6ccb2')}
	confirmText={messageActions.deletionInfo && messageActions.deletionInfo.totalCount > 1
		? fText('message5b5338fe8b24', { p0: messageActions.deletionInfo.totalCount })
		: fText('messagee2d0a54968ea')}
	description={messageActions.deletionInfo && messageActions.deletionInfo.totalCount > 1
		? fText('message9c6b7e82eb81', { p0: messageActions.deletionInfo.totalCount, p1: messageActions.deletionInfo.userMessages, p2: messageActions.deletionInfo.userMessages > 1 ? 's' : '', p3: messageActions.deletionInfo.assistantMessages, p4: messageActions.deletionInfo.assistantMessages > 1 ? 's' : '' })
		: fText('message24e7dc980667')}
	icon={Trash2}
	onCancel={() => messageActions.setShowDeleteDialog(false)}
	onConfirm={handleConfirmDelete}
	open={messageActions.showDeleteDialog}
	title={fText('message43e94c3cb95e')}
	variant="destructive"
/>

<DialogConfirmation
	bind:open={showForkDialog}
	cancelText={fText('message19766ed6ccb2')}
	confirmText={fText('message8e5b1a73152c')}
	description={fText('message5af90254c54e')}
	icon={GitBranch}
	onCancel={() => (showForkDialog = false)}
	onConfirm={handleConfirmFork}
	title={fText('message84b04588e14c')}
>
	<div class="flex flex-col gap-4 py-2">
		<div class="flex flex-col gap-2">
			<Label for="fork-name">{fText('message7e8cd2056da7')}</Label>

			<Input
				bind:value={forkName}
				class="text-foreground"
				id="fork-name"
				placeholder={fText('message1be3523505c4')}
				type="text"
			/>
		</div>

		<div class="flex items-center gap-2">
			<Checkbox
				checked={forkIncludeAttachments}
				id="fork-attachments"
				onCheckedChange={(checked) => {
					forkIncludeAttachments = checked === true;
				}}
			/>

			<Label class="cursor-pointer text-sm font-normal" for="fork-attachments">
				{fText('messagec159fa23ee8e')}
			</Label>
		</div>
	</div>
</DialogConfirmation>
