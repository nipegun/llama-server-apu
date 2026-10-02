import { fText } from '$lib/i18n';

/**
 * Labels shown while a model loads, keyed by the stage reported on /models/sse.
 */
export const MODEL_LOAD_STAGE_LABELS: Record<ApiModelLoadStage, string> = {
	mmproj_model: fText('messaged5b1c506a74f'),
	spec_model: fText('message5af36567f9a9'),
	text_model: fText('message6996f21952a8')
};

/**
 * Share of the bar reserved for each load phase after text_model.
 * text_model fills the rest, so a plain model reaches 100% on its own.
 */
export const MODEL_LOAD_TAIL_SHARE = 0.1;
