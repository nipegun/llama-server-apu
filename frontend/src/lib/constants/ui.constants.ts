import { Package, Search, Settings, SquarePen } from '@lucide/svelte';
import { SidebarAction, ToolSource } from '$lib/enums';
import type { DesktopIconStripItem } from '$lib/types';
import { fText } from '$lib/i18n';

export const FORK_TREE_DEPTH_PADDING = 8;
export const SYSTEM_MESSAGE_PLACEHOLDER = fText('messagee066e37463a8');

/** Data attributes for app-level DOM contracts. */
export const UI_DATA_ATTRS = {
	ACTIVE: 'data-active',
	ACTIVE_TAB: 'data-active-tab',
	CONVERSATION_ROW: 'data-conversation-row',
	HIGHLIGHT_THEME_PREVIEW: 'data-highlight-theme-preview',
	PICKER_INDEX: 'data-picker-index',
	RESULT_INDEX: 'data-result-index',
	THUMBNAIL_INDEX: 'data-thumbnail-index'
} as const;

export const TOOL_GROUP_LABELS = {
	[ToolSource.BROWSER]: fText('messaged31de1a5c5c8'),
	[ToolSource.CUSTOM]: fText('message13a8f29ba149'),
	[ToolSource.SERVER]: fText('messageaef7de28d529')
} as const;

export const TOOL_SERVER_LABELS = {
	[ToolSource.BROWSER]: fText('messagec78befadef32'),
	[ToolSource.CUSTOM]: fText('message2304e587b23b'),
	[ToolSource.SERVER]: fText('messagee3ac1ee0f8b3')
} as const;

export const TOOLTIP_DELAY_DURATION = 500;

export const VIEWPORT_GUTTER = 8;
export const MENU_OFFSET = 6;

export const PROCESSING_INFO_TIMEOUT = 2000;

/**
 * Statistics units labels
 */
export const STATS_UNITS = {
	TOKENS_PER_SECOND: 't/s'
} as const;

export const DEFAULT_MOBILE_BREAKPOINT = 768;

/** Orgs whose avatar is dark and needs inverting in dark mode. */
export const DARK_INVERT_AVATAR_ORGS = ['openai'];

/** Icon used for the model selector and the `/model` slash command. */
export const MODEL_SELECTOR_ICON = Package;

export const ICON_STRIP_TRANSITION_DURATION = 150;
export const ICON_STRIP_TRANSITION_DELAY_MULTIPLIER = 50;

/** Max height for tool-result code blocks (json / source / diff / streaming code). */
export const MAX_HEIGHT_CODE_BLOCK = '22rem';

export const SIDEBAR_ACTIONS_ITEMS: DesktopIconStripItem[] = [
	{
		action: SidebarAction.NEW_CHAT,
		icon: SquarePen,
		keys: ['shift', 'cmd', 'o'],
		tooltip: fText('messagedb18382a249e')
	},
	{ icon: Search, keys: ['cmd', 'k'], tooltip: fText('message49c266baaaa7') },
	{
		action: SidebarAction.SETTINGS,
		icon: Settings,
		tooltip: fText('message74a883a037bc')
	}
];
