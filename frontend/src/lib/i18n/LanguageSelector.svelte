<script lang="ts">
  import { onMount } from 'svelte';
  import { aLocales, fGetLocale, fSetLocale, fText, type Locale } from './index';

  const cLocale = fGetLocale();

  onMount(() => {
    document.documentElement.lang = cLocale;
  });

  function fChange(pEvent: Event): void {
    fSetLocale((pEvent.currentTarget as HTMLSelectElement).value as Locale);
  }
</script>

<label class="flex min-w-0 items-center gap-2 px-3 py-2 text-sm">
  <span>{fText('language')}</span>
  <select
    class="min-w-0 flex-1 rounded-md border border-border bg-background px-2 py-1 text-foreground"
    aria-label={fText('language')}
    value={cLocale}
    onchange={fChange}
  >
    {#each aLocales as vLocale}
      <option value={vLocale}>{fText(`language.${vLocale}`)}</option>
    {/each}
  </select>
</label>
