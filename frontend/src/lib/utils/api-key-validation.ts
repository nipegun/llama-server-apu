import { error } from '@sveltejs/kit';
import { browser } from '$app/environment';
import { base } from '$app/paths';
import { HEADERS } from '$lib/constants';
import { MimeTypeApplication } from '$lib/enums';
import { settingsStore } from '$lib/stores/settings/index.svelte';
import { fText } from '$lib/i18n';

/**
 * Validates API key by making a request to the server props endpoint
 * Throws SvelteKit errors for authentication failures or server issues
 */
export async function validateApiKey(fetch: typeof globalThis.fetch): Promise<void> {
	if (!browser) {
		return;
	}

	const apiKey = settingsStore.config.apiKey;

	try {
		const headers: Record<string, string> = {
			[HEADERS.CONTENT_TYPE]: MimeTypeApplication.JSON
		};

		// Probe /props even without a stored key: on a server started with
		// --api-key the unauthenticated request returns 401 and surfaces the
		// API key splash, which is the onboarding path for entering the key.
		if (apiKey) {
			headers[HEADERS.AUTHORIZATION] = `${HEADERS.BEARER}${apiKey}`;
		}

		const response = await fetch(`${base}/api/props`, { headers });

		if (!response.ok) {
			if (response.status === 401 || response.status === 403) {
				throw error(401, fText('messagecc11d415d932'));
			}

			console.warn(`Server responded with status ${response.status} during API key validation`);

			return;
		}
	} catch (err) {
		// If it's already a SvelteKit error, re-throw it
		if (err && typeof err === 'object' && 'status' in err) {
			throw err;
		}

		// Network or other errors
		console.warn('Cannot connect to server for API key validation:', err);
	}
}
