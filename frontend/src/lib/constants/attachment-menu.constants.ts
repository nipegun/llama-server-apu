import { FILE_TYPE_ICONS } from '$lib/constants';
import { AttachmentAction, AttachmentItemEnabledWhen, AttachmentMenuItemId } from '$lib/enums';
import type { AttachmentMenuItem } from '$lib/types';
import { fText } from '$lib/i18n';

/**
 * File attachment menu items shown in both the desktop dropdown and mobile sheet.
 * The "Tools" submenu is handled separately by each component.
 */
export const ATTACHMENT_FILE_ITEMS: AttachmentMenuItem[] = [
	{
		action: AttachmentAction.FILE_UPLOAD,
		class: 'images-button',
		disabledTooltip: fText('messageda3986960d94'),
		enabledWhen: AttachmentItemEnabledWhen.HAS_VISION_MODALITY,
		icon: FILE_TYPE_ICONS.image,
		id: AttachmentMenuItemId.IMAGES,
		label: fText('messagebe7e2f201293')
	},
	{
		action: AttachmentAction.FILE_UPLOAD,
		class: 'audio-button',
		disabledTooltip: fText('message546305b42e63'),
		enabledWhen: AttachmentItemEnabledWhen.HAS_AUDIO_MODALITY,
		icon: FILE_TYPE_ICONS.audio,
		id: AttachmentMenuItemId.AUDIO,
		label: fText('message85b791f3241c')
	},
	{
		action: AttachmentAction.FILE_UPLOAD,
		class: 'video-button',
		disabledTooltip: fText('message01f526933484'),
		enabledWhen: AttachmentItemEnabledWhen.HAS_VIDEO_MODALITY,
		icon: FILE_TYPE_ICONS.video,
		id: AttachmentMenuItemId.VIDEO,
		label: fText('messagef1719b8182ad')
	},
	{
		action: AttachmentAction.FILE_UPLOAD,
		enabledWhen: AttachmentItemEnabledWhen.ALWAYS,
		icon: FILE_TYPE_ICONS.text,
		id: AttachmentMenuItemId.TEXT,
		label: fText('message58c701e56182')
	},
	{
		action: AttachmentAction.FILE_UPLOAD,
		disabledTooltip: fText('message24ab085b25ae'),
		enabledWhen: AttachmentItemEnabledWhen.ALWAYS,
		hasEnabledTooltip: true,
		icon: FILE_TYPE_ICONS.pdf,
		id: AttachmentMenuItemId.PDF,
		label: fText('messagefad030751fb1')
	}
];

export const ATTACHMENT_TOOLTIP_TEXT = fText('message413359146641');
