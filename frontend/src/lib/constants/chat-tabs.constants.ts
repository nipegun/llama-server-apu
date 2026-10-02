import { fText } from '$lib/i18n';

/** Sentinel tab id for the bare `#/` new-chat screen */
export const NEW_CHAT_TAB_ID = 'new-chat';

/** Label shown for the new-chat sentinel tab. */
export const NEW_CHAT_LABEL = fText('messagedb18382a249e');

/** Fallback label for conversations without an auto-generated title. */
export const UNNAMED_CHAT_LABEL = fText('message460b3a7da007');

/**
 * Tab bar max width so it stays clear of the sidebar strip. The expanded strip
 * is `md:w-72` and the collapsed one `md:w-12`; these hold the fully tuned
 * `max-w-[calc(100vw-?rem)]` classes so the offset has a single source.
 */
export const CHAT_TABS_MAX_WIDTH = {
	COLLAPSED_SIDEBAR: 'max-w-[calc(100vw-5rem)]',
	EXPANDED_SIDEBAR: 'max-w-[calc(100vw-20rem)]'
} as const;
