import { fText } from '$lib/i18n';

export const ERROR_MESSAGES = {
	HTTP: {
		ACCESS_DENIED: fText('messagecc11d415d932'),
		GENERIC: fText('messagecfce761befa8'),
		INTERNAL_ERROR: fText('message9051661bb355'),
		NOT_FOUND: fText('messagee3ebaa16dd9d'),
		TEMPORARILY_UNAVAILABLE: fText('message797397887a90')
	},
	NETWORK: {
		GENERIC: fText('messagefa67448b4462'),
		NXDOMAIN: fText('message51f6f3d1a801'),
		REFUSED: fText('message448ea20860db'),
		TIMEOUT: fText('message7aa26ae72ac1'),
		UNREACHABLE: fText('messagea28e8330bb9f')
	}
};

export const HTTP_CODE_TO_STRING: Record<string, string> = {
	401: ERROR_MESSAGES.HTTP.ACCESS_DENIED,
	403: ERROR_MESSAGES.HTTP.ACCESS_DENIED,
	500: ERROR_MESSAGES.HTTP.INTERNAL_ERROR,
	503: ERROR_MESSAGES.HTTP.TEMPORARILY_UNAVAILABLE
};
