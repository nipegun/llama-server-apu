/**
 * File validation utilities based on model modalities
 * Ensures only compatible file types are processed based on model capabilities
 */

import { FileTypeCategory } from '$lib/enums';
import type { ModalityCapabilities } from '$lib/types';
import { getFileTypeCategory } from '$lib/utils';
import { fText } from '$lib/i18n';

/**
 * Check if a file type is supported by the given modalities
 * @param filename - The filename to check
 * @param mimeType - The MIME type of the file
 * @param capabilities - The modality capabilities to check against
 * @returns true if the file type is supported
 */
export function isFileTypeSupportedByModel(
	filename: string,
	mimeType: string | undefined,
	capabilities: ModalityCapabilities
): boolean {
	const category = mimeType ? getFileTypeCategory(mimeType) : null;

	// If we can't determine the category from MIME type, fall back to general support check
	if (!category) {
		// For unknown types, only allow if they might be text files
		// This is a conservative approach for edge cases
		return true; // Let the existing isFileTypeSupported handle this
	}

	switch (category) {
		case FileTypeCategory.TEXT:
			// Text files are always supported
			return true;

		case FileTypeCategory.PDF:
			// PDFs are always supported (will be processed as text for non-vision models)
			return true;

		case FileTypeCategory.IMAGE:
			// Images require vision support
			return capabilities.hasVision;

		case FileTypeCategory.AUDIO:
			// Audio files require audio support
			return capabilities.hasAudio;

		case FileTypeCategory.VIDEO:
			// Video files require video support
			return capabilities.hasVideo;

		default:
			// Unknown categories - be conservative and allow
			return true;
	}
}

/**
 * Filter files based on model modalities and return supported/unsupported lists
 * @param files - Array of files to filter
 * @param capabilities - The modality capabilities to check against
 * @returns Object with supportedFiles and unsupportedFiles arrays
 */
export function filterFilesByModalities(
	files: File[],
	capabilities: ModalityCapabilities
): {
	supportedFiles: File[];
	unsupportedFiles: File[];
	modalityReasons: Record<string, string>;
} {
	const supportedFiles: File[] = [];
	const unsupportedFiles: File[] = [];
	const modalityReasons: Record<string, string> = {};
	const { hasAudio, hasVideo, hasVision } = capabilities;

	for (const file of files) {
		const category = getFileTypeCategory(file.type);

		let isSupported = true;
		let reason = '';

		switch (category) {
			case FileTypeCategory.IMAGE:
				if (!hasVision) {
					isSupported = false;
					reason = fText('message44cdb11b7a8a');
				}

				break;

			case FileTypeCategory.AUDIO:
				if (!hasAudio) {
					isSupported = false;
					reason = fText('messageb0f8367dee0c');
				}

				break;

			case FileTypeCategory.VIDEO:
				if (!hasVideo) {
					isSupported = false;
					reason = fText('message70390aa680b4');
				}

				break;

			case FileTypeCategory.TEXT:
			case FileTypeCategory.PDF:
				// Always supported
				break;

			default:
				break;
		}

		if (isSupported) {
			supportedFiles.push(file);
		} else {
			unsupportedFiles.push(file);
			modalityReasons[file.name] = reason;
		}
	}

	return { modalityReasons, supportedFiles, unsupportedFiles };
}

/**
 * Generate a user-friendly error message for unsupported files
 * @param unsupportedFiles - Array of unsupported files
 * @param modalityReasons - Reasons why files are unsupported
 * @param capabilities - The modality capabilities to check against
 * @returns Formatted error message
 */
export function generateModalityErrorMessage(
	unsupportedFiles: File[],
	modalityReasons: Record<string, string>,
	capabilities: ModalityCapabilities
): string {
	if (unsupportedFiles.length === 0) return '';

	const { hasAudio, hasVideo, hasVision } = capabilities;

	let message = '';

	if (unsupportedFiles.length === 1) {
		const file = unsupportedFiles[0];
		const reason = modalityReasons[file.name];

		message = fText('messageb0f1d92b85c5', { p0: file.name, p1: reason });
	} else {
		const fileNames = unsupportedFiles.map((f) => f.name).join(', ');

		message = fText('messagedad82b66bf1d', { p0: fileNames });
	}

	// Add helpful information about what is supported
	const supportedTypes: string[] = [fText('message4228a0d6fcbe'), fText('message211eae3ffd87')];

	if (hasVision) supportedTypes.push(fText('message21b2eed1e328'));

	if (hasAudio) supportedTypes.push(fText('messagee6ef5e87009d'));

	if (hasVideo) supportedTypes.push(fText('messagebc7eedd943c0'));

	message += ` ${fText('message8d7b0335370c', { p0: supportedTypes.join(', ') })}`;

	return message;
}
