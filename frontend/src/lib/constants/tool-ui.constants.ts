// Registry of server and browser tools whose renderer
// shows a recognizable icon and friendly label inline in the chat UI.
//
// To add a new tool, add an entry to TOOL_UI. To give a
// tool a custom title or body renderer, add a dedicated component under
// ChatMessageToolCall/ and route it in ChatMessageToolCallBlock.svelte
// (see ChatMessageToolCallBlockGetDatetime and
// ChatMessageToolCallBlockSearchResults for prior art).

import {
	Braces,
	Clock,
	Eye,
	FilePen,
	FilePlus,
	FileSearch,
	FileText,
	Info,
	SearchCode,
	Terminal
} from '@lucide/svelte';
import { BuiltInTool, ToolSource } from '$lib/enums';
import type { ToolUiEntry } from '$lib/types';
import { fText } from '$lib/i18n';

export const TOOL_UI: Readonly<Record<BuiltInTool, ToolUiEntry>> = {
	[BuiltInTool.BROWSER_GET_DATETIME]: {
		icon: Clock,
		label: fText('message06dafda7802b'),
		source: ToolSource.BROWSER
	},
	[BuiltInTool.BROWSER_READ_MEDIA]: { icon: Eye, label: fText('messageaa4c7701ac82'), source: ToolSource.BROWSER },
	[BuiltInTool.BROWSER_RUN_JAVASCRIPT]: {
		icon: Braces,
		label: fText('message9c90cb6e8c27'),
		source: ToolSource.BROWSER
	},
	[BuiltInTool.SERVER_EDIT_FILE]: { icon: FilePen, label: fText('message9608dd142d9b'), source: ToolSource.SERVER },
	[BuiltInTool.SERVER_EXEC_SHELL_COMMAND]: {
		icon: Terminal,
		label: fText('message87e30f34875f'),
		source: ToolSource.SERVER
	},
	[BuiltInTool.SERVER_FILE_GLOB_SEARCH]: {
		icon: FileSearch,
		label: fText('message179fed85ec50'),
		source: ToolSource.SERVER
	},
	[BuiltInTool.SERVER_GET_INFO]: { icon: Info, label: fText('message0bc0f77ade2d'), source: ToolSource.SERVER },
	[BuiltInTool.SERVER_GREP_SEARCH]: {
		icon: SearchCode,
		label: fText('message5fcd436a8042'),
		source: ToolSource.SERVER
	},
	[BuiltInTool.SERVER_READ_FILE]: { icon: FileText, label: fText('message47659c3dccc8'), source: ToolSource.SERVER },
	[BuiltInTool.SERVER_WRITE_FILE]: {
		icon: FilePlus,
		label: fText('message997357233881'),
		source: ToolSource.SERVER
	}
} as const;
