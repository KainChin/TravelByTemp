import { useEffect, useState } from 'react';
import { adminApi, AdminDestination } from '../api';
import { Breadcrumb } from '../components/Breadcrumb';
import { ContentPageHeader, ContentToast } from '../components/ContentPageHeader';
import { CheckCircleIcon, TrashIcon } from '../components/Icons';
import { useI18n } from '../i18n';

export function RecycleBinPage() {
  const { t } = useI18n();
  const [items, setItems] = useState<AdminDestination[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [toast, setToast] = useState('');

  const load = () => {
    setLoading(true);
    adminApi
      .inactiveDestinations()
      .then(setItems)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    load();
  }, []);

  useEffect(() => {
    if (!toast) return;
    const timer = window.setTimeout(() => setToast(''), 3200);
    return () => window.clearTimeout(timer);
  }, [toast]);

  const handleRestore = async (d: AdminDestination) => {
    try {
      await adminApi.restoreDestination(d.id);
      setToast(t('destinations.restored', { name: d.name }));
      load();
    } catch (e) {
      setToast(e instanceof Error ? e.message : t('common.actionFailed'));
    }
  };

  if (error) return <div className="admin-error">{error}</div>;

  return (
    <div className="content-page">
      <Breadcrumb items={[{ label: t('nav.recycleBin') }]} />
      <ContentToast message={toast} />
      <ContentPageHeader
        title={t('nav.recycleBin')}
        description={t('activity.description')}
        count={items.length}
        countLabel={t('destinations.countLabel')}
      />

      {loading ? (
        <div className="card-loading"><span className="loading-dots">{t('common.loading')}</span></div>
      ) : items.length === 0 ? (
        <div className="content-empty card" style={{ padding: '3rem 2rem', textAlign: 'center' }}>
          <p style={{ color: 'var(--ink-muted)' }}>{t('destinations.hiddenEmpty')}</p>
        </div>
      ) : (
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          <div className="table-wrap">
            <table className="admin-table">
              <thead>
                <tr>
                  <th>{t('destinations.fieldName')}</th>
                  <th>{t('destinations.province')}</th>
                  <th>{t('destinations.region')}</th>
                  <th>{t('destinations.type')}</th>
                  <th style={{ textAlign: 'right' }}>{t('common.actions')}</th>
                </tr>
              </thead>
              <tbody>
                {items.map((d) => (
                  <tr key={d.id}>
                    <td>
                      <div className="article-title-cell">
                        {d.imageUrl && <img src={d.imageUrl} alt="" className="article-thumb" />}
                        <strong>{d.name}</strong>
                      </div>
                    </td>
                    <td>{d.province}</td>
                    <td>{t(`region.${d.region}` as any)}</td>
                    <td><span className="tag tag-cat tag-destination">{d.category}</span></td>
                    <td style={{ textAlign: 'right' }}>
                      <button
                        type="button"
                        className="btn-primary btn-sm"
                        style={{ cursor: 'pointer' }}
                        onClick={() => handleRestore(d)}
                      >
                        <CheckCircleIcon size={14} />
                        {t('destinations.restore')}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
