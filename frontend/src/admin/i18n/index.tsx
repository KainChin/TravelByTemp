import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import en from './locales/en';
import vi from './locales/vi';
import type { Locale, TranslateParams, TranslationDict } from './types';

const STORAGE_KEY = 'admin_locale';

const LOCALES: Record<Locale, TranslationDict> = { vi, en };

function getNested(dict: TranslationDict, path: string): string | undefined {
  const parts = path.split('.');
  let cur: unknown = dict;
  for (const part of parts) {
    if (!cur || typeof cur !== 'object' || !(part in (cur as object))) return undefined;
    cur = (cur as Record<string, unknown>)[part];
  }
  return typeof cur === 'string' ? cur : undefined;
}

export function translate(dict: TranslationDict, key: string, params?: TranslateParams): string {
  const template = getNested(dict, key) ?? key;
  if (!params) return template;
  return Object.entries(params).reduce(
    (text, [k, v]) => text.replace(new RegExp(`\\{\\{${k}\\}\\}`, 'g'), String(v)),
    template,
  );
}

export function getStoredLocale(): Locale {
  const saved = localStorage.getItem(STORAGE_KEY);
  return saved === 'en' ? 'en' : 'vi';
}

export function formatNumber(value: number, locale: Locale): string {
  return value.toLocaleString(locale === 'vi' ? 'vi-VN' : 'en-US');
}

export function formatTimeAgo(iso: string, locale: Locale, t: (key: string, params?: TranslateParams) => string): string {
  const diff = Date.now() - new Date(iso).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return t('common.justNow');
  if (mins < 60) return t('common.minutesAgo', { count: mins });
  const hours = Math.floor(mins / 60);
  if (hours < 24) return t('common.hoursAgo', { count: hours });
  const days = Math.floor(hours / 24);
  return t('common.daysAgo', { count: days });
}

type I18nContextValue = {
  locale: Locale;
  setLocale: (locale: Locale) => void;
  t: (key: string, params?: TranslateParams) => string;
  formatNumber: (value: number) => string;
  formatTimeAgo: (iso: string) => string;
};

const I18nContext = createContext<I18nContextValue | null>(null);

export function I18nProvider({ children }: { children: ReactNode }) {
  const [locale, setLocaleState] = useState<Locale>(() => getStoredLocale());

  const setLocale = useCallback((next: Locale) => {
    setLocaleState(next);
    localStorage.setItem(STORAGE_KEY, next);
  }, []);

  useEffect(() => {
    document.documentElement.lang = locale;
  }, [locale]);

  const dict = LOCALES[locale];

  const t = useCallback(
    (key: string, params?: TranslateParams) => translate(dict, key, params),
    [dict],
  );

  const value = useMemo<I18nContextValue>(
    () => ({
      locale,
      setLocale,
      t,
      formatNumber: (n) => formatNumber(n, locale),
      formatTimeAgo: (iso) => formatTimeAgo(iso, locale, t),
    }),
    [locale, setLocale, t],
  );

  return <I18nContext.Provider value={value}>{children}</I18nContext.Provider>;
}

export function useI18n() {
  const ctx = useContext(I18nContext);
  if (!ctx) throw new Error('useI18n must be used within I18nProvider');
  return ctx;
}

/** For non-React modules (e.g. api.ts) */
export function tStatic(key: string, params?: TranslateParams): string {
  return translate(LOCALES[getStoredLocale()], key, params);
}
