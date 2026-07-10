import { adminNavigate } from '../api';
import { Breadcrumb } from '../components/Breadcrumb';
import { ContentPageHeader } from '../components/ContentPageHeader';
import { useI18n } from '../i18n';
import { ShieldCheckIcon } from '../components/Icons';

type Props = {
  navId: string;
};

export function PlaceholderPage({ navId }: Props) {
  const { t } = useI18n();
  const pageTitle = t(`nav.${navId}` as any);

  return (
    <div className="content-page placeholder-page">
      <Breadcrumb items={[{ label: pageTitle }]} />
      <ContentPageHeader 
        title={pageTitle} 
        description={t('placeholder.title')} 
      />

      <div className="card placeholder-card" style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', textAlign: 'center', padding: '3rem 2rem', gap: '1.5rem' }}>
        <div className="placeholder-icon-wrap" style={{ background: 'var(--brand-soft)', color: 'var(--brand)', padding: '1.5rem', borderRadius: '50%' }}>
          <ShieldCheckIcon size={48} />
        </div>
        <div style={{ maxWidth: '540px' }}>
          <h2 style={{ fontSize: '1.25rem', fontWeight: 600, color: 'var(--ink)', marginBottom: '0.75rem' }}>
            {t('placeholder.title')} (Suggested Future Feature)
          </h2>
          <p style={{ color: 'var(--ink-muted)', fontSize: '0.9375rem', lineHeight: 1.6 }}>
            {t('placeholder.desc', { name: pageTitle })}
          </p>
        </div>
        <button 
          type="button" 
          className="btn-primary" 
          style={{ cursor: 'pointer', padding: '0.75rem 1.5rem' }} 
          onClick={() => adminNavigate('dashboard')}
        >
          {t('placeholder.back')}
        </button>
      </div>
    </div>
  );
}
