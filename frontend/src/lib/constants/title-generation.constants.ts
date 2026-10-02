import { fText } from '$lib/i18n';

/* Title generation constants */
export const TITLE_GENERATION = {
	DEFAULT_PROMPT: fText('message7ce80665d9f7'),
	FALLBACK: fText('message0d33235199fb'),
	MIN_LENGTH: 3,
	PREFIX_PATTERN: /^(Title:|Subject:|Topic:)\s*/i,
	QUOTE_PATTERN: /^["]|["]$/g
} as const;
