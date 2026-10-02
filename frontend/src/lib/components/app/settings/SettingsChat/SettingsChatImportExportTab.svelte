<script lang="ts">
  import { fText } from '$lib/i18n';
	import SettingsChatImportExportSection from './SettingsChatImportExportSection.svelte';
	import { Download, Trash2, Upload } from '@lucide/svelte';
	import {
		DialogConfirmation,
		DialogConversationSelection,
		DialogExportSettings
	} from '$lib/components/app';
	import SettingsGroup from '$lib/components/app/settings/SettingsGroup.svelte';
	import { ConversationSelectionMode, FileExtensionText, HtmlInputType } from '$lib/enums';
	import { ConversationTransferService } from '$lib/services';
	import { conversationsStore, settingsStore } from '$lib/stores';
	import { createMessageCountMap } from '$lib/utils';
	import { fade } from 'svelte/transition';
	import { toast } from 'svelte-sonner';

	let exportedConversations = $state<DatabaseConversation[]>([]);
	let importedConversations = $state<DatabaseConversation[]>([]);
	let showExportSummary = $state(false);
	let showImportSummary = $state(false);

	let showExportDialog = $state(false);
	let showImportDialog = $state(false);
	let availableConversations = $state<DatabaseConversation[]>([]);
	let messageCountMap = $state<Map<string, number>>(new Map());
	let fullImportData = $state<Array<{ conv: DatabaseConversation; messages: DatabaseMessage[] }>>(
		[]
	);

	// Delete functionality state
	let showDeleteDialog = $state(false);

	// Settings import/export state
	let showSettingsExportSummary = $state(false);
	let showSettingsImportSummary = $state(false);
	let showSettingsExportDialog = $state(false);
	let includeSensitiveData = $state(false);

	function handleSettingsExport() {
		showSettingsExportDialog = true;
		includeSensitiveData = false;
	}

	function handleSettingsExportConfirm() {
		showSettingsExportDialog = false;

		try {
			const data = settingsStore.exportSettings(includeSensitiveData);
			const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
			const url = URL.createObjectURL(blob);
			const a = document.createElement('a');

			a.href = url;
			a.download = `llama_settings_${new Date().toISOString().split('T')[0]}.json`;
			document.body.appendChild(a);
			a.click();
			document.body.removeChild(a);
			URL.revokeObjectURL(url);

			showSettingsExportSummary = true;
			showSettingsImportSummary = false;
			toast.success(fText('message5bfca92e998f'));
		} catch (err) {
			console.error('Failed to export settings:', err);
			toast.error(fText('message3cf664c4bd2b'));
		}
	}

	function handleSettingsExportCancel() {
		showSettingsExportDialog = false;
	}

	function handleSettingsImport() {
		try {
			const input = document.createElement('input');

			input.type = HtmlInputType.FILE;
			input.accept = FileExtensionText.JSON;

			input.onchange = async (e) => {
				const file = (e.target as HTMLInputElement)?.files?.[0];

				if (!file) return;

				try {
					const text = await file.text();
					const data = JSON.parse(text);

					if (!data || typeof data !== 'object' || !data.config) {
						toast.error(fText('messagee65771eee330'));

						return;
					}

					settingsStore.importSettings(data);

					showSettingsImportSummary = true;
					showSettingsExportSummary = false;
					toast.success(fText('messagef3addd823e40'));
				} catch (err) {
					console.error('Failed to import settings:', err);
					toast.error(fText('message6ffd4b51379f'));
				}
			};

			input.click();
		} catch (err) {
			console.error('Failed to open file picker:', err);
			toast.error(fText('message5843f72974fd'));
		}
	}

	async function handleExportClick() {
		try {
			const allConversations = conversationsStore.conversations;

			if (allConversations.length === 0) {
				toast.info(fText('messagebf0779e06dd8'));

				return;
			}

			const conversationsWithMessages = await Promise.all(
				allConversations.map(async (conv: DatabaseConversation) => {
					const messages = await conversationsStore.getConversationMessages(conv.id);

					return { conv, messages };
				})
			);

			messageCountMap = createMessageCountMap(conversationsWithMessages);
			availableConversations = allConversations;
			showExportDialog = true;
		} catch (err) {
			console.error('Failed to load conversations:', err);
			alert(fText('messageae55fc046c4c'));
		}
	}

	async function handleExportConfirm(selectedConversations: DatabaseConversation[]) {
		try {
			const allData = await conversationsStore.getConversationsForExport(
				selectedConversations.map((conv) => conv.id)
			);

			if (allData.length === 1) {
				ConversationTransferService.downloadConversationFile(allData[0]);
			} else {
				ConversationTransferService.downloadConversationsArchive(allData);
			}

			exportedConversations = selectedConversations;
			showExportSummary = true;
			showImportSummary = false;
			showExportDialog = false;
		} catch (err) {
			console.error('Export failed:', err);
			alert(fText('message96f775dbb3fc'));
		}
	}

	async function handleImportClick() {
		try {
			const input = document.createElement('input');

			// No `accept` filter: iOS resolves each entry to a UTI and has none for
			// `.jsonl`, which greys out exported conversations in the file picker.
			// `parseImportFile` detects the format from the file contents instead.
			input.type = HtmlInputType.FILE;

			input.onchange = async (e) => {
				const file = (e.target as HTMLInputElement)?.files?.[0];

				if (!file) return;

				try {
					const importedData = await ConversationTransferService.parseImportFile(file);

					if (importedData.length === 0) {
						throw new Error(fText('message5db93832d23b'));
					}

					fullImportData = importedData;
					availableConversations = importedData.map((item) => item.conv);
					messageCountMap = createMessageCountMap(importedData);
					showImportDialog = true;
				} catch (err: unknown) {
					const message = err instanceof Error ? err.message : fText('message27c2ccd962c2');

					console.error('Failed to parse file:', err);
					alert(fText('message0d691e020bf8', { p0: message }));
				}
			};

			input.click();
		} catch (err) {
			console.error('Import failed:', err);
			alert(fText('messageebbdaaef4f97'));
		}
	}

	async function handleImportConfirm(selectedConversations: DatabaseConversation[]) {
		try {
			const selectedIds = new Set(selectedConversations.map((c) => c.id));
			const selectedData = $state
				.snapshot(fullImportData)
				.filter((item) => selectedIds.has(item.conv.id));
			const { imported, skipped } = await conversationsStore.importConversationsData(selectedData);

			// A conversation already in the database is left untouched, so the summary
			// lists what was written and the toast accounts for the rest.
			if (skipped.length > 0) {
				toast.info(
					skipped.length === 1
						? fText('messagefbd56914aa01')
						: fText('message2d198b42946d', { p0: skipped.length })
				);
			}

			importedConversations = imported;
			showImportSummary = true;
			showExportSummary = false;
			showImportDialog = false;
		} catch (err) {
			console.error('Import failed:', err);
			alert(fText('message1b082e402d1d'));
		}
	}

	async function handleDeleteAllClick() {
		try {
			const allConversations = conversationsStore.conversations;

			if (allConversations.length === 0) {
				toast.info(fText('message5c9a78a4a817'));

				return;
			}

			showDeleteDialog = true;
		} catch (err) {
			console.error('Failed to load conversations for deletion:', err);
			toast.error(fText('messageae55fc046c4c'));
		}
	}

	async function handleDeleteAllConfirm() {
		try {
			await conversationsStore.deleteAll();

			showDeleteDialog = false;
		} catch (err) {
			console.error('Failed to delete conversations:', err);
		}
	}

	function handleDeleteAllCancel() {
		showDeleteDialog = false;
	}
</script>

<div in:fade={{ duration: 150 }} class="space-y-12">
	<SettingsGroup title={fText('message1d432f58690c')}>
		<SettingsChatImportExportSection
			IconComponent={Download}
			buttonText={fText('messageb1eb55883f73')}
			description={fText('messagee1c29b8d7188')}
			onclick={handleExportClick}
			summary={{ items: exportedConversations, show: showExportSummary, verb: fText('message391065e4dc23') }}
			title={fText('message3664895579f0')}
		/>

		<SettingsChatImportExportSection
			IconComponent={Upload}
			buttonText={fText('message982025854bd5')}
			description={fText('messagea659626215c6')}
			onclick={handleImportClick}
			summary={{ items: importedConversations, show: showImportSummary, verb: fText('message321f179c80ba') }}
			title={fText('message2cff9baabf56')}
		/>

		<SettingsChatImportExportSection
			IconComponent={Trash2}
			buttonClass="text-destructive-foreground justify-start justify-self-start bg-destructive hover:bg-destructive/80 md:w-auto"
			buttonText={fText('message43a72ccf4424')}
			buttonVariant="destructive"
			description={fText('message21814f9e74f4')}
			onclick={handleDeleteAllClick}
			title={fText('messageef85afa1b92c')}
			titleClass="text-destructive"
		/>
	</SettingsGroup>

	<SettingsGroup title={fText('message74a883a037bc')}>
		<SettingsChatImportExportSection
			IconComponent={Download}
			buttonText={fText('message4431ea74c184')}
			description={fText('message72df65773b40')}
			onclick={handleSettingsExport}
			summary={{ items: [], show: showSettingsExportSummary, verb: fText('message391065e4dc23') }}
			title={fText('message3664895579f0')}
		/>

		<SettingsChatImportExportSection
			IconComponent={Upload}
			buttonText={fText('message72f01a736575')}
			description={fText('message6235faca5e63')}
			onclick={handleSettingsImport}
			summary={{ items: [], show: showSettingsImportSummary, verb: fText('message321f179c80ba') }}
			title={fText('message2cff9baabf56')}
		/>
	</SettingsGroup>
</div>

<DialogExportSettings
	bind:includeSensitiveData
	bind:open={showSettingsExportDialog}
	onCancel={handleSettingsExportCancel}
	onConfirm={handleSettingsExportConfirm}
/>

<DialogConversationSelection
	bind:open={showExportDialog}
	conversations={availableConversations}
	{messageCountMap}
	mode={ConversationSelectionMode.EXPORT}
	onCancel={() => (showExportDialog = false)}
	onConfirm={handleExportConfirm}
/>

<DialogConversationSelection
	bind:open={showImportDialog}
	conversations={availableConversations}
	{messageCountMap}
	mode={ConversationSelectionMode.IMPORT}
	onCancel={() => (showImportDialog = false)}
	onConfirm={handleImportConfirm}
/>

<DialogConfirmation
	bind:open={showDeleteDialog}
	cancelText={fText('message19766ed6ccb2')}
	confirmText={fText('messageef85afa1b92c')}
	description={fText('message45145fe2a7ce')}
	icon={Trash2}
	onCancel={handleDeleteAllCancel}
	onConfirm={handleDeleteAllConfirm}
	title={fText('message43a72ccf4424')}
	variant="destructive"
/>
