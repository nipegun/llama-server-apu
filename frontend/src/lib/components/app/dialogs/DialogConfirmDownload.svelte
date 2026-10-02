<script lang="ts">
  import { fText } from '$lib/i18n';
	import DialogConfirmation from '$lib/components/app/dialogs/DialogConfirmation.svelte';
	import { ModelDownloadConfirmAction } from '$lib/enums';
	import { modelsStore } from '$lib/stores';

	interface Props {
		/** Action being confirmed; drives the wording. */
		action: ModelDownloadConfirmAction;
		/** `<repo>:<tag>` the action targets. */
		repoWithTag: string;
		onClose: () => void;
		/** Overrides the default store removal; defaults to removing the entry. */
		onConfirm?: (repoWithTag: string) => void;
		open?: boolean;
	}

	let { action, onClose, onConfirm, open = true, repoWithTag }: Props = $props();

	// Both actions resolve through the same store removal (cancelDownload drops a
	// running download's partial files or a cached model's files); only the copy
	// differs. One component so the discover chips and the selector rows word the
	// destructive confirmations identically.
	const COPY = {
		[ModelDownloadConfirmAction.CANCEL]: {
			cancelText: fText('messagebe6565b33105'),
			confirmText: fText('messagede5b23e69cd1'),
			description: (name: string) =>
				fText('messagefd8c601398d8', { p0: name }),
			title: fText('messagede5b23e69cd1')
		},
		[ModelDownloadConfirmAction.DELETE]: {
			cancelText: fText('messagefa43d6c822b5'),
			confirmText: fText('messagee2d0a54968ea'),
			description: (name: string) =>
				fText('message9ce500fdb05c', { p0: name }),
			title: fText('messageb7828ba00ee1')
		}
	} as const;

	let copy = $derived(COPY[action]);
	let displayName = $derived(modelsStore.toDisplayName(repoWithTag));

	function confirm() {
		if (onConfirm) onConfirm(repoWithTag);
		else void modelsStore.status.cancelDownload(repoWithTag);

		onClose();
	}
</script>

<DialogConfirmation
	cancelText={copy.cancelText}
	confirmText={copy.confirmText}
	description={copy.description(displayName)}
	onCancel={onClose}
	onConfirm={confirm}
	{open}
	title={copy.title}
	variant="destructive"
/>
