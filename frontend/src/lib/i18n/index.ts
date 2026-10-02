import dEnglishBritish from './en-GB.json';
import dEnglishAmerican from './en-US.json';
import dSpanishArgentina from './es-AR.json';
import dSpanishSpain from './es-ES.json';

export const aLocales = ['en-GB', 'en-US', 'es-AR', 'es-ES'] as const;
export type Locale = (typeof aLocales)[number];
const cStorageKey = 'llama-server-apu.language';
const dCatalogs: Record<Locale, Record<string, string>> = {
  'en-GB': dEnglishBritish,
  'en-US': dEnglishAmerican,
  'es-AR': dSpanishArgentina,
  'es-ES': dSpanishSpain
};

function fIsLocale(pValue: string | null): pValue is Locale {
  return aLocales.some((pLocale) => pLocale === pValue);
}

function fReadLocale(): Locale {
  if (typeof window === 'undefined') return 'en-US';
  const vRequested = new URL(window.location.href).searchParams.get('lang');
  if (fIsLocale(vRequested)) return vRequested;
  try {
    const vSaved = window.localStorage.getItem(cStorageKey);
    return fIsLocale(vSaved) ? vSaved : 'en-US';
  } catch {
    return 'en-US';
  }
}

const cLocale = fReadLocale();

export function fGetLocale(): Locale {
  return cLocale;
}

export function fText(pKey: string, pParameters: Record<string, unknown> = {}): string {
  const vText = dCatalogs[cLocale][pKey] ?? dCatalogs['en-US'][pKey] ?? pKey;
  return vText.replace(/\{(p\d+)\}/g, (pMatch, pName: string) =>
    Object.hasOwn(pParameters, pName) ? String(pParameters[pName]) : pMatch
  );
}

export function fSetLocale(pLocale: Locale): void {
  if (typeof window === 'undefined' || !fIsLocale(pLocale)) return;
  try {
    window.localStorage.setItem(cStorageKey, pLocale);
  } catch {
    // The URL also retains the choice when browser storage is unavailable.
  }
  const vUrl = new URL(window.location.href);
  vUrl.searchParams.set('lang', pLocale);
  // A full navigation refreshes module-level labels as well as components.
  window.location.assign(vUrl.toString());
}
