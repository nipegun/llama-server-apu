import { buildInfoPlugin } from './scripts/vite-plugin-build-info';
import { nerdamerPlugin } from './scripts/vite-plugin-nerdamer';
import { relativizeBasePlugin } from './scripts/vite-plugin-relativize-base';
import { splashScreenPlugin } from './scripts/vite-plugin-splash-screen';
import { SVELTEKIT_PWA_OPTIONS } from './src/lib/constants/pwa.constants';
import { sveltekit } from '@sveltejs/kit/vite';
import tailwindcss from '@tailwindcss/vite';
import { SvelteKitPWA } from '@vite-pwa/sveltekit';
import { resolve } from 'path';
import { defineConfig } from 'vite';

export default defineConfig(() => {
	return {
		build: {
			assetsInlineLimit: 32000,
			chunkSizeWarningLimit: 3072,
			minify: true
		},

		plugins: [
			tailwindcss(),
			sveltekit(),
			SvelteKitPWA(SVELTEKIT_PWA_OPTIONS),
			splashScreenPlugin(),
			buildInfoPlugin(),
			nerdamerPlugin(),
			relativizeBasePlugin()
		],

		resolve: {
			alias: {
				'katex-fonts': resolve('node_modules/katex/dist/fonts')
			}
		}
	};
});
