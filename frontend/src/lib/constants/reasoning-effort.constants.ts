import { ReasoningEffort } from '$lib/enums';
import type { ReasoningEffortLevel } from '$lib/types';
import { fText } from '$lib/i18n';

/**
 * Reasoning effort UI labels.
 * Keys match the ReasoningEffort enum values for type-safe lookups.
 */
export const REASONING_EFFORT_LABELS: Record<string, string> = {
	[ReasoningEffort.DEFAULT]: fText('message21b111cbfe6e'),
	[ReasoningEffort.HIGH]: fText('messagec4ebc6d4a583'),
	[ReasoningEffort.LOW]: fText('messagef793de205ead'),
	[ReasoningEffort.MAX]: fText('messagea1a5936d3b0f'),
	[ReasoningEffort.MEDIUM]: fText('message8e588cd18774'),
	[ReasoningEffort.OFF]: fText('messageca7981b46ecf')
};

export const REASONING_EFFORT_LEVELS: ReasoningEffortLevel[] = [
	{ label: fText('message21b111cbfe6e'), value: ReasoningEffort.DEFAULT },
	{ label: fText('messageca7981b46ecf'), value: ReasoningEffort.OFF },
	{ label: fText('messagef793de205ead'), value: ReasoningEffort.LOW },
	{ label: fText('message8e588cd18774'), value: ReasoningEffort.MEDIUM },
	{ label: fText('messagec4ebc6d4a583'), value: ReasoningEffort.HIGH },
	{ hasInfo: true, label: fText('messagea1a5936d3b0f'), value: ReasoningEffort.MAX }
];

/**
 * Reasoning effort to token budget mapping.
 * Maps the ReasoningEffort enum values to concrete token counts for the server.
 */
export const REASONING_EFFORT_TOKENS: Record<string, number> = {
	[ReasoningEffort.HIGH]: 8192,
	[ReasoningEffort.LOW]: 512,
	[ReasoningEffort.MAX]: -1, // unlimited
	[ReasoningEffort.MEDIUM]: 2048
};
