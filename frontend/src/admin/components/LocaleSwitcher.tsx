import { useI18n, type Locale } from '../i18n';

const LOCALES: { id: Locale; labelKey: string }[] = [
  { id: 'vi', labelKey: 'locale.vi' },
  { id: 'en', labelKey: 'locale.en' },
];

export function LocaleSwitcher({ compact }: { compact?: boolean }) {
  const { locale, setLocale, t } = useI18n();

  return (
    <div className={`locale-switcher${compact ? ' locale-switcher-compact' : ''}`}>
      {!compact && <span className="locale-switcher-label">{t('locale.switch')}</span>}
      <div className="locale-switcher-options" role="group" aria-label={t('locale.switch')}>
        {LOCALES.map((item) => (
          <button
            key={item.id}
            type="button"
            className={`locale-btn${locale === item.id ? ' active' : ''}`}
            aria-pressed={locale === item.id}
            onClick={() => setLocale(item.id)}
          >
            {item.id.toUpperCase()}
          </button>
        ))}
      </div>
    </div>
  );
}
